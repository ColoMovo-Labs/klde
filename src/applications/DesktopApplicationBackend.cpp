// SPDX-License-Identifier: GPL-3.0-or-later
#include "DesktopApplicationBackend.h"
#include <QCollator>
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QFutureWatcher>
#include <QIcon>
#include <QSet>
#include <QSettings>
#include <QStandardPaths>
#include <QTimer>
#include <QUrl>
#include <QtConcurrent/QtConcurrentRun>
#include <algorithm>
#if defined(OWODE_HAVE_KDE_APPLICATIONS)
#include <KConfigGroup>
#include <KDesktopFile>
#include <KIO/ApplicationLauncherJob>
#include <KJob>
#include <KService>
#endif

namespace klde {
namespace {
struct DesktopEntry {
    ApplicationEntry application;
    QString path;
    QString icon;
    QString startupClass;
};
struct Discovery {
    QList<DesktopEntry> entries;
    QStringList directories;
    QStringList files;
};

#if defined(OWODE_HAVE_KDE_APPLICATIONS)
bool visibleInShell(const KDesktopFile &desktop, const KService &service) {
    const auto group = desktop.desktopGroup();
    const auto excluded = group.readXdgListEntry("NotShowIn");
    // Explicit exclusion of our desktop is still respected. OnlyShowIn is a
    // menu visibility hint, not an execution/security boundary.
    const auto desktops = qEnvironmentVariable("XDG_CURRENT_DESKTOP").split(':');
    for (const auto &name : desktops) {
        if (excluded.contains(name))
            return false;
    }
    if (service.showInCurrentDesktop())
        return true;
    if (!desktops.contains("owoDE"))
        return false;
    const auto included = group.readXdgListEntry("OnlyShowIn");
    return included.contains("GNOME") || included.contains("KDE");
}
#endif

Discovery discover(const QStringList &roots, const QString &locale) {
    Discovery result;
#if defined(OWODE_HAVE_KDE_APPLICATIONS)
    QSet<QString> seen;
    for (const auto &dataRoot : roots) {
        const QDir applications(dataRoot + QStringLiteral("/applications"));
        // Watch the parent too, so creating a previously absent applications directory works.
        if (QDir(dataRoot).exists())
            result.directories.append(dataRoot);
        if (!applications.exists())
            continue;
        result.directories.append(applications.absolutePath());
        QStringList paths;
        QDirIterator iterator(applications.absolutePath(), QDir::AllEntries | QDir::NoDotAndDotDot,
                              QDirIterator::Subdirectories);
        while (iterator.hasNext()) {
            iterator.next();
            const auto info = iterator.fileInfo();
            if (info.isDir())
                result.directories.append(info.absoluteFilePath());
            else if (info.isFile() && info.suffix() == QStringLiteral("desktop"))
                paths.append(info.absoluteFilePath());
        }
        paths.sort();
        for (const auto &path : paths) {
            result.files.append(path);
            const auto id = applications.relativeFilePath(path).replace('/', '-');
            if (seen.contains(id))
                continue;
            // An overriding Hidden/invalid entry must still suppress the lower-priority entry.
            seen.insert(id);
            KDesktopFile desktop(path);
            desktop.setLocale(locale);
            if (!desktop.hasApplicationType() ||
                desktop.desktopGroup().readEntry("Hidden", false) || desktop.noDisplay() ||
                !desktop.tryExec())
                continue;
            const KService service(&desktop, path);
            if (!service.isValid() || !service.isApplication() || service.name().isEmpty() ||
                !visibleInShell(desktop, service) || !service.showOnCurrentPlatform())
                continue;
            const auto description =
                service.comment().isEmpty() ? service.genericName() : service.comment();
            auto keywords = service.keywords();
            keywords << service.genericName() << service.untranslatedName() << id;
            ApplicationEntry application{
                id,
                service.name(),
                description,
                QStringLiteral("image://applications/") +
                    QString::fromLatin1(id.toUtf8().toBase64(QByteArray::Base64UrlEncoding |
                                                             QByteArray::OmitTrailingEquals)),
                keywords.join(' '),
                false,
                false,
                "system"};
            result.entries.append({application, path, service.icon(),
                                   desktop.desktopGroup().readEntry("StartupWMClass", QString{})});
        }
    }
    QCollator collator;
    collator.setCaseSensitivity(Qt::CaseInsensitive);
    std::sort(result.entries.begin(), result.entries.end(),
              [&collator](const auto &a, const auto &b) {
                  const int order = collator.compare(a.application.name, b.application.name);
                  return order == 0 ? a.application.id < b.application.id : order < 0;
              });
    result.directories.removeDuplicates();
#else
    Q_UNUSED(roots)
    Q_UNUSED(locale)
#endif
    return result;
}
} // namespace

class DesktopApplicationBackend::Private {
  public:
    QList<DesktopEntry> entries;
    QFutureWatcher<Discovery> watcher;
    QFileSystemWatcher files;
    QTimer debounce;
    bool started = false;
    bool ready = false;
    bool repeat = false;
    QString locale;
};

DesktopApplicationBackend::DesktopApplicationBackend(QObject *parent)
    : QObject(parent), d(std::make_unique<Private>()) {
    d->debounce.setSingleShot(true);
    d->debounce.setInterval(150);
    connect(&d->debounce, &QTimer::timeout, this, &DesktopApplicationBackend::refresh);
    const auto changed = [this] { d->debounce.start(); };
    connect(&d->files, &QFileSystemWatcher::directoryChanged, this, changed);
    connect(&d->files, &QFileSystemWatcher::fileChanged, this, changed);
    connect(&d->watcher, &QFutureWatcher<Discovery>::finished, this, [this] {
        const auto result = d->watcher.result();
        d->entries = result.entries;
        const auto pins = QSettings().value("applications/pinned").toStringList();
        for (auto &entry : d->entries)
            entry.application.pinned = pins.contains(entry.application.id);
        if (!d->files.directories().isEmpty())
            d->files.removePaths(d->files.directories());
        if (!d->files.files().isEmpty())
            d->files.removePaths(d->files.files());
        if (!result.directories.isEmpty())
            d->files.addPaths(result.directories);
        if (!result.files.isEmpty())
            d->files.addPaths(result.files);
        d->ready = true;
        emit catalogChanged();
        emit busyChanged();
        if (d->repeat) {
            d->repeat = false;
            refresh();
        }
    });
}
DesktopApplicationBackend::~DesktopApplicationBackend() = default;
bool DesktopApplicationBackend::available() {
#if defined(OWODE_HAVE_KDE_APPLICATIONS)
    return true;
#else
    return false;
#endif
}
bool DesktopApplicationBackend::ready() const { return d->ready; }
bool DesktopApplicationBackend::busy() const { return d->watcher.isRunning(); }
QList<ApplicationEntry> DesktopApplicationBackend::entries() const {
    QList<ApplicationEntry> result;
    for (const auto &entry : d->entries)
        result.append(entry.application);
    return result;
}
void DesktopApplicationBackend::start() {
    if (d->started || !available())
        return;
    d->started = true;
    refresh();
}
void DesktopApplicationBackend::refresh() {
    if (!d->started)
        return;
    if (busy()) {
        d->repeat = true;
        return;
    }
    d->watcher.setFuture(QtConcurrent::run(
        discover, QStandardPaths::standardLocations(QStandardPaths::GenericDataLocation),
        d->locale));
    emit busyChanged();
}
void DesktopApplicationBackend::setLocale(const QString &locale) {
    if (d->locale != locale) {
        d->locale = locale;
        refresh();
    }
}
void DesktopApplicationBackend::setPinned(const QString &id, bool pinned) {
    auto found = std::find_if(d->entries.begin(), d->entries.end(),
                              [&id](const auto &entry) { return entry.application.id == id; });
    if (found == d->entries.end() || found->application.pinned == pinned)
        return;
    QSettings settings;
    auto pins = settings.value("applications/pinned").toStringList();
    pins.removeAll(id);
    if (pinned)
        pins.append(id);
    settings.setValue("applications/pinned", pins);
    found->application.pinned = pinned;
    emit catalogChanged();
}
QString DesktopApplicationBackend::applicationForWindow(const QString &desktopFile,
                                                        const QString &resourceClass,
                                                        const QString &resourceName) const {
    const auto stem = [](QString id) {
        if (id.endsWith(".desktop", Qt::CaseInsensitive))
            id.chop(8);
        return id.toCaseFolded();
    };
    // The compositor's declared desktop identity has precedence over WM_CLASS.
    // Ambiguous aliases deliberately don't attach a badge to an unrelated app.
    QStringList matches;
    if (!desktopFile.isEmpty()) {
        for (const auto &entry : d->entries)
            if (entry.path == desktopFile || stem(entry.application.id) == stem(desktopFile))
                matches.append(entry.application.id);
        if (!matches.isEmpty())
            return matches.size() == 1 ? matches.first() : QString{};
    }
    for (const auto &entry : d->entries) {
        const auto aliases =
            QStringList{stem(entry.application.id), entry.startupClass.toCaseFolded()};
        if ((!resourceClass.isEmpty() && aliases.contains(resourceClass.toCaseFolded())) ||
            (!resourceName.isEmpty() && aliases.contains(resourceName.toCaseFolded())))
            matches.append(entry.application.id);
    }
    return matches.size() == 1 ? matches.first() : QString{};
}
bool DesktopApplicationBackend::launch(const QString &id) {
#if defined(OWODE_HAVE_KDE_APPLICATIONS)
    const auto found =
        std::find_if(d->entries.cbegin(), d->entries.cend(),
                     [&id](const auto &entry) { return entry.application.id == id; });
    if (found == d->entries.cend())
        return false;
    // Re-read metadata: an app may have been removed or hidden since the last scan.
    const KDesktopFile desktop(found->path);
    if (!QFileInfo::exists(found->path) || desktop.desktopGroup().readEntry("Hidden", false) ||
        desktop.noDisplay() || !desktop.tryExec())
        return false;
    auto service = KService::Ptr(new KService(&desktop, found->path));
    if (!service->isValid() || !service->isApplication() || !visibleInShell(desktop, *service) ||
        !service->showOnCurrentPlatform())
        return false;
    auto *job = new KIO::ApplicationLauncherJob(service, this);
    job->setUiDelegate(nullptr);
    connect(job, &KJob::result, this, [this, id](KJob *finished) {
        emit launchFinished(id, finished->error() == 0, finished->errorText());
    });
    job->start();
    return true;
#else
    Q_UNUSED(id)
    return false;
#endif
}
QImage DesktopApplicationBackend::icon(const QString &id, const QSize &size) const {
    const auto found =
        std::find_if(d->entries.cbegin(), d->entries.cend(),
                     [&id](const auto &entry) { return entry.application.id == id; });
    const QIcon fallback(QStringLiteral(":/assets/icons/note.svg"));
    const auto name = found == d->entries.cend() ? QString{} : found->icon;
    const auto image = name.startsWith('/') ? QIcon(name) : QIcon::fromTheme(name, fallback);
    return (image.isNull() ? fallback : image).pixmap(size).toImage();
}
ApplicationIconProvider::ApplicationIconProvider(DesktopApplicationBackend *backend)
    : QQuickImageProvider(QQuickImageProvider::Image), m_backend(backend) {}
QImage ApplicationIconProvider::requestImage(const QString &id, QSize *size,
                                             const QSize &requestedSize) {
    const auto extent =
        requestedSize.isValid() ? requestedSize.boundedTo(QSize(256, 256)) : QSize(64, 64);
    const auto image = m_backend
                           ? m_backend->icon(QString::fromUtf8(QByteArray::fromBase64(
                                                 id.toLatin1(), QByteArray::Base64UrlEncoding)),
                                             extent)
                           : QImage{};
    if (size)
        *size = image.size();
    return image;
}
} // namespace klde

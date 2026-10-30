// SPDX-License-Identifier: GPL-3.0-or-later
#include <QCoreApplication>
#include <QDBusConnectionInterface>
#include <QDBusInterface>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDBusReply>
#include <QDBusUnixFileDescriptor>
#include <QDebug>
#include <QDir>
#include <QElapsedTimer>
#include <QEventLoop>
#include <QFile>
#include <QImage>
#include <QJsonDocument>
#include <QProcess>
#include <QTemporaryFile>
#include <QThread>
#include <QTimer>

int main(int argc, char **argv) {
    QCoreApplication app(argc, argv);
    const auto display = qEnvironmentVariable("WAYLAND_DISPLAY");
    const auto runtime = qEnvironmentVariable("XDG_RUNTIME_DIR");
    const bool isolated =
        (display == "owode-ci" && runtime.startsWith(QDir::tempPath() + "/owode-native-ci-")) ||
        (display == "owode-login-ci" && runtime.startsWith(QDir::tempPath() + "/owode-login-ci-"));
    if (app.arguments().size() != 2 || qEnvironmentVariable("OWODE_NATIVE_TEST_ISOLATED") != "1" ||
        !isolated) {
        qCritical("Capture is restricted to the isolated native test compositor");
        return 2;
    }
    const auto output = app.arguments().at(1);
    const auto bus = QDBusConnection::sessionBus();
    const QDBusReply<bool> screenshotRegistered =
        bus.interface()->isServiceRegistered("org.kde.KWin.ScreenShot2");
    if (!screenshotRegistered.isValid())
        return 3;
    QDBusInterface kwin("org.kde.KWin", "/KWin", "org.kde.KWin");
    const QDBusReply<QString> support = kwin.call("supportInformation");
    if (!support.isValid())
        return 3;
    if (support.value().contains("Compositing Type: QPainter")) {
        // ScreenShot2 requires an EGL backend, even when registered in KWin 6.7.
        // Capture only the X11 viewport verified to belong to this private KWin.
        const auto viewport = qEnvironmentVariable("OWODE_NATIVE_CAPTURE_WINDOW");
        bool validId = false;
        const auto id = viewport.toULongLong(&validId, 0);
        if (!validId || id == 0)
            return 10;
        QProcess owner;
        owner.start("xdotool", {"getwindowpid", viewport});
        if (!owner.waitForFinished(3000) || owner.exitCode() != 0)
            return 11;
        const QDBusReply<uint> kwinPid = bus.interface()->servicePid("org.kde.KWin");
        if (!kwinPid.isValid() ||
            owner.readAllStandardOutput().trimmed().toUInt() != kwinPid.value())
            return 12;
        if (QProcess::execute("import", {"-window", viewport, output}) != 0)
            return 13;
        const QImage captured(output);
        if (captured.isNull())
            return 14;
        QFile evidence(output + ".json");
        if (!evidence.open(QIODevice::WriteOnly))
            return 15;
        evidence.write(
            QJsonDocument::fromVariant(
                QVariantMap{
                    {"backend", "owned X11 viewport; KWin QPainter, ScreenShot2 requires EGL"},
                    {"hostCapture", false},
                    {"width", captured.width()},
                    {"height", captured.height()},
                    {"kwinPid", kwinPid.value()},
                    {"viewport", viewport}})
                .toJson());
        return 0;
    }
    if (!screenshotRegistered.value()) {
        qCritical("ScreenShot2 is unavailable for this compositor backend");
        return 3;
    }
    QTemporaryFile pixels;
    if (!pixels.open())
        return 3;
    QDBusInterface screenshot("org.kde.KWin.ScreenShot2", "/org/kde/KWin/ScreenShot2",
                              "org.kde.KWin.ScreenShot2");
    const QVariantMap options{
        {"include-cursor", false}, {"native-resolution", true}, {"hide-caller-windows", false}};
    QDBusPendingCallWatcher pending(
        screenshot.asyncCall("CaptureActiveScreen", options,
                             QVariant::fromValue(QDBusUnixFileDescriptor(pixels.handle()))));
    QEventLoop loop;
    QTimer deadline;
    deadline.setSingleShot(true);
    QObject::connect(&deadline, &QTimer::timeout, &loop, &QEventLoop::quit);
    QObject::connect(&pending, &QDBusPendingCallWatcher::finished, &loop, &QEventLoop::quit);
    deadline.start(10000);
    if (!pending.isFinished())
        loop.exec();
    if (!pending.isFinished()) {
        qCritical("KWin screenshot request timed out");
        return 4;
    }
    const QDBusPendingReply<QVariantMap> reply = pending;
    if (reply.isError()) {
        qCritical().noquote() << reply.error().message();
        return 5;
    }
    const auto metadata = reply.value();
    const int width = metadata.value("width").toInt();
    const int height = metadata.value("height").toInt();
    const int stride = metadata.value("stride").toInt();
    const auto format = static_cast<QImage::Format>(metadata.value("format").toInt());
    const qint64 size = qint64(stride) * height;
    if (width <= 0 || width > 8192 || height <= 0 || height > 8192 || stride <= 0 || size <= 0 ||
        size > 64 * 1024 * 1024) {
        qCritical("Invalid or oversized compositor screenshot metadata");
        return 6;
    }
    QElapsedTimer written;
    written.start();
    while (pixels.size() < size && written.elapsed() < 5000)
        QThread::msleep(10);
    if (pixels.size() != size || !pixels.seek(0))
        return 7;
    const auto bytes = pixels.read(size);
    const QImage image(reinterpret_cast<const uchar *>(bytes.constData()), width, height, stride,
                       format);
    if (image.isNull() || !image.save(app.arguments().at(1)))
        return 8;
    QFile evidence(app.arguments().at(1) + ".json");
    if (!evidence.open(QIODevice::WriteOnly))
        return 9;
    auto result = metadata;
    result.insert("backend", "private KWin ScreenShot2 CaptureActiveScreen");
    result.insert("hostCapture", false);
    evidence.write(QJsonDocument::fromVariant(result).toJson());
    return 0;
}

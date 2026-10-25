// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include "models/ApplicationEntry.h"
#include <QImage>
#include <QObject>
#include <QPointer>
#include <QQuickImageProvider>
#include <QtQml/qqmlregistration.h>
#include <memory>

namespace klde {
// Desktop metadata and launch requests stay outside the presentation model.
class DesktopApplicationBackend final : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.desktopApplications")
    Q_PROPERTY(bool available READ available CONSTANT)
    Q_PROPERTY(bool ready READ ready NOTIFY catalogChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
  public:
    explicit DesktopApplicationBackend(QObject *parent = nullptr);
    ~DesktopApplicationBackend() override;
    static bool available();
    bool ready() const;
    bool busy() const;
    QList<ApplicationEntry> entries() const;
    void start();
    void setLocale(const QString &locale);
    Q_INVOKABLE void refresh();
    bool launch(const QString &id);
    void setPinned(const QString &id, bool pinned);
    QImage icon(const QString &id, const QSize &size) const;
  signals:
    void catalogChanged();
    void busyChanged();
    void launchFinished(const QString &id, bool success, const QString &message);

  private:
    class Private;
    std::unique_ptr<Private> d;
};

class ApplicationIconProvider final : public QQuickImageProvider {
  public:
    explicit ApplicationIconProvider(DesktopApplicationBackend *backend);
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;

  private:
    QPointer<DesktopApplicationBackend> m_backend;
};
} // namespace klde

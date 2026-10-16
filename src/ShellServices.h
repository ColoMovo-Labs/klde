// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include "backends/BlurBackend.h"
#include "backends/MockSystemBackend.h"
#include "backends/MockWindowManagerBackend.h"
#include "models/ApplicationModel.h"
#include <QTimer>

namespace klde {
class ShellServices final : public QObject {
    Q_OBJECT
    QML_NAMED_ELEMENT(Shell)
    QML_SINGLETON
    Q_PROPERTY(SystemBackend *system READ system CONSTANT)
    Q_PROPERTY(WindowManagerBackend *windowManager READ windowManager CONSTANT)
    Q_PROPERTY(BlurBackend *blur READ blur CONSTANT)
    Q_PROPERTY(ApplicationModel *applications READ applications CONSTANT)
    Q_PROPERTY(ApplicationFilterModel *search READ search CONSTANT)
    Q_PROPERTY(QVariantMap weather READ weather CONSTANT)
    Q_PROPERTY(QString message READ message NOTIFY messageChanged)
    Q_PROPERTY(int osdValue READ osdValue NOTIFY messageChanged)
  public:
    explicit ShellServices(QObject *parent = nullptr);
    SystemBackend *system() { return &m_system; }
    WindowManagerBackend *windowManager() { return &m_windowManager; }
    BlurBackend *blur() { return &m_blur; }
    ApplicationModel *applications() { return &m_applications; }
    ApplicationFilterModel *search() { return &m_search; }
    QVariantMap weather() const;
    QString message() const { return m_message; }
    int osdValue() const { return m_osdValue; }
    Q_INVOKABLE bool launch(const QString &appId);
    Q_INVOKABLE void showNotice(const QString &message);
    void setGraphicsAvailable(bool available) { m_blur.setGraphicsAvailable(available); }
  signals:
    void messageChanged();

  private:
    MockSystemBackend m_system;
    MockWindowManagerBackend m_windowManager;
    PreviewBlurBackend m_blur;
    ApplicationModel m_applications;
    ApplicationFilterModel m_search;
    QTimer m_noticeTimer;
    QString m_message;
    int m_osdValue = -1;
};
} // namespace klde

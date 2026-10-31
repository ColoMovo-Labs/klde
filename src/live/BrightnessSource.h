// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QObject>
#include <QString>
#include <QTimer>

namespace klde {
class SystemStateModel;

// Reads the internal panel's backlight from sysfs and writes it through
// logind's Session.SetBrightness, which needs no root helper. sysfs gives no
// change notification, so external changes are picked up by a coarse poll.
class BrightnessSource final : public QObject {
    Q_OBJECT
  public:
    explicit BrightnessSource(SystemStateModel *state, QString root = QStringLiteral("/"),
                              QObject *parent = nullptr);
    void start(int pollMs = 2000);
    // Prefers firmware, then platform, then raw interfaces, like systemd-backlight.
    QString findDevice() const;
    static int percent(int brightness, int maximum);
    static int rawFor(int percent, int maximum);
    void sample();
  signals:
    // A confirmed brightness change after the first reading.
    void brightnessChanged(int percent);

  private:
    int readInt(const QString &file) const;
    bool request(int percent);
    SystemStateModel *m_state;
    QString m_root;
    QString m_device;
    int m_maximum = 0;
    int m_last = -1;
    QTimer m_poll;
};
} // namespace klde

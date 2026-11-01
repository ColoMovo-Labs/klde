// SPDX-License-Identifier: GPL-3.0-or-later
#include "status/StatusNotifierHost.h"
#include <QDBusArgument>
#include <QDBusConnectionInterface>
#include <QDBusMetaType>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QEventLoop>
#include <QSignalSpy>
#include <QtTest>

struct TrayPixmap {
    int width = 2, height = 1;
    QByteArray data = QByteArray::fromHex("ffff0000ff0000ff");
};
using TrayPixmaps = QList<TrayPixmap>;
Q_DECLARE_METATYPE(TrayPixmap)
Q_DECLARE_METATYPE(TrayPixmaps)
QDBusArgument &operator<<(QDBusArgument &argument, const TrayPixmap &pixmap) {
    argument.beginStructure();
    argument << pixmap.width << pixmap.height << pixmap.data;
    argument.endStructure();
    return argument;
}
const QDBusArgument &operator>>(const QDBusArgument &argument, TrayPixmap &pixmap) {
    argument.beginStructure();
    argument >> pixmap.width >> pixmap.height >> pixmap.data;
    argument.endStructure();
    return argument;
}

class TrayFixture final : public QObject {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.kde.StatusNotifierItem")
    Q_PROPERTY(QString Id READ id)
    Q_PROPERTY(QString Title READ title)
    Q_PROPERTY(QString Status READ status)
    Q_PROPERTY(QString IconName READ icon)
    Q_PROPERTY(TrayPixmaps IconPixmap READ pixmaps)
    Q_PROPERTY(bool ItemIsMenu READ isMenu)
  public:
    QString titleValue = QStringLiteral("Fcitx fixture");
    QString statusValue = QStringLiteral("Active");
    int activated = 0, secondary = 0, menu = 0;
    QString id() const { return QStringLiteral("fixture"); }
    QString title() const { return titleValue; }
    QString status() const { return statusValue; }
    QString icon() const { return {}; }
    bool isMenu() const { return false; }
    TrayPixmaps pixmaps() const { return {TrayPixmap{}}; }
  public slots:
    void Activate(int, int) { ++activated; }
    void SecondaryActivate(int, int) { ++secondary; }
    void ContextMenu(int, int) { ++menu; }
  signals:
    void NewTitle();
    void NewStatus(const QString &status);
};
class TrayTests final : public QObject {
    Q_OBJECT
    QDBusConnection m_client =
        QDBusConnection::connectToBus(QDBusConnection::SessionBus, "tray-fixture");
    QDBusConnection m_stranger =
        QDBusConnection::connectToBus(QDBusConnection::SessionBus, "tray-stranger");
    QDBusMessage call(const QDBusConnection &bus, const QString &method, const QString &arg) {
        auto request = QDBusMessage::createMethodCall("org.kde.StatusNotifierWatcher",
                                                      "/StatusNotifierWatcher",
                                                      "org.kde.StatusNotifierWatcher", method);
        request.setArguments({arg});
        QDBusPendingCallWatcher watcher(bus.asyncCall(request, 2000));
        QEventLoop loop;
        connect(&watcher, &QDBusPendingCallWatcher::finished, &loop, &QEventLoop::quit);
        if (!watcher.isFinished())
            loop.exec();
        return watcher.reply();
    }
  private slots:
    void initTestCase() {
        qDBusRegisterMetaType<TrayPixmap>();
        qDBusRegisterMetaType<TrayPixmaps>();
    }
    void privateBusRegistrationUpdatesActionsAndRemoval() {
        klde::StatusNotifierHost host;
        host.start();
        QVERIFY(host.available());
        QVERIFY(m_client.registerService("org.owode.TrayFixture"));
        TrayFixture item;
        QVERIFY(m_client.registerObject("/StatusNotifierItem", &item,
                                        QDBusConnection::ExportAllContents));
        QCOMPARE(call(m_stranger, "RegisterStatusNotifierItem", "org.owode.TrayFixture").type(),
                 QDBusMessage::ReplyMessage);
        QCOMPARE(host.registeredItems().size(),
                 0); // A client cannot register another process's name.
        QCOMPARE(call(m_client, "RegisterStatusNotifierItem", "org.owode.TrayFixture").type(),
                 QDBusMessage::ReplyMessage);
        QTRY_COMPARE(host.items().size(), 1);
        const auto record = host.items().front().toMap();
        QCOMPARE(record.value("title").toString(), item.titleValue);
        QVERIFY(record.value("icon").toString().startsWith("image://tray/"));
        QVERIFY(!host.image(record.value("icon").toString().mid(13)).isNull());
        const auto decoded = host.image(record.value("icon").toString().mid(13));
        QCOMPARE(decoded.pixelColor(0, 0), QColor(Qt::red));
        QCOMPARE(decoded.pixelColor(decoded.width() - 1, 0), QColor(Qt::blue));
        const auto id = record.value("id").toString();
        {
            klde::StatusNotifierHost observer;
            observer.start();
            QTRY_VERIFY(observer.available());
            QTRY_COMPARE(observer.items().size(), 1);
            QCOMPARE(observer.items().front().toMap().value("id").toString(), id);
        }
        QVERIFY(QDBusConnection::sessionBus()
                    .interface()
                    ->isServiceRegistered("org.kde.StatusNotifierWatcher")
                    .value());
        host.activate(id, 1, 2);
        host.activate(id, 1, 2, true);
        host.contextMenu(id, 1, 2);
        QTRY_COMPARE(item.activated, 1);
        QTRY_COMPARE(item.secondary, 1);
        QTRY_COMPARE(item.menu, 1);
        QSignalSpy updates(&host, &klde::StatusNotifierHost::itemStatusChanged);
        item.titleValue = QStringLiteral("Changed method");
        emit item.NewTitle();
        QTRY_COMPARE(host.items().front().toMap().value("title").toString(), item.titleValue);
        QVERIFY(!updates.isEmpty());
        item.statusValue = QStringLiteral("Passive");
        emit item.NewStatus(item.statusValue);
        QTRY_COMPARE(host.items().size(), 0);
        item.statusValue = QStringLiteral("NeedsAttention");
        emit item.NewStatus(item.statusValue);
        QTRY_COMPARE(host.items().size(), 1);
        QVERIFY(host.items().front().toMap().value("attention").toBool());
        m_client.unregisterService("org.owode.TrayFixture");
        QTRY_COMPARE(host.registeredItems().size(), 0);
        m_client.unregisterObject("/StatusNotifierItem");
        QDBusConnection::disconnectFromBus("tray-fixture");
        // Closing the last connection drops the sender, so its registrations disappear.
        m_client = m_stranger;
        QTRY_COMPARE(host.registeredItems().size(), 0);
    }
};
QTEST_MAIN(TrayTests)
#include "test_status_notifier.moc"

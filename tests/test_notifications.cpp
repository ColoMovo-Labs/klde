// SPDX-License-Identifier: GPL-3.0-or-later
#include "notifications/NotificationServer.h"
#include <QDBusArgument>
#include <QDBusConnectionInterface>
#include <QDBusPendingCallWatcher>
#include <QEventLoop>
#include <QSignalSpy>
#include <QtTest>

class LockerFixture final : public QObject {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.freedesktop.ScreenSaver")
  public slots:
    bool GetActive() const { return false; }
  signals:
    void ActiveChanged(bool active);
};
class NotificationTests final : public QObject {
    Q_OBJECT
    QDBusConnection m_bus =
        QDBusConnection::connectToBus(QDBusConnection::SessionBus, "notification-server-fixture");
    QDBusConnection m_client = QDBusConnection::sessionBus();
    LockerFixture m_locker;
    std::unique_ptr<klde::NotificationModel> m_model;
    std::unique_ptr<klde::NotificationServer> m_server;
    QDBusMessage call(const QString &method, const QVariantList &arguments = {}) {
        auto request = QDBusMessage::createMethodCall("org.freedesktop.Notifications",
                                                      "/org/freedesktop/Notifications",
                                                      "org.freedesktop.Notifications", method);
        request.setArguments(arguments);
        QDBusPendingCallWatcher watcher(m_client.asyncCall(request));
        QEventLoop loop;
        QTimer timeout;
        timeout.setSingleShot(true);
        connect(&watcher, &QDBusPendingCallWatcher::finished, &loop, &QEventLoop::quit);
        connect(&timeout, &QTimer::timeout, &loop, &QEventLoop::quit);
        timeout.start(3000);
        if (!watcher.isFinished())
            loop.exec();
        if (!watcher.isFinished())
            qFatal("Private notification bus request timed out");
        return watcher.reply();
    }
    uint notify(uint replace = 0, int expiry = -1, const QVariantMap &hints = {},
                const QStringList &actions = {},
                const QString &body = QStringLiteral("<b>Hello</b> world")) {
        const auto reply =
            call("Notify", {QString("Fixture"), replace, QString{}, QString("A notification"), body,
                            actions, hints, expiry});
        if (reply.type() == QDBusMessage::ErrorMessage)
            qFatal("Notify error: %s", qPrintable(reply.errorMessage()));
        return reply.arguments().first().toUInt();
    }
  private slots:
    void initTestCase() {
        QVERIFY(m_bus.isConnected());
        QVERIFY(m_bus.registerService("org.freedesktop.ScreenSaver"));
        QVERIFY(m_bus.registerObject("/ScreenSaver", &m_locker,
                                     QDBusConnection::ExportAllSlots |
                                         QDBusConnection::ExportAllSignals));
        QVERIFY(m_client.connect("org.freedesktop.Notifications", "/org/freedesktop/Notifications",
                                 "org.freedesktop.Notifications", "NotificationClosed", this,
                                 SLOT(observeClosed(uint, uint))));
        QVERIFY(m_client.connect("org.freedesktop.Notifications", "/org/freedesktop/Notifications",
                                 "org.freedesktop.Notifications", "ActionInvoked", this,
                                 SLOT(observeAction(uint, QString))));
    }
    void init() {
        m_model = std::make_unique<klde::NotificationModel>();
        m_server = std::make_unique<klde::NotificationServer>(m_model.get(), m_bus);
        QVERIFY(m_server->start());
        QTRY_VERIFY(!m_model->locked());
    }
    void cleanup() {
        m_server.reset();
        m_model.reset();
    }
    void capabilitiesAndServerInformationUseTheStandardSignature() {
        const auto capabilities =
            qdbus_cast<QStringList>(call("GetCapabilities").arguments().first());
        QVERIFY(capabilities.contains("body-markup"));
        QVERIFY(capabilities.contains("actions"));
        QVERIFY(!capabilities.contains("inline-reply"));
        const auto info = call("GetServerInformation");
        QCOMPARE(info.type(), QDBusMessage::ReplyMessage);
        QCOMPARE(info.signature(), QString("ssss"));
        QCOMPARE(info.arguments().first().toString(), QString("owoDE"));
        QCOMPARE(info.arguments().last().toString(), QString("1.2"));
        // Internal privacy slots are not exported as public D-Bus methods.
        QCOMPARE(call("lockerActiveChanged", {false}).type(), QDBusMessage::ErrorMessage);
    }
    void replacementIsAtomicAndBodyMarkupCannotLoadRemoteImages() {
        const auto id = notify();
        QVERIFY(id > 0);
        QCOMPARE(m_model->count(), 1);
        QCOMPARE(m_model->data(m_model->index(0), klde::NotificationModel::BodyTextRole).toString(),
                 QString("Hello world"));
        QCOMPARE(notify(id, -1, {}, {},
                        "<img src=\"https://invalid.example/private\" alt=\"Image\"/><a "
                        "href=\"javascript:bad\">Click</a>"),
                 id);
        QCOMPARE(m_model->count(), 1);
        const auto markup =
            m_model->data(m_model->index(0), klde::NotificationModel::BodyMarkupRole).toString();
        QVERIFY(!markup.contains("https:"));
        QVERIFY(!markup.contains("javascript:"));
        QCOMPARE(m_model->unreadCount(), 1);
        m_model->markRead(QString::number(id));
        QCOMPARE(m_model->unreadCount(), 0);
        QCOMPARE(notify(id), id);
        QCOMPARE(m_model->unreadCount(), 1);
    }
    void expirationAndApplicationCloseEmitTheirWireReasons() {
        QSignalSpy closed(this, &NotificationTests::closedObserved);
        const auto expired = notify(0, 80);
        QTRY_COMPARE(m_model->count(), 0);
        QTRY_COMPARE(closed.size(), 1);
        QCOMPARE(closed.first().at(0).toUInt(), expired);
        QCOMPARE(closed.first().at(1).toUInt(), 1u);
        const auto explicitId = notify(0, 0);
        call("CloseNotification", {explicitId});
        QTRY_COMPARE(closed.size(), 2);
        QCOMPARE(closed.last().at(1).toUInt(), 3u);
        QCOMPARE(call("CloseNotification", {explicitId}).type(), QDBusMessage::ErrorMessage);
    }
    void actionsValidateKeysAndHonorResident() {
        QSignalSpy actions(this, &NotificationTests::actionObserved);
        QSignalSpy closed(this, &NotificationTests::closedObserved);
        const auto id = notify(0, 0, {{"resident", true}}, {"open", "Open"});
        QVERIFY(!m_model->invokeAction(QString::number(id), "invented"));
        QVERIFY(m_model->invokeAction(QString::number(id), "open"));
        QTRY_COMPARE(actions.size(), 1);
        QCOMPARE(actions.first().at(0).toUInt(), id);
        QCOMPARE(actions.first().at(1).toString(), QString("open"));
        QCOMPARE(m_model->count(), 1);
        QCOMPARE(notify(id, 0, {}, {"open", "Open"}), id);
        QVERIFY(m_model->invokeAction(QString::number(id), "open"));
        QTRY_COMPARE(closed.size(), 1);
        QCOMPARE(closed.first().at(1).toUInt(), 2u);
    }
    void popupQueueDndAndLockPrivacyRemainIndependentOfHistory() {
        const auto first = notify(0, -1, {{"urgency", uchar(2)}});
        const auto second = notify();
        QCOMPARE(m_model->popup().value("id").toString(), QString::number(first));
        QCOMPARE(m_model->popup().value("severity").toInt(), 2);
        m_model->advancePopup();
        QCOMPARE(m_model->popup().value("id").toString(), QString::number(second));
        m_model->setDnd(true);
        notify();
        QVERIFY(m_model->popup().isEmpty());
        QCOMPARE(m_model->count(), 3);
        m_model->setDnd(false);
        QVERIFY(m_model->popup().isEmpty());
        notify();
        QVERIFY(!m_model->popup().isEmpty());
        m_model->setLocked(true);
        QVERIFY(m_model->popup().isEmpty());
        QVERIFY(m_model->data(m_model->index(0), klde::NotificationModel::BodyTextRole)
                    .toString()
                    .isEmpty());
        m_model->setLocked(false);
        QVERIFY(m_model->popup().isEmpty());
    }
    void hoverPausesAnExplicitExpiry() {
        notify(0, 250);
        m_model->pausePopup(true);
        QTest::qWait(350);
        QCOMPARE(m_model->count(), 1);
        m_model->pausePopup(false);
        QTRY_COMPARE(m_model->count(), 0);
    }
    void imageDataDecodesRgbChannelsWithBoundsChecking() {
        QDBusArgument image;
        image.beginStructure();
        image << 2 << 1 << 8 << true << 8 << 4 << QByteArray::fromHex("ff0000ff00ff00ff");
        image.endStructure();
        const auto id = notify(0, 0, {{"image-data", QVariant::fromValue(image)}});
        const auto pixels = m_model->image(id, QSize(2, 1));
        QCOMPARE(pixels.pixelColor(0, 0), QColor(Qt::red));
        QCOMPARE(pixels.pixelColor(1, 0), QColor(Qt::green));
    }
    void normalPopupRetractsButCriticalWaitsForAnExplicitAction() {
        const auto critical = notify(0, 80, {{"urgency", uchar(2)}});
        const auto normal = notify(0, 0);
        QTest::qWait(4700);
        QCOMPARE(m_model->popup().value("id").toString(), QString::number(critical));
        m_model->advancePopup();
        QCOMPARE(m_model->popup().value("id").toString(), QString::number(normal));
        QTRY_VERIFY_WITH_TIMEOUT(m_model->popup().isEmpty(), 6000);
        QCOMPARE(m_model->count(), 2); // Popup dismissal is separate from history.
    }
    void transientNotificationsAreNotRetainedAndHistoryIsBounded() {
        notify(0, 0, {{"transient", true}});
        m_model->advancePopup();
        QCOMPARE(m_model->count(), 0);
        m_model->setDnd(true);
        notify(0, 0, {{"transient", true}});
        QTRY_COMPARE(m_model->count(), 0);
        klde::NotificationModel::Incoming incoming;
        incoming.sender = QStringLiteral(":bounded-test");
        incoming.source = QStringLiteral("Bounded fixture");
        incoming.expireTimeout = 0;
        for (int i = 0; i < 110; ++i)
            QVERIFY(m_model->receive(0, incoming) > 0);
        QCOMPARE(m_model->count(), 100);
        QVERIFY(m_model->popup().isEmpty());
    }
    void anExistingServerIsNeverReplaced() {
        const auto owner = m_bus.interface()->serviceOwner("org.freedesktop.Notifications").value();
        klde::NotificationModel otherModel;
        klde::NotificationServer other(&otherModel, m_client);
        QVERIFY(!other.start());
        QCOMPARE(otherModel.serviceStatus(), QString("another-server"));
        QVERIFY(!otherModel.available());
        QCOMPARE(m_bus.interface()->serviceOwner("org.freedesktop.Notifications").value(), owner);
        notify();
        QCOMPARE(m_model->count(), 1);
        QCOMPARE(otherModel.count(), 0);
        klde::NotificationModel sameConnectionModel;
        klde::NotificationServer duplicate(&sameConnectionModel, m_bus);
        QVERIFY(!duplicate.start());
        QCOMPARE(m_bus.interface()->serviceOwner("org.freedesktop.Notifications").value(), owner);
        notify();
        QCOMPARE(m_model->count(), 2);
    }
  public slots:
    void observeClosed(uint id, uint reason) { emit closedObserved(id, reason); }
    void observeAction(uint id, const QString &key) { emit actionObserved(id, key); }
  signals:
    void closedObserved(uint id, uint reason);
    void actionObserved(uint id, const QString &key);
};
QTEST_MAIN(NotificationTests)
#include "test_notifications.moc"

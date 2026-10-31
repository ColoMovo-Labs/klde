// SPDX-License-Identifier: GPL-3.0-or-later
#include "live/BrightnessSource.h"
#include "live/HostTelemetrySource.h"
#include "live/LiveSystemBackend.h"
#include "live/MprisSource.h"
#include "live/UPowerBatterySource.h"
#include "mock/SystemStateModel.h"
#include <QDir>
#include <QFile>
#include <QTemporaryDir>
#include <QtTest>

namespace {
void write(const QString &path, const QByteArray &bytes) {
    QDir().mkpath(QFileInfo(path).path());
    QFile file(path);
    QVERIFY(file.open(QIODevice::WriteOnly));
    file.write(bytes);
}
const QByteArray stat1("cpu  100 0 100 700 100 0 0 0 0 0\ncpu0 1 2 3 4\n");
const QByteArray stat2("cpu  200 0 200 750 150 0 0 0 0 0\n");
const QByteArray meminfo("MemTotal:       16000000 kB\nMemFree:  1 kB\n"
                         "MemAvailable:    4000000 kB\n");
} // namespace

class LiveSystemTest final : public QObject {
    Q_OBJECT
  private slots:
    void parsesKernelCounters() {
        const auto first = klde::HostTelemetrySource::parseCpuTimes(stat1);
        const auto second = klde::HostTelemetrySource::parseCpuTimes(stat2);
        QVERIFY(first && second);
        QCOMPARE(first->total, quint64{1000});
        QCOMPARE(first->busy, quint64{200});
        // 200 busy of 300 elapsed jiffies.
        QCOMPARE(second->usageSince(*first), 67);
        QCOMPARE(first->usageSince(*second), 0);
        QVERIFY(!klde::HostTelemetrySource::parseCpuTimes("intr 1 2 3\n"));
        QVERIFY(!klde::HostTelemetrySource::parseCpuTimes("cpu 1 x 3 4\n"));
        QCOMPARE(klde::HostTelemetrySource::parseMemoryUsedPercent(meminfo).value_or(-1), 75);
        QVERIFY(!klde::HostTelemetrySource::parseMemoryUsedPercent("MemTotal: 0 kB\n"));
        QVERIFY(!klde::HostTelemetrySource::parseMemoryUsedPercent(
            "MemTotal: 10 kB\nMemAvailable: 20 kB\n"));
    }

    void selectsPackageSensorBeforeThermalZones() {
        QTemporaryDir root;
        QVERIFY(root.isValid());
        klde::SystemStateModel state;
        write(root.filePath("sys/class/thermal/thermal_zone0/type"), "acpitz\n");
        write(root.filePath("sys/class/thermal/thermal_zone0/temp"), "41000\n");
        klde::HostTelemetrySource source(&state, root.path());
        QCOMPARE(source.findTemperatureInput(),
                 QStringLiteral("sys/class/thermal/thermal_zone0/temp"));
        write(root.filePath("sys/class/hwmon/hwmon0/name"), "nvme\n");
        write(root.filePath("sys/class/hwmon/hwmon0/temp1_input"), "30000\n");
        write(root.filePath("sys/class/hwmon/hwmon3/name"), "coretemp\n");
        write(root.filePath("sys/class/hwmon/hwmon3/temp1_label"), "Core 0\n");
        write(root.filePath("sys/class/hwmon/hwmon3/temp1_input"), "50000\n");
        write(root.filePath("sys/class/hwmon/hwmon3/temp2_label"), "Package id 0\n");
        write(root.filePath("sys/class/hwmon/hwmon3/temp2_input"), "63400\n");
        QCOMPARE(source.findTemperatureInput(),
                 QStringLiteral("sys/class/hwmon/hwmon3/temp2_input"));
    }

    void livePathsArePinnedAgainstFixtures() {
        QTemporaryDir root;
        QVERIFY(root.isValid());
        write(root.filePath("proc/stat"), stat1);
        write(root.filePath("proc/meminfo"), meminfo);
        klde::SystemStateModel state;
        klde::HostTelemetrySource source(&state, root.path());
        source.start(60000);
        // No temperature sensor in this tree: report the capability, not a number.
        QCOMPARE(state.value("capabilities.sensors").toBool(), false);
        QCOMPARE(state.value("memory.usedPercent").toInt(), 75);
        QVERIFY(!state.isLive("cpu.usage")); // needs a second sample
        write(root.filePath("proc/stat"), stat2);
        source.sample();
        QCOMPARE(state.value("cpu.usage").toInt(), 67);
        QVERIFY(state.isLive("cpu.usage"));
        QVERIFY(!state.requestValue("cpu.usage", 5));
        QVERIFY(state.replacePreview(state.baseline()));
        QCOMPARE(state.value("cpu.usage").toInt(), 67);
        QCOMPARE(state.value("memory.usedPercent").toInt(), 75);
        QVERIFY(!state.publishLive("cpu.usage", 101));
        QVERIFY(!state.publishLive("not.a.path", 1));
        // Paths without a live source keep their preview behavior.
        QVERIFY(state.requestValue("notifications.dnd", true));
        source.stop();
    }

    void selectsBacklightAndNeverWritesZero() {
        QTemporaryDir root;
        QVERIFY(root.isValid());
        klde::SystemStateModel state;
        klde::BrightnessSource source(&state, root.path());
        QVERIFY(source.findDevice().isEmpty());
        write(root.filePath("sys/class/backlight/acpi_video0/type"), "firmware\n");
        write(root.filePath("sys/class/backlight/acpi_video0/max_brightness"), "0\n");
        write(root.filePath("sys/class/backlight/intel_backlight/type"), "raw\n");
        write(root.filePath("sys/class/backlight/intel_backlight/max_brightness"), "19200\n");
        write(root.filePath("sys/class/backlight/intel_backlight/brightness"), "9600\n");
        // A firmware interface with no range is unusable; fall through to raw.
        QCOMPARE(source.findDevice(), QStringLiteral("intel_backlight"));
        source.start(60000);
        QVERIFY(state.value("capabilities.brightness").toBool());
        QCOMPARE(state.value("brightness").toInt(), 50);
        QVERIFY(state.isLive("brightness"));
        QCOMPARE(klde::BrightnessSource::rawFor(0, 19200), 192);
        QCOMPARE(klde::BrightnessSource::rawFor(100, 19200), 19200);
        QCOMPARE(klde::BrightnessSource::percent(-1, 100), 0);
    }

    void mapsSceneProfilesToDaemonIdentifiers() {
        using klde::LiveSystemBackend;
        for (const auto *name : {"Performance", "Balanced", "Power saver"})
            QCOMPARE(LiveSystemBackend::profileName(LiveSystemBackend::profileId(name)),
                     QString::fromLatin1(name));
        QVERIFY(LiveSystemBackend::profileId("Turbo").isEmpty());
        QCOMPARE(LiveSystemBackend::profileId("Power saver"), QStringLiteral("power-saver"));
    }

    void boundsUntrustedMediaMetadata() {
        const QVariantMap metadata{{"xesam:title", QString("Song\u0007 <b>x</b>")},
                                   {"xesam:artist", QStringList{"A", "B"}}};
        QCOMPARE(klde::MprisSource::title(metadata), QStringLiteral("Song <b>x</b>"));
        QCOMPARE(klde::MprisSource::artist(metadata), QStringLiteral("A, B"));
        QVERIFY(klde::MprisSource::title(QVariantMap{{"xesam:title", QString(500, 'x')}}).size() <=
                120);
        QVERIFY(klde::MprisSource::title({}).isEmpty());
    }

    void projectsUPowerDisplayDevice() {
        using klde::UPowerBatterySource;
        QVERIFY(!UPowerBatterySource::project({}).value("available").toBool());
        QVERIFY(!UPowerBatterySource::project({{"IsPresent", true}, {"Type", 1u}})
                     .value("available")
                     .toBool());
        const auto discharging = UPowerBatterySource::project(
            {{"IsPresent", true}, {"Type", 2u}, {"Percentage", 57.4}, {"State", 2u}});
        QVERIFY(discharging.value("available").toBool());
        QCOMPARE(discharging.value("percent").toInt(), 57);
        QVERIFY(!discharging.value("charging").toBool());
        const auto full = UPowerBatterySource::project(
            {{"IsPresent", true}, {"Type", 2u}, {"Percentage", 100.0}, {"State", 4u}});
        QVERIFY(full.value("charging").toBool());
        QCOMPARE(UPowerBatterySource::project(
                     {{"IsPresent", true}, {"Type", 2u}, {"Percentage", 140.0}, {"State", 1u}})
                     .value("percent")
                     .toInt(),
                 100);
    }
};

QTEST_GUILESS_MAIN(LiveSystemTest)
#include "test_live_system.moc"

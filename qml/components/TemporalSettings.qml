// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

LabPanel {
    id: root
    objectName: "temporalDetail"
    heading: I18n.t("temporal.title")
    subtitle: I18n.t(Shell.time.reading.mock ? "temporal.mock" : "temporal.system")
    signal studyRequested
    TemporalCapsule {
        sizeMode: "expanded"
        Layout.alignment: Qt.AlignHCenter
    }
    Label {
        text: I18n.date(Shell.time.reading.dateTime, false) + " · " + I18n.t("temporal.season." + Shell.time.reading.season)
        font: Tokens.label
        color: Tokens.textPrimary
        Layout.alignment: Qt.AlignHCenter
    }
    Label {
        text: I18n.t("temporal.astronomy") + "\n" + I18n.t("temporal.sun-events") + "  " + Shell.time.reading.astronomy.sunrise + " / " + Shell.time.reading.astronomy.sunset + "\n" + I18n.t("temporal.moon-events") + "  " + Shell.time.reading.astronomy.moonrise + " / " + Shell.time.reading.astronomy.moonset + " · " + I18n.t("temporal.moon-phase")
        font: Tokens.caption
        color: Tokens.textSecondary
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    StateChoice {
        visible: Shell.time.reading.mock
        label: I18n.t("temporal.phase")
        path: "temporal.phase"
        values: ["auto", "clear-morning", "cloudy-day", "sunset", "rainy-evening", "starry-night", "moonlit-night"]
        labels: values.map(v => I18n.t("temporal.phase." + v))
    }
    Label {
        text: I18n.t("temporal.desktop-mode")
        font: Tokens.label
        color: Tokens.textPrimary
    }
    ChoiceBox {
        objectName: "desktopModeChoice"
        Layout.fillWidth: true
        model: [I18n.t("temporal.mode.default"), I18n.t("temporal.mode.clock"), I18n.t("temporal.mode.focus")]
        currentIndex: !Shell.state.snapshot.appearance.ambient ? 0 : Shell.state.snapshot.appearance.focus ? 2 : 1
        Accessible.name: I18n.t("temporal.desktop-mode")
        onActivated: {
            const selected = currentIndex;
            Shell.state.requestValue("appearance.focus", selected === 2);
            Shell.state.requestValue("appearance.ambient", selected > 0);
        }
    }
    ActionButton {
        visible: Shell.time.reading.mock
        text: I18n.t("temporal.advance")
        Layout.fillWidth: true
        onClicked: Shell.state.advanceMinutes(1)
    }
}

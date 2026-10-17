// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

LabPanel {
    id: root
    heading: I18n.t("temporal.title")
    subtitle: I18n.t("temporal.mock")
    TemporalCapsule {
        compact: false
        Layout.alignment: Qt.AlignHCenter
    }
    StateChoice {
        label: I18n.t("temporal.phase")
        path: "temporal.phase"
        values: ["auto", "clear-morning", "cloudy-day", "sunset", "rainy-evening", "starry-night", "moonlit-night"]
        labels: values.map(v => I18n.t("temporal.phase." + v))
    }
    ActionButton {
        text: I18n.t("temporal.advance")
        Layout.fillWidth: true
        onClicked: Shell.state.advanceMinutes(1)
    }
    Switch {
        text: I18n.t("temporal.ambient")
        checked: Shell.state.snapshot.appearance.ambient
        onToggled: Shell.state.requestValue("appearance.ambient", checked)
    }
    Label {
        text: I18n.t("temporal.season." + Shell.time.reading.season) + " · " + I18n.t("temporal.season.note")
        font: Tokens.body
        color: Tokens.textSecondary
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
}

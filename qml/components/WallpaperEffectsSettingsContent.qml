// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ColumnLayout {
    id: root
    signal viewRequested(string view)
    readonly property var effects: Shell.wallpaperEffects.state
    spacing: Tokens.rowGap
    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.space8
        MockBadge {}
        Label {
            text: I18n.t("wallpaper.mock")
            font: Tokens.caption
            color: Tokens.textSecondary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
    StateChoice {
        label: I18n.t("wallpaper.mode")
        path: "wallpaperEffects.mode"
        values: ["normal", "depth", "soft-blur"]
        labels: values.map(v => I18n.t("wallpaper.mode." + v))
    }
    StateChoice {
        label: I18n.t("wallpaper.quality")
        path: "wallpaperEffects.quality"
        values: ["power-saver", "standard", "refined"]
        labels: values.map(v => I18n.t("wallpaper.quality." + v))
    }
    Label {
        text: I18n.t(root.effects.stale ? "wallpaper.cache.stale" : "wallpaper.cache." + root.effects.cacheState)
        font: Tokens.body
        color: root.effects.cacheState === "failed" ? Tokens.error : Tokens.textSecondary
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    Switch {
        text: I18n.t("wallpaper.foreground")
        checked: root.effects.foreground
        onToggled: Shell.state.requestValue("wallpaperEffects.foreground", checked)
    }
    Switch {
        text: I18n.t("wallpaper.link")
        checked: root.effects.lockLinked
        onToggled: Shell.state.requestValue("wallpaperEffects.lockLinked", checked)
    }
    Switch {
        text: I18n.t("wallpaper.auto")
        checked: root.effects.autoCache
        onToggled: Shell.state.requestValue("wallpaperEffects.autoCache", checked)
    }
    StateSlider {
        label: I18n.t("wallpaper.blur")
        iconName: "weather"
        path: "wallpaperEffects.blurStrength"
        maximumValue: 3
        unit: ""
    }
    StateSlider {
        label: I18n.t("wallpaper.lock-blur")
        iconName: "moon"
        path: "wallpaperEffects.lockBlurStrength"
        maximumValue: 3
        unit: ""
    }
    RowLayout {
        ActionButton {
            text: I18n.t("wallpaper.regenerate")
            onClicked: Shell.wallpaperEffects.regeneratePreview()
        }
        ActionButton {
            text: I18n.t("wallpaper.clear")
            onClicked: Shell.wallpaperEffects.clearPreview()
        }
    }
    ActionButton {
        text: I18n.t("wallpaper.lock-preview")
        Layout.fillWidth: true
        onClicked: root.viewRequested("lock-preview")
    }
}

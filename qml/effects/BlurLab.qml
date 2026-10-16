// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ShellPopup {
    id: root
    objectName: "blurLab"
    modal: true
    width: Tokens.panelWidth + Tokens.space32
    height: contentColumn.implicitHeight + padding * 2
    contentItem: ColumnLayout {
        id: contentColumn
        spacing: Tokens.space16
        RowLayout {
            Label {
                text: I18n.t("shell.blur.title")
                font: Tokens.title
                color: Tokens.textPrimary
                Layout.fillWidth: true
            }
            IconButton {
                iconName: "close"
                text: I18n.t("shell.blur.close")
                onClicked: root.close()
            }
        }
        OwnedBlurSample {
            id: sample
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Tokens.blurSampleWidth
            Layout.preferredHeight: Tokens.blurSampleHeight
        }
        Label {
            text: Shell.blur.quality === BlurBackend.Off ? I18n.t("shell.blur.unfiltered") : Shell.blur.ownedContentAvailable ? I18n.t("shell.blur.gpu") : I18n.t("shell.blur.fallback")
            font: Tokens.label
            color: Tokens.textPrimary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        ChoiceBox {
            Layout.fillWidth: true
            model: [I18n.t("common.off"), I18n.t("common.low"), I18n.t("common.medium"), I18n.t("common.high")]
            currentIndex: Shell.blur.quality
            Accessible.name: I18n.t("shell.blur.quality")
            onActivated: {
                Shell.scenes.customize("blurEnabled", currentIndex > 0);
                if (currentIndex > 0)
                    Shell.scenes.customize("blurQuality", currentIndex);
            }
        }
        Label {
            text: I18n.t("shell.blur.explanation")
            font: Tokens.caption
            color: Tokens.textSecondary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        ActionButton {
            text: I18n.t("shell.blur.refresh")
            font: Tokens.label
            onClicked: sample.revision += 1
        }
    }
}

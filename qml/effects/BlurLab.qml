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
                text: qsTr("A softer view.")
                font: Tokens.title
                color: Tokens.textPrimary
                Layout.fillWidth: true
            }
            IconButton {
                iconName: "close"
                text: qsTr("Close blur lab")
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
            text: Shell.blur.quality === BlurBackend.Off ? qsTr("Unfiltered sample") : Shell.blur.ownedContentAvailable ? qsTr("GPU filtering · KLDE-owned image") : qsTr("Opaque fallback · GPU effect unavailable")
            font: Tokens.label
            color: Tokens.textPrimary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        ComboBox {
            Layout.fillWidth: true
            model: [qsTr("Off"), qsTr("Low"), qsTr("Medium"), qsTr("High")]
            currentIndex: Shell.blur.quality
            Accessible.name: qsTr("Owned-content blur quality")
            onActivated: {
                Shell.scenes.customize("blurEnabled", currentIndex > 0);
                if (currentIndex > 0)
                    Shell.scenes.customize("blurQuality", currentIndex);
            }
        }
        Label {
            text: qsTr("This sample owns its pixels. Native blur behind desktop windows is not connected. Static captures update only when invalidated.")
            font: Tokens.caption
            color: Tokens.textSecondary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Button {
            text: qsTr("Refresh capture")
            font: Tokens.label
            onClicked: sample.revision += 1
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import KLDE.Backends

Item {
    id: root
    default property alias contentData: content.data
    property real padding: Tokens.space16
    property real cornerRadius: Tokens.radiusXL
    property color tone: Tokens.surfaceElevated
    property Item backdropSource: null
    property int backdropRevision: 0
    readonly property bool hasBlur: backdropSource !== null && Tokens.transparencyEnabled && Shell.blur.ownedContentAvailable && Shell.blur.renderingAllowed && Shell.blur.quality !== BlurBackend.Off

    function refreshCapture(): void {
        backdropRevision += 1;
    }
    onXChanged: Qt.callLater(refreshCapture)
    onYChanged: Qt.callLater(refreshCapture)
    Connections {
        target: Tokens
        function onDarkModeChanged(): void {
            Qt.callLater(root.refreshCapture);
        }
    }

    Loader {
        anchors.fill: parent
        active: root.visible && root.hasBlur
        sourceComponent: Component {
            OwnedBackdrop {
                sourceItem: root.backdropSource
                cornerRadius: root.cornerRadius
                revision: root.backdropRevision
            }
        }
    }
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: Tokens.elevationLow
        anchors.bottomMargin: -Tokens.elevationLow
        radius: root.cornerRadius
        color: Tokens.shadow
        opacity: Tokens.shadowsEnabled ? Tokens.shadowOpacity * (Tokens.shadowLevel === 0 ? 0.6 : Tokens.shadowLevel === 2 ? 1.4 : 1) : 0
    }
    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: Qt.rgba(root.tone.r, root.tone.g, root.tone.b, root.hasBlur ? Tokens.frostedSurfaceOpacity : 1)
        border.width: Tokens.space1
        border.color: Qt.rgba(Tokens.outline.r, Tokens.outline.g, Tokens.outline.b, Tokens.outlineOpacity)
    }
    Item {
        id: content
        anchors.fill: parent
        anchors.margins: root.padding
    }
}

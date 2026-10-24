// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

// Mock-first comparison of the frozen 0.1 surfaces with the fusion direction:
// Material Expressive shape and spring motion, Fluent-style material tiers and
// a little refracting glass. Every material samples only owned wallpaper.
Item {
    id: root
    objectName: "materialStudy"
    property int revealRevision: 0
    property int captureRevision: 0
    readonly property real specimenWidth: Math.max(Tokens.materialFlyoutWidth, Math.min(Tokens.materialSpecimenWidth, (width - Tokens.desktopMargin * 2 - Tokens.materialLabelWidth - Tokens.space32 * 2) / 2))
    function replay(): void {
        revealRevision += 1;
    }
    function recapture(): void {
        captureRevision += 1;
    }
    Component.onCompleted: {
        replay();
        Qt.callLater(recapture);
    }
    onWidthChanged: Qt.callLater(recapture)
    onHeightChanged: Qt.callLater(recapture)

    // A specimen surface with a replayable entrance. The current side repeats the
    // ShellPopup transition; the fusion side lifts and scales on springs.
    component RevealSurface: Surface {
        id: card
        property bool fusion: false
        property int order: 0
        property int revision: 0
        property int captureRevision: 0
        // Pressable specimens squeeze under the pointer; Glass also deepens its lens.
        property bool pressable: false
        readonly property bool pressed: pressable && tap.pressed
        transformOrigin: Item.Bottom
        pressAmount: fusion && pressed ? 1 : 0
        Behavior on pressAmount {
            NumberAnimation {
                duration: Tokens.springEffects.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Tokens.springEffects.curve
            }
        }
        transform: [
            Translate {
                id: lift
            },
            Scale {
                origin.x: card.width / 2
                origin.y: card.height / 2
                xScale: yScale
                yScale: card.fusion && card.pressed ? Tokens.glassPressScale : 1
                Behavior on yScale {
                    NumberAnimation {
                        duration: Tokens.springSpatialFast.duration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Tokens.springSpatialFast.curve
                    }
                }
            },
            Scale {
                origin.x: card.width / 2
                origin.y: card.height / 2
                xScale: yScale
                yScale: !card.fusion && card.pressed ? Tokens.glassPressScale : 1
                Behavior on yScale {
                    NumberAnimation {
                        duration: Tokens.motionFast
                        easing.type: Tokens.emphasizedDecelerate
                    }
                }
            }
        ]
        TapHandler {
            id: tap
            enabled: card.pressable
        }
        onRevisionChanged: fusion ? springEntrance.restart() : cubicEntrance.restart()
        onCaptureRevisionChanged: refreshCapture()
        SequentialAnimation {
            id: cubicEntrance
            ScriptAction {
                script: {
                    card.opacity = 0;
                    card.scale = Tokens.popupStartScale;
                }
            }
            PauseAnimation {
                duration: card.order * Tokens.springStagger
            }
            ParallelAnimation {
                NumberAnimation {
                    target: card
                    property: "opacity"
                    to: 1
                    duration: Tokens.motionNormal
                }
                NumberAnimation {
                    target: card
                    property: "scale"
                    to: 1
                    duration: Tokens.motionNormal
                    easing.type: Tokens.emphasizedDecelerate
                }
            }
            ScriptAction {
                script: card.refreshCapture()
            }
        }
        SequentialAnimation {
            id: springEntrance
            ScriptAction {
                script: {
                    card.opacity = 0;
                    card.scale = Tokens.revealScale;
                    lift.y = Tokens.revealLift;
                }
            }
            PauseAnimation {
                duration: card.order * Tokens.springStagger
            }
            ParallelAnimation {
                NumberAnimation {
                    target: card
                    property: "opacity"
                    to: 1
                    duration: Tokens.springEffects.duration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Tokens.springEffects.curve
                }
                NumberAnimation {
                    target: card
                    property: "scale"
                    to: 1
                    duration: Tokens.springSpatial.duration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Tokens.springSpatial.curve
                }
                NumberAnimation {
                    target: lift
                    property: "y"
                    to: 0
                    duration: Tokens.springSpatial.duration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Tokens.springSpatial.curve
                }
            }
            ScriptAction {
                script: card.refreshCapture()
            }
        }
    }

    // Long-lived panel content. Fusion pairs an Expressive headline with
    // Fluent-style inset rows on small radii inside the large outer container.
    component PanelSample: ColumnLayout {
        id: panel
        property bool fusion: false
        spacing: panel.fusion ? Tokens.space6 : Tokens.space8
        Label {
            text: I18n.t("material.sample.display")
            font: panel.fusion ? Tokens.headline : Tokens.title
            color: Tokens.textPrimary
        }
        Label {
            text: I18n.t("material.sample.display.hint")
            font: Tokens.caption
            color: Tokens.textSecondary
            Layout.bottomMargin: Tokens.space4
        }
        Repeater {
            model: [["material.sample.night", I18n.t("common.on")], ["material.sample.scale", "125%"]]
            delegate: Rectangle {
                id: row
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: Tokens.controlHeight
                radius: panel.fusion ? Tokens.radiusS : Tokens.radiusM
                color: panel.fusion ? Qt.rgba(Tokens.surfaceContainerHigh.r, Tokens.surfaceContainerHigh.g, Tokens.surfaceContainerHigh.b, 0.72) : Tokens.surfaceContainer
                border.width: panel.fusion ? Tokens.space1 : 0
                border.color: Tokens.surfaceEdge
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.space12
                    anchors.rightMargin: Tokens.space12
                    Label {
                        text: I18n.t(row.modelData[0])
                        font: Tokens.label
                        color: Tokens.textPrimary
                        Layout.fillWidth: true
                    }
                    Label {
                        text: row.modelData[1]
                        font: Tokens.label
                        color: panel.fusion ? Tokens.primary : Tokens.textSecondary
                    }
                }
            }
        }
    }

    // Transient menu content. Fusion uses the Fluent selection pill and
    // small-radius rows; the current side uses the shell's tinted container.
    component MenuSample: ColumnLayout {
        id: menu
        property bool fusion: false
        spacing: Tokens.space2
        Repeater {
            model: ["material.sample.copy", "material.sample.paste", "material.sample.rename"]
            delegate: Rectangle {
                id: entry
                required property string modelData
                required property int index
                readonly property bool selected: index === 0
                Layout.fillWidth: true
                implicitHeight: Tokens.materialMenuRow
                radius: menu.fusion ? Tokens.radiusXS : Tokens.radiusM
                color: !entry.selected ? "transparent" : menu.fusion ? Qt.rgba(Tokens.textPrimary.r, Tokens.textPrimary.g, Tokens.textPrimary.b, 0.07) : Tokens.primaryContainer
                Rectangle {
                    visible: menu.fusion && entry.selected
                    anchors.verticalCenter: parent.verticalCenter
                    width: Tokens.materialIndicatorWidth
                    height: Tokens.materialIndicatorHeight
                    radius: width / 2
                    color: Tokens.primary
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Tokens.space12
                    text: I18n.t(entry.modelData)
                    font: Tokens.label
                    color: Tokens.textPrimary
                }
            }
        }
    }

    // Expressive button: the shape morphs from pill to a small Fluent radius and
    // compresses on press, then springs back past its rest size on release.
    component ExpressiveButton: AbstractButton {
        id: button
        implicitHeight: Tokens.controlHeight
        implicitWidth: buttonLabel.implicitWidth + Tokens.space24 * 2
        font: Tokens.label
        focusPolicy: Qt.StrongFocus
        Accessible.role: Accessible.Button
        Accessible.name: text
        scale: down ? Tokens.pressScale : hovered ? Tokens.hoverScale : 1
        Behavior on scale {
            NumberAnimation {
                duration: Tokens.springSpatialMicro.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Tokens.springSpatialMicro.curve
            }
        }
        contentItem: Text {
            id: buttonLabel
            text: button.text
            font: button.font
            color: Tokens.textOnPrimary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: button.down ? Tokens.radiusS : height / 2
            color: button.down ? Qt.darker(Tokens.primary, 1.1) : button.hovered ? Qt.lighter(Tokens.primary, 1.08) : Tokens.primary
            Behavior on radius {
                NumberAnimation {
                    duration: Tokens.springSpatialMicro.duration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Tokens.springSpatialMicro.curve
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: Tokens.springEffectsFast.duration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Tokens.springEffectsFast.curve
                }
            }
            // Fluent double focus ring: an outer ink stroke separated by a gap.
            Rectangle {
                visible: button.visualFocus
                anchors.fill: parent
                anchors.margins: -Tokens.space3
                radius: parent.radius + Tokens.space3
                color: "transparent"
                border.width: Tokens.space2
                border.color: Tokens.textPrimary
            }
        }
    }

    // Expressive switch: the thumb grows when on, swells under the finger and
    // travels on a spatial spring while colours follow an effects spring.
    component ExpressiveSwitch: AbstractButton {
        id: toggle
        checkable: true
        implicitWidth: Tokens.materialSwitchWidth
        implicitHeight: Tokens.materialSwitchHeight
        focusPolicy: Qt.StrongFocus
        Accessible.role: Accessible.CheckBox
        Accessible.checkable: true
        Accessible.checked: checked
        background: Rectangle {
            radius: height / 2
            color: toggle.checked ? Tokens.primary : Tokens.surfaceContainerHighest
            border.width: toggle.checked ? 0 : Tokens.space2
            border.color: Tokens.outline
            Behavior on color {
                ColorAnimation {
                    duration: Tokens.springEffects.duration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Tokens.springEffects.curve
                }
            }
            Rectangle {
                visible: toggle.visualFocus
                anchors.fill: parent
                anchors.margins: -Tokens.space3
                radius: height / 2
                color: "transparent"
                border.width: Tokens.space2
                border.color: Tokens.textPrimary
            }
        }
        contentItem: Item {
            Rectangle {
                id: thumb
                readonly property real diameter: toggle.down ? Tokens.materialThumbPressed : toggle.checked ? Tokens.materialThumbOn : Tokens.materialThumbOff
                width: diameter
                height: diameter
                radius: height / 2
                anchors.verticalCenter: parent.verticalCenter
                x: toggle.checked ? parent.width - (parent.height + diameter) / 2 : (parent.height - diameter) / 2
                color: toggle.checked ? Tokens.textOnPrimary : Tokens.outline
                Behavior on x {
                    NumberAnimation {
                        duration: Tokens.springSpatialMicro.duration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Tokens.springSpatialMicro.curve
                    }
                }
                Behavior on width {
                    NumberAnimation {
                        duration: Tokens.springSpatialMicro.duration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Tokens.springSpatialMicro.curve
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: Tokens.springSpatialMicro.duration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Tokens.springSpatialMicro.curve
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: Tokens.springEffects.duration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Tokens.springEffects.curve
                    }
                }
            }
        }
    }

    // Dock icons lift under the pointer: a cubic ease today, a spatial spring in
    // the fusion. The press itself is handled by the surrounding surface.
    component DockSample: Row {
        id: dockRow
        property bool fusion: false
        spacing: Tokens.space4
        Repeater {
            model: ["folder", "globe", "terminal", "note", "music", "settings"]
            delegate: Item {
                id: slot
                required property string modelData
                width: Tokens.dockItem
                height: Tokens.dockItem
                HoverHandler {
                    id: hover
                }
                Icon {
                    anchors.centerIn: parent
                    name: slot.modelData
                    width: Tokens.dockIcon
                    height: Tokens.dockIcon
                    // One transform per motion language so each keeps its own curve.
                    transform: [
                        Translate {
                            y: dockRow.fusion && hover.hovered ? -Tokens.materialHoverLift : 0
                            Behavior on y {
                                NumberAnimation {
                                    duration: Tokens.springHover.duration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Tokens.springHover.curve
                                }
                            }
                        },
                        Translate {
                            y: !dockRow.fusion && hover.hovered ? -Tokens.materialHoverLift : 0
                            Behavior on y {
                                NumberAnimation {
                                    duration: Tokens.motionFast
                                    easing.type: Tokens.emphasizedDecelerate
                                }
                            }
                        }
                    ]
                }
            }
        }
    }

    component TierLabel: ColumnLayout {
        id: tier
        property string tierId: ""
        Layout.preferredWidth: Tokens.materialLabelWidth
        Layout.alignment: Qt.AlignVCenter
        spacing: Tokens.space2
        Label {
            text: I18n.t("material.tier." + tier.tierId)
            font: Tokens.label
            color: Tokens.textPrimary
        }
        Label {
            text: I18n.t("material.tier." + tier.tierId + ".hint")
            font: Tokens.caption
            color: Tokens.textSecondary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    WallpaperLayers {
        id: backdrop
        anchors.fill: parent
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.desktopMargin
        spacing: Tokens.space16
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.space16
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.space4
                Label {
                    text: I18n.t("material.study.title")
                    font: Tokens.headline
                    color: Tokens.textPrimary
                }
                Label {
                    text: I18n.t("material.study.subtitle")
                    font: Tokens.caption
                    color: Tokens.textSecondary
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                Label {
                    objectName: "materialFallbackNotice"
                    visible: !Shell.blur.ownedContentAvailable
                    text: I18n.t("material.study.fallback")
                    font: Tokens.caption
                    color: Tokens.warning
                }
            }
            ExpressiveButton {
                objectName: "materialReplay"
                text: I18n.t("material.study.replay")
                onClicked: root.replay()
            }
        }
        GridLayout {
            Layout.alignment: Qt.AlignHCenter
            columns: 3
            columnSpacing: Tokens.space32
            rowSpacing: Tokens.space16
            Item {
                Layout.preferredWidth: Tokens.materialLabelWidth
                implicitHeight: Tokens.space1
            }
            Label {
                Layout.preferredWidth: root.specimenWidth
                text: I18n.t("material.study.current")
                font: Tokens.label
                color: Tokens.textSecondary
            }
            Label {
                Layout.preferredWidth: root.specimenWidth
                text: I18n.t("material.study.fusion")
                font: Tokens.label
                color: Tokens.textPrimary
            }

            TierLabel {
                tierId: "mica"
            }
            RevealSurface {
                order: 0
                revision: root.revealRevision
                captureRevision: root.captureRevision
                backdropSource: backdrop
                Layout.preferredWidth: root.specimenWidth
                Layout.preferredHeight: Tokens.materialPanelHeight
                PanelSample {
                    anchors.fill: parent
                }
            }
            RevealSurface {
                objectName: "materialMica"
                fusion: true
                material: "mica"
                order: 0
                revision: root.revealRevision
                captureRevision: root.captureRevision
                backdropSource: backdrop
                Layout.preferredWidth: root.specimenWidth
                Layout.preferredHeight: Tokens.materialPanelHeight
                PanelSample {
                    anchors.fill: parent
                    fusion: true
                }
            }

            TierLabel {
                tierId: "acrylic"
            }
            RevealSurface {
                order: 1
                revision: root.revealRevision
                captureRevision: root.captureRevision
                backdropSource: backdrop
                padding: Tokens.space8
                Layout.preferredWidth: Tokens.materialFlyoutWidth
                Layout.preferredHeight: Tokens.materialFlyoutHeight
                MenuSample {
                    anchors.fill: parent
                }
            }
            RevealSurface {
                objectName: "materialAcrylic"
                fusion: true
                material: "acrylic"
                order: 1
                cornerRadius: Tokens.radiusL
                revision: root.revealRevision
                captureRevision: root.captureRevision
                backdropSource: backdrop
                padding: Tokens.space8
                Layout.preferredWidth: Tokens.materialFlyoutWidth
                Layout.preferredHeight: Tokens.materialFlyoutHeight
                MenuSample {
                    anchors.fill: parent
                    fusion: true
                }
            }

            TierLabel {
                tierId: "glass"
            }
            RevealSurface {
                order: 2
                pressable: true
                revision: root.revealRevision
                captureRevision: root.captureRevision
                backdropSource: backdrop
                padding: (Tokens.materialDockHeight - Tokens.dockItem) / 2
                Layout.preferredWidth: dockCurrent.implicitWidth + padding * 2
                Layout.preferredHeight: Tokens.materialDockHeight
                Accessible.role: Accessible.Button
                Accessible.name: I18n.t("material.tier.glass.hint")
                DockSample {
                    id: dockCurrent
                    anchors.centerIn: parent
                }
            }
            RevealSurface {
                objectName: "materialGlass"
                fusion: true
                material: "glass"
                order: 2
                pressable: true
                cornerRadius: height / 2
                revision: root.revealRevision
                captureRevision: root.captureRevision
                backdropSource: backdrop
                padding: (Tokens.materialDockHeight - Tokens.dockItem) / 2
                Layout.preferredWidth: dockFusion.implicitWidth + padding * 2 + Tokens.space16
                Layout.preferredHeight: Tokens.materialDockHeight
                Accessible.role: Accessible.Button
                Accessible.name: I18n.t("material.tier.glass.hint")
                DockSample {
                    id: dockFusion
                    anchors.centerIn: parent
                    fusion: true
                }
            }

            TierLabel {
                tierId: "motion"
            }
            RevealSurface {
                order: 3
                revision: root.revealRevision
                captureRevision: root.captureRevision
                backdropSource: backdrop
                Layout.preferredWidth: root.specimenWidth
                Layout.preferredHeight: Tokens.materialMotionHeight
                RowLayout {
                    anchors.fill: parent
                    spacing: Tokens.space16
                    ActionButton {
                        text: I18n.t("material.sample.button")
                        emphasized: true
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Switch {
                        text: I18n.t("material.sample.switch")
                        font: Tokens.label
                        checked: true
                    }
                }
            }
            RevealSurface {
                objectName: "materialMotion"
                fusion: true
                material: "mica"
                order: 3
                revision: root.revealRevision
                captureRevision: root.captureRevision
                backdropSource: backdrop
                Layout.preferredWidth: root.specimenWidth
                Layout.preferredHeight: Tokens.materialMotionHeight
                RowLayout {
                    anchors.fill: parent
                    spacing: Tokens.space16
                    ExpressiveButton {
                        objectName: "materialExpressiveButton"
                        text: I18n.t("material.sample.button")
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Label {
                        text: I18n.t("material.sample.switch")
                        font: Tokens.label
                        color: Tokens.textPrimary
                    }
                    ExpressiveSwitch {
                        objectName: "materialExpressiveSwitch"
                        checked: true
                        Accessible.name: I18n.t("material.sample.switch")
                    }
                }
            }
        }
        Item {
            Layout.fillHeight: true
        }
    }
}

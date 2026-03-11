pragma ComponentBehavior: Bound

import qs.components
import qs.components.containers
import qs.services
import qs.config
import qs.modules.bar.popouts as BarPopouts
import qs.modules.session as Session
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects

PanelWindow {
    id: root

    required property ShellScreen screen

    readonly property int dockHeight: Config.bar.sizes.innerWidth + padding * 2
    readonly property int padding: Math.max(Appearance.padding.smaller, Config.border.thickness)
    readonly property int hotZone: Config.border.thickness
    readonly property int gap: Appearance.padding.large
    readonly property int dockWidth: Math.round(screen.width * 0.75)

    property bool dockVisible: false

    WlrLayershell.namespace: "caelestia-dock"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: dockVisibilities.session && Config.session.enabled
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    // Always fullscreen — never resize, eliminates jerk entirely
    anchors.top:    true
    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true

    screen: root.screen
    color: "transparent"

    mask: Region {
        item: dockVisibilities.session && Config.session.enabled
            ? sessionMaskRect
            : (dockPopouts.hasCurrent || dockPopouts.implicitWidth > 0
                ? trayDockMaskRect
                : dockMaskRect)
    }

    Item {
        id: dockMaskRect
        x: dockContainer.x
        y: 0
        width: dockVisible ? dockContainer.width : root.width
        height: dockVisible ? dockContainer.height + root.gap : root.hotZone
    }

    // Covers both dock strip and tray popout area
    Item {
        id: trayDockMaskRect
        x: Math.min(dockContainer.x, trayPopoutContainer.x)
        y: 0
        width: Math.max(dockContainer.x + dockContainer.width, trayPopoutContainer.x + trayPopoutContainer.width) - x
        height: trayPopoutContainer.y + trayPopoutContainer.height
    }

    Item {
        id: sessionMaskRect
        x: 0
        y: 0
        width: root.width
        height: root.height
    }

    // Delays hiding the bar by 1.5s after hover leaves
    Timer {
        id: hideTimer
        interval: 1500
        repeat: false
        onTriggered: root.dockVisible = false
    }

    // Flash bar on workspace switch
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const n = event.name;
            if (n === "workspace" || n === "activespecial" || n === "focusedmon") {
                root.dockVisible = true;
                hideTimer.restart();
            }
        }
    }

    // Close tray popout 300ms after both tray row and popout lose hover
    readonly property bool trayZoneHovered: dockContent.trayHovered || popoutHover.hovered
    onTrayZoneHoveredChanged: {
        if (!trayZoneHovered)
            trayCloseTimer.restart()
        else
            trayCloseTimer.stop()
    }

    Timer {
        id: trayCloseTimer
        interval: 300
        repeat: false
        onTriggered: dockPopouts.hasCurrent = false
    }

    // Full-window dismiss layer — any click outside popup closes session
    MouseArea {
        anchors.fill: parent
        enabled: dockVisibilities.session && Config.session.enabled
        visible: enabled
        z: 0
        onClicked: dockVisibilities.session = false
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered) {
                hideTimer.stop()
                root.dockVisible = true
            } else {
                hideTimer.restart()
            }
        }
    }

    // Dock bar pill — slides down from above + fades in
    Item {
        id: dockContainer
        z: 1

        anchors.top:              parent.top
        anchors.topMargin:        root.gap
        anchors.horizontalCenter: parent.horizontalCenter

        width:  root.dockWidth
        height: root.dockHeight

        readonly property bool shown: root.dockVisible || dockVisibilities.session
        property real slideY: shown ? 0 : -(root.dockHeight + root.gap)

        opacity: shown ? 1 : 0
        Behavior on opacity {
            Anim {}
        }

        transform: Translate { y: dockContainer.slideY }
        Behavior on slideY {
            Anim {}
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax:       20
            shadowColor:   Qt.alpha(Colours.palette.m3shadow, 0.7)
        }

        StyledRect {
            anchors.fill: parent
            color:  Colours.palette.m3surface
            radius: Appearance.rounding.full
        }

        DockBar {
            id: dockContent

            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.top:    parent.top
            anchors.bottom: parent.bottom

            screen:       root.screen
            visibilities: dockVisibilities
            popouts:      dockPopouts
        }
    }

    // Session popup — slides down from behind the dock + fades in
    Item {
        id: sessionPopup
        z: 2

        readonly property real rightEdge: (root.width + root.dockWidth) / 2
        readonly property real popupW: sessionLoader.active ? sessionLoader.item.implicitWidth + Appearance.padding.large * 2 : 0
        readonly property real popupH: sessionLoader.active ? sessionLoader.item.implicitHeight + Appearance.padding.large * 2 : 0

        x: Math.min(rightEdge - popupW, root.width - popupW - root.gap)
        y: dockContainer.y + dockContainer.height + root.gap / 2

        width:  popupW
        height: popupH

        visible: Config.session.enabled

        property real slideY: dockVisibilities.session ? 0 : -(root.dockHeight + root.gap)

        opacity: dockVisibilities.session ? 1 : 0
        Behavior on opacity {
            Anim {}
        }

        transform: Translate { y: sessionPopup.slideY }
        Behavior on slideY {
            Anim {}
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax:       20
            shadowColor:   Qt.alpha(Colours.palette.m3shadow, 0.7)
        }

        StyledRect {
            anchors.fill: parent
            color:  Colours.palette.m3surface
            radius: Appearance.rounding.large
        }

        Loader {
            id: sessionLoader
            anchors.centerIn: parent

            active: dockVisibilities.session || sessionPopup.opacity > 0

            sourceComponent: Session.Content {
                visibilities: dockVisibilities
            }
        }
    }

    PersistentProperties {
        id: dockVisibilities
        property bool bar
        property bool osd
        property bool session
        property bool launcher
        property bool dashboard
        property bool utilities
        property bool sidebar
    }

    // Tray popout — slides down from behind the dock + fades in, same animation as bar
    Item {
        id: trayPopoutContainer
        z: 3

        x: Math.max(root.gap, Math.min(
            dockPopouts.currentCenter - dockPopouts.implicitWidth / 2,
            root.width - dockPopouts.implicitWidth - root.gap
        ))
        y: dockContainer.y + dockContainer.height + root.gap / 2

        width:  dockPopouts.implicitWidth
        height: dockPopouts.implicitHeight

        property real slideY: dockPopouts.hasCurrent ? 0 : -(root.dockHeight + root.gap)

        opacity: dockPopouts.hasCurrent ? 1 : 0
        Behavior on opacity { Anim {} }

        transform: Translate { y: trayPopoutContainer.slideY }
        Behavior on slideY { Anim {} }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax:       20
            shadowColor:   Qt.alpha(Colours.palette.m3shadow, 0.7)
        }

        StyledRect {
            anchors.fill: parent
            color:  Colours.palette.m3surface
            radius: Appearance.rounding.large
        }

        HoverHandler {
            id: popoutHover
        }

        BarPopouts.Wrapper {
            id: dockPopouts
            screen: root.screen
            anchors.fill: parent
        }
    }
}

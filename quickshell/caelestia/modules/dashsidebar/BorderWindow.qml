pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

// Minimal full-screen border ring window — identical to Border.qml inside
// Drawers, but as a standalone PanelWindow for sidebar-only mode.
// No bar → anchors.leftMargin on the mask rect = Config.border.thickness.
PanelWindow {
    id: root

    required property ShellScreen screen

    WlrLayershell.namespace:     "caelestia-border"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors.top:    true
    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true

    screen: root.screen
    color:  "transparent"

    // Pass all input through — the DashSidebarWindow handles its own mask
    mask: Region {}

    StyledRect {
        anchors.fill: parent
        color: Colours.palette.m3surface

        layer.enabled: true
        layer.effect: MultiEffect {
            maskSource:       borderMask
            maskEnabled:      true
            maskInverted:     true
            maskThresholdMin: 0.5
            maskSpreadAtMin:  1
        }
    }

    Item {
        id: borderMask
        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill:       parent
            anchors.margins:    Config.border.thickness
            anchors.leftMargin: Config.border.thickness
            radius:             Config.border.rounding
        }
    }
}

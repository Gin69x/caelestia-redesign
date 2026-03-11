pragma ComponentBehavior: Bound

import qs.components
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects

// ─────────────────────────────────────────────────────────────────────────────
// DashSidebarWindow — panel background + content only.
// The border ring is NOT rendered here — in normal mode Drawers.qml owns it,
// in sidebar-only mode shell.qml instantiates a separate border window.
//
// Panel background ShapePath (left-anchored, mirrors how Backgrounds.qml works):
//   Coordinate space: inset by Config.border.thickness on all sides,
//   leftMargin = Config.border.thickness (no bar).
//   (0,0) = top-left corner of border's inner rect.
//
//   Start (0, br)
//   ➊ CW arc (+br, -br) → top-left  CONCAVE — connects to border top-left corner
//   top edge → square top-right corner
//   right edge → square bottom-right corner
//   bottom edge →
//   ➍ CW arc (-br, -br) → bot-left  CONCAVE — connects to border bot-left corner
//   left edge back to start
// ─────────────────────────────────────────────────────────────────────────────
PanelWindow {
    id: root

    required property ShellScreen screen

    readonly property int contentWidth: 440
    readonly property int hotZoneWidth: Config.border.thickness

    property bool sidebarVisible: false
    property real panelWidth: 0

    Behavior on panelWidth {
        enabled: root.sidebarVisible
        NumberAnimation {
            duration:           Appearance.anim.durations.expressiveDefaultSpatial
            easing.type:        Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }
    Behavior on panelWidth {
        enabled: !root.sidebarVisible
        NumberAnimation {
            duration:           Appearance.anim.durations.expressiveDefaultSpatial
            easing.type:        Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }

    onSidebarVisibleChanged: panelWidth = sidebarVisible ? contentWidth : 0

    WlrLayershell.namespace:     "caelestia-dashsidebar"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors.top:    true
    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true

    screen: root.screen
    color:  "transparent"

    mask: Region {
        x:      0
        y:      0
        width:  root.sidebarVisible
                    ? root.panelWidth + Config.border.thickness
                    : root.hotZoneWidth
        height: root.screen.height
    }

    HoverHandler {
        onHoveredChanged: root.sidebarVisible = hovered
    }

    // Panel background shape + drop shadow — no border here
    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax:       15
            shadowColor:   Qt.alpha(Colours.palette.m3shadow, 0.7)
        }

        Shape {
            id: bgShape

            // Same coordinate space as Backgrounds.qml:
            // inset by border.thickness, leftMargin = border.thickness (no bar)
            anchors.fill:       parent
            anchors.margins:    Config.border.thickness
            anchors.leftMargin: Config.border.thickness
            preferredRendererType: Shape.CurveRenderer

            readonly property real br: Config.border.rounding

            ShapePath {
                fillColor:   Colours.palette.m3surface
                strokeWidth: -1

                startX: 0
                startY: bgShape.br

                // ➊ Top-left CONCAVE
                PathArc {
                    relativeX: bgShape.br; relativeY: -bgShape.br
                    radiusX:   bgShape.br; radiusY:    bgShape.br
                }
                // Top edge
                PathLine {
                    relativeX: Math.max(0, root.panelWidth - bgShape.br)
                    relativeY: 0
                }
                // Right edge (square top-right)
                PathLine {
                    relativeX: 0
                    relativeY: bgShape.height
                }
                // Bottom edge (square bottom-right)
                PathLine {
                    relativeX: -Math.max(0, root.panelWidth - bgShape.br)
                    relativeY: 0
                }
                // ➍ Bottom-left CONCAVE
                PathArc {
                    relativeX: -bgShape.br; relativeY: -bgShape.br
                    radiusX:    bgShape.br; radiusY:    bgShape.br
                }
                // Left edge back to start
                PathLine {
                    relativeX: 0
                    relativeY: -(bgShape.height - bgShape.br * 2)
                }

                Behavior on fillColor { CAnim {} }
            }
        }
    }

    // Content
    Flickable {
        id: sidebarFlick

        x:      Config.border.thickness
        y:      Config.border.thickness
        width:  root.panelWidth - Config.border.thickness
        height: root.height - Config.border.thickness * 2

        contentWidth:  width
        contentHeight: sidebarContent.implicitHeight
        clip:          true
        flickableDirection:    Flickable.VerticalFlick
        maximumFlickVelocity:  3000

        opacity: root.sidebarVisible ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration:           Appearance.anim.durations.expressiveEffects
                easing.type:        Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.expressiveEffects
            }
        }

        DashSidebar {
            id: sidebarContent
            width: sidebarFlick.width
        }
    }
}

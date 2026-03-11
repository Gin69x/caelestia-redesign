pragma ComponentBehavior: Bound

import qs.components
import qs.config
import qs.modules.bar.popouts as BarPopouts
import "../dashsidebar"
import Quickshell
import QtQuick
import QtQuick.Controls

// Drop-in replacement for BarWrapper that expands to sidebar width when hovered,
// showing DashSidebar as content. The bar items are hidden.
// Because this item IS the bar passed to Border and Backgrounds,
// bar.implicitWidth drives the left-margin of the border mask and all panel
// backgrounds — so the sidebar connects to the border exactly like the bar does.
Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property BarPopouts.Wrapper popouts

    // Keep these so Drawers/Interactions don't break
    readonly property int padding:        Math.max(Appearance.padding.smaller, Config.border.thickness)
    readonly property int barContentWidth: Config.bar.sizes.innerWidth + padding * 2
    readonly property int sidebarContentWidth: 440 + padding * 2
    readonly property int exclusiveZone:  visibilities.bar ? barContentWidth : Config.border.thickness
    readonly property bool shouldBeVisible: sidebarVisible || visibilities.bar || isHovered
    property bool isHovered
    property bool sidebarVisible: false

    // Stubs so Interactions/BarWrapper callers don't error
    function closeTray(): void {}
    function checkPopout(y: real): void {}
    function handleWheel(y: real, angleDelta: point): void {}

    visible: width > Config.border.thickness

    // Start at border.thickness (collapsed), just like BarWrapper
    implicitWidth: Config.border.thickness

    states: State {
        name: "sidebar"
        when: root.sidebarVisible

        PropertyChanges {
            root.implicitWidth: root.sidebarContentWidth
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "sidebar"
            Anim {
                target: root
                property: "implicitWidth"
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        },
        Transition {
            from: "sidebar"
            to: ""
            Anim {
                target: root
                property: "implicitWidth"
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }
    ]

    // Hover zone — thin strip at collapsed width triggers open
    HoverHandler {
        onHoveredChanged: root.sidebarVisible = hovered
    }

    // Sidebar content — anchored the same way Bar is in BarWrapper
    Loader {
        id: content

        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        anchors.right:  parent.right

        active: root.sidebarVisible || root.visible

        sourceComponent: Item {
            width: root.sidebarContentWidth

            opacity: root.sidebarVisible ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration:           Appearance.anim.durations.expressiveEffects
                    easing.type:        Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveEffects
                }
            }

            Flickable {
                anchors.fill: parent
                anchors.margins: root.padding

                contentWidth:  width
                contentHeight: sidebarContent.implicitHeight
                clip:          true
                flickableDirection:    Flickable.VerticalFlick
                maximumFlickVelocity:  3000

                DashSidebar {
                    id: sidebarContent
                    width: parent.width
                }
            }
        }
    }
}

pragma ComponentBehavior: Bound

import qs.components
import qs.config
import "popouts" as BarPopouts
import "../dashsidebar"
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property BarPopouts.Wrapper popouts

    readonly property int padding: Math.max(Appearance.padding.smaller, Config.border.thickness)
    readonly property int contentWidth: 440 + padding * 2
    readonly property int exclusiveZone: Config.border.thickness
    readonly property bool shouldBeVisible: isHovered
    property bool isHovered

    function closeTray(): void {}
    function checkPopout(y: real): void {}
    function handleWheel(y: real, angleDelta: point): void {}

    visible: width > Config.border.thickness
    implicitWidth: Config.border.thickness

    states: State {
        name: "visible"
        when: root.shouldBeVisible

        PropertyChanges {
            root.implicitWidth: root.contentWidth
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "implicitWidth"
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitWidth"
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }
    ]

    Loader {
        id: content

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: root.contentWidth

        active: root.shouldBeVisible || root.visible

        opacity: root.shouldBeVisible ? 1 : 0
        Behavior on opacity {
            Anim {
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }

        sourceComponent: Flickable {
            width: root.contentWidth
            contentWidth: width
            contentHeight: sidebarContent.implicitHeight
            clip: true
            flickableDirection: Flickable.VerticalFlick
            maximumFlickVelocity: 3000

            anchors.fill: parent
            anchors.topMargin: Config.border.thickness
            anchors.bottomMargin: Config.border.thickness
            anchors.leftMargin: Config.border.thickness
            anchors.rightMargin: Config.border.thickness

            DashSidebar {
                id: sidebarContent
                width: parent.width
            }
        }
    }
}

pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property int activeTab: 0

    readonly property int colCpu: 72
    readonly property int colMem: 96

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.normal

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            TabButton {
                label: qsTr("Processes")
                icon: "memory_alt"
                active: root.activeTab === 0
                onClicked: root.activeTab = 0
            }

            TabButton {
                label: qsTr("Services")
                icon: "manufacturing"
                active: root.activeTab === 1
                onClicked: root.activeTab = 1
            }

            Item { Layout.fillWidth: true }

            StyledText {
                text: qsTr("Updates every 2s")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ProcessesTab {
                anchors.fill: parent
                visible: root.activeTab === 0
                active: root.activeTab === 0
                colCpu: root.colCpu
                colMem: root.colMem
            }

            ServicesTab {
                anchors.fill: parent
                visible: root.activeTab === 1
                active: root.activeTab === 1
            }
        }
    }

    component TabButton: StyledRect {
        id: tabBtn

        required property string label
        required property string icon
        required property bool active
        signal clicked()

        implicitHeight: tabInner.implicitHeight + Appearance.padding.normal * 2
        implicitWidth:  tabInner.implicitWidth  + Appearance.padding.large  * 2

        radius: active ? Appearance.rounding.small
                       : Math.min(width, height) / 2 * Math.min(1, Appearance.rounding.scale)
        color: active ? Colours.palette.m3secondaryContainer : "transparent"

        StateLayer {
            color: active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
            function onClicked(): void { tabBtn.clicked(); }
        }

        RowLayout {
            id: tabInner
            anchors.centerIn: parent
            spacing: Appearance.spacing.normal

            MaterialIcon {
                text: tabBtn.icon
                fill: tabBtn.active ? 1 : 0
                color: tabBtn.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.larger
                Behavior on fill { Anim {} }
            }

            StyledText {
                text: tabBtn.label
                font.weight: tabBtn.active ? 500 : 400
                color: tabBtn.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
            }
        }

        Behavior on radius { Anim { duration: Appearance.anim.durations.expressiveFastSpatial; easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial } }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}

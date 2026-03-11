pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.services
import qs.utils
import qs.config
import qs.modules.bar.popouts as BarPopouts
import qs.modules.bar.components as BarComponents
import qs.modules.bar.components.workspaces as BarWorkspaces
import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property BarPopouts.Wrapper popouts

    readonly property int hPadding: Appearance.padding.large * 2

    // True when mouse is over any tray icon
    readonly property bool trayHovered: trayRowHover.hovered

    // Left: OS icon + workspaces
    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: root.hPadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.normal

        BarComponents.OsIcon {
            Layout.alignment: Qt.AlignVCenter
        }

        BarWorkspaces.Workspaces {
            Layout.alignment: Qt.AlignVCenter
            screen: root.screen
        }
    }

    // Center: active window icon + title
    RowLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.small

        MaterialIcon {
            Layout.alignment: Qt.AlignVCenter
            animate: true
            text: Icons.getAppCategoryIcon(Hypr.activeToplevel?.lastIpcObject.class, "desktop_windows")
            color: Colours.palette.m3primary
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: Hypr.activeToplevel?.title ?? qsTr("Desktop")
            font.pointSize: Appearance.font.size.smaller
            font.family: Appearance.font.family.mono
            color: Colours.palette.m3primary
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }

    // Right: tray, clock, power
    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: root.hPadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.normal

        // Inline horizontal tray with hover-to-popout
        Row {
            id: trayRow
            Layout.alignment: Qt.AlignVCenter
            spacing: Appearance.spacing.small

            // Single HoverHandler on the whole row — no onExited per-item needed
            HoverHandler {
                id: trayRowHover
            }

            Repeater {
                id: trayItems
                model: SystemTray.items

                Item {
                    id: trayItemWrapper
                    required property SystemTrayItem modelData
                    required property int index

                    implicitWidth:  Appearance.font.size.small * 2
                    implicitHeight: Appearance.font.size.small * 2

                    ColouredIcon {
                        anchors.fill: parent
                        source: Icons.getTrayIcon(trayItemWrapper.modelData.id, trayItemWrapper.modelData.icon)
                        colour: Colours.palette.m3secondary
                        layer.enabled: Config.bar.tray.recolour
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        hoverEnabled: true

                        onClicked: event => {
                            if (event.button === Qt.LeftButton)
                                trayItemWrapper.modelData.activate()
                            else
                                trayItemWrapper.modelData.secondaryActivate()
                        }

                        onEntered: {
                            root.popouts.currentName = `traymenu${trayItemWrapper.index}`
                            root.popouts.currentCenter = trayItemWrapper.mapToItem(null, trayItemWrapper.implicitWidth / 2, 0).x
                            root.popouts.hasCurrent = true
                        }
                    }
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: Time.format(Config.services.useTwelveHourClock ? "hh mm A" : "hh mm")
            font.pointSize: Appearance.font.size.smaller
            font.family: Appearance.font.family.mono
            color: Colours.palette.m3tertiary
        }

        BarComponents.Power {
            Layout.alignment: Qt.AlignVCenter
            visibilities: root.visibilities
        }
    }
}

import qs.components
import qs.services
import qs.config
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + Appearance.padding.large * 2

    radius: Appearance.rounding.normal
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.normal

        StyledText {
            text: UPower.displayDevice.isLaptopBattery
                ? qsTr("Remaining: %1%").arg(Math.round(UPower.displayDevice.percentage * 100))
                : qsTr("No battery detected")
            font.pointSize: Appearance.font.size.normal
        }

        StyledText {
            function formatSeconds(s: int, fallback: string): string {
                const day = Math.floor(s / 86400);
                const hr  = Math.floor(s / 3600) % 60;
                const min = Math.floor(s / 60) % 60;
                let comps = [];
                if (day > 0) comps.push(`${day} days`);
                if (hr  > 0) comps.push(`${hr} hours`);
                if (min > 0) comps.push(`${min} mins`);
                return comps.join(", ") || fallback;
            }

            text: UPower.displayDevice.isLaptopBattery
                ? qsTr("Time %1: %2")
                    .arg(UPower.onBattery ? "remaining" : "until charged")
                    .arg(UPower.onBattery
                        ? formatSeconds(UPower.displayDevice.timeToEmpty, "Calculating...")
                        : formatSeconds(UPower.displayDevice.timeToFull,  "Fully charged!"))
                : qsTr("Power profile: %1").arg(PowerProfile.toString(PowerProfiles.profile))
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.small
        }

        // Degradation warning (only shown when relevant)
        Loader {
            Layout.fillWidth: true

            active: PowerProfiles.degradationReason !== PerformanceDegradationReason.None
            asynchronous: true
            height: active ? (item?.implicitHeight ?? 0) : 0

            sourceComponent: StyledRect {
                implicitWidth: child.implicitWidth + Appearance.padding.normal * 2
                implicitHeight: child.implicitHeight + Appearance.padding.smaller * 2

                color: Colours.palette.m3error
                radius: Appearance.rounding.normal

                Column {
                    id: child

                    anchors.centerIn: parent

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Appearance.spacing.small

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "warning"
                            color: Colours.palette.m3onError
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Performance Degraded")
                            color: Colours.palette.m3onError
                            font.family: Appearance.font.family.mono
                            font.weight: 500
                        }

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "warning"
                            color: Colours.palette.m3onError
                        }
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("Reason: %1").arg(PerformanceDegradationReason.toString(PowerProfiles.degradationReason))
                        color: Colours.palette.m3onError
                    }
                }
            }
        }

        // Profile selector pill
        StyledRect {
            id: profiles

            property string current: {
                const p = PowerProfiles.profile;
                if (p === PowerProfile.PowerSaver)   return saver.icon;
                if (p === PowerProfile.Performance)  return perf.icon;
                return balance.icon;
            }

            Layout.fillWidth: true
            implicitHeight: saver.implicitHeight + Appearance.padding.small * 2

            color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
            radius: Appearance.rounding.full

            // Sliding indicator — x/width driven by which third is active
            StyledRect {
                id: indicator

                readonly property int activeIndex: {
                    const p = PowerProfiles.profile;
                    if (p === PowerProfile.PowerSaver)  return 0;
                    if (p === PowerProfile.Performance) return 2;
                    return 1;
                }

                readonly property real btnWidth: (profiles.width - Appearance.padding.smaller * 4) / 3
                readonly property real offset: Appearance.padding.smaller

                y: Appearance.padding.smaller
                height: profiles.height - Appearance.padding.smaller * 2
                width: btnWidth
                x: offset + activeIndex * (btnWidth + Appearance.padding.smaller)

                color: Colours.palette.m3primary
                radius: Appearance.rounding.full

                Behavior on x {
                    Anim {
                        duration: Appearance.anim.durations.normal
                        easing.bezierCurve: Appearance.anim.curves.emphasized
                    }
                }
            }

            Row {
                anchors.fill: parent
                anchors.margins: Appearance.padding.smaller
                spacing: Appearance.padding.smaller

                Profile {
                    id: saver
                    width: (parent.width - Appearance.padding.smaller * 2) / 3
                    height: parent.height
                    profile: PowerProfile.PowerSaver
                    icon: "energy_savings_leaf"
                }

                Profile {
                    id: balance
                    width: (parent.width - Appearance.padding.smaller * 2) / 3
                    height: parent.height
                    profile: PowerProfile.Balanced
                    icon: "balance"
                }

                Profile {
                    id: perf
                    width: (parent.width - Appearance.padding.smaller * 2) / 3
                    height: parent.height
                    profile: PowerProfile.Performance
                    icon: "rocket_launch"
                }
            }
        }
    }

    component Profile: Item {
        required property string icon
        required property int    profile

        implicitWidth:  iconItem.implicitHeight + Appearance.padding.small * 2
        implicitHeight: iconItem.implicitHeight + Appearance.padding.small * 2

        readonly property bool isActive: PowerProfiles.profile === profile

        StateLayer {
            radius: Appearance.rounding.full
            color: parent.isActive ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

            function onClicked(): void {
                PowerProfiles.profile = parent.profile;
            }
        }

        MaterialIcon {
            id: iconItem

            anchors.centerIn: parent
            text: parent.icon
            font.pointSize: Appearance.font.size.large
            color: parent.isActive ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            fill: parent.isActive ? 1 : 0

            Behavior on fill { Anim {} }
        }
    }
}

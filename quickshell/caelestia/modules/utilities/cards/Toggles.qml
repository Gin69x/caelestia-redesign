import qs.components
import qs.components.controls
import qs.services
import qs.config
import qs.modules.controlcenter
import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property var visibilities
    signal openRecorder()
    signal openWifi()
    signal openBluetooth()

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
            text: qsTr("Quick Toggles")
            font.pointSize: Appearance.font.size.normal
        }

        // Row 1: wifi, bluetooth, mic, settings
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.padding.small
            spacing: Appearance.spacing.small

            Toggle {
                icon: "wifi"
                checked: Network.wifiEnabled
                toggle: false
                inactiveOnColour: Network.wifiEnabled ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                inactiveColour: Network.wifiEnabled ? Colours.palette.m3primary : Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
                onClicked: root.openWifi()
            }
            Toggle {
                icon: "bluetooth"
                checked: Bluetooth.defaultAdapter?.enabled ?? false
                toggle: false
                inactiveOnColour: (Bluetooth.defaultAdapter?.enabled ?? false) ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                inactiveColour: (Bluetooth.defaultAdapter?.enabled ?? false) ? Colours.palette.m3primary : Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
                onClicked: root.openBluetooth()
            }
            Toggle {
                icon: "mic"
                checked: !Audio.sourceMuted
                onClicked: {
                    const audio = Audio.source?.audio;
                    if (audio) audio.muted = !audio.muted;
                }
            }
            Toggle {
                icon: "settings"
                toggle: false
                inactiveOnColour: Colours.palette.m3onSurfaceVariant
                onClicked: {
                    root.visibilities.utilities = false;
                    WindowFactory.create(null, { screen: QsWindow.window?.screen ?? null });
                }
            }
        }

        // Row 2: gamepad, notifications_off, keep awake, screen recorder
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            Toggle { icon: "gamepad";          checked: GameMode.enabled;        onClicked: GameMode.enabled = !GameMode.enabled }
            Toggle { icon: "notifications_off"; checked: Notifs.dnd;              onClicked: Notifs.dnd = !Notifs.dnd }
            Toggle { icon: "coffee";            checked: IdleInhibitor.enabled;   onClicked: IdleInhibitor.enabled = !IdleInhibitor.enabled }
            Toggle {
                icon: "screen_record"
                toggle: false
                inactiveOnColour: Colours.palette.m3onSurfaceVariant
                onClicked: root.openRecorder()
            }
        }
    }

    component Toggle: IconButton {
        Layout.fillWidth: true
        Layout.preferredWidth: 1   // equal weight — all 4 in each row get the same width
        radius: stateLayer.pressed ? Appearance.rounding.small / 2 : internalChecked ? Appearance.rounding.small : Appearance.rounding.normal
        inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
        toggle: true
        radiusAnim.duration: Appearance.anim.durations.expressiveFastSpatial
        radiusAnim.easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
    }
}

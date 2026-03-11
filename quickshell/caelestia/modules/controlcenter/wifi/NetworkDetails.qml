pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.config
import qs.utils
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Session session
    readonly property var network: session.wifi.active

    spacing: Appearance.spacing.normal

    // ── Speed monitor state ───────────────────────────────────────────────────
    property real rxSpeed: 0
    property real txSpeed: 0
    property real lastRxBytes: -1
    property real lastTxBytes: -1

    function formatSpeed(bytesPerSec: real): string {
        if (bytesPerSec >= 1048576)
            return (bytesPerSec / 1048576).toFixed(1) + " MB/s";
        if (bytesPerSec >= 1024)
            return (bytesPerSec / 1024).toFixed(1) + " KB/s";
        return bytesPerSec.toFixed(0) + " B/s";
    }

    Timer {
        interval: 1000
        running: root.network !== null && root.network !== undefined
        repeat: true
        triggeredOnStart: true
        onTriggered: netDevFile.reload()
    }

    FileView {
        id: netDevFile
        path: "/proc/net/dev"
        onLoaded: {
            const lines = text().split("\n");
            for (const line of lines) {
                const parts = line.trim().split(/\s+/);
                if (parts.length < 10) continue;
                const iface = parts[0].replace(":", "");
                if (!iface.startsWith("wl")) continue;

                const rx = parseFloat(parts[1]);
                const tx = parseFloat(parts[9]);

                if (root.lastRxBytes >= 0) {
                    root.rxSpeed = Math.max(0, rx - root.lastRxBytes);
                    root.txSpeed = Math.max(0, tx - root.lastTxBytes);
                }

                root.lastRxBytes = rx;
                root.lastTxBytes = tx;
                break;
            }
        }
    }

    // ── Header ────────────────────────────────────────────────────────────────
    MaterialIcon {
        Layout.alignment: Qt.AlignHCenter
        animate: true
        text: root.network ? Icons.getNetworkIcon(root.network.strength) : "wifi_off"
        font.pointSize: Appearance.font.size.extraLarge * 3
        font.bold: true
        fill: root.network?.active ? 1 : 0

        Behavior on fill { Anim {} }
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        animate: true
        text: root.network?.ssid ?? ""
        font.pointSize: Appearance.font.size.large
        font.bold: true
    }

    // ── Connection status ─────────────────────────────────────────────────────
    StyledText {
        Layout.topMargin: Appearance.spacing.large
        text: qsTr("Connection status")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("Connection settings for this network")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: connStatus.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: connStatus

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.larger

            Toggle {
                label: qsTr("Connected")
                checked: root.network?.active ?? false
                toggle.onToggled: {
                    if (checked)
                        Network.connectToNetwork(root.network.ssid, "");
                    else
                        Network.disconnectFromNetwork();
                }
            }
        }
    }

    // ── Speed monitor ─────────────────────────────────────────────────────────
    StyledText {
        Layout.topMargin: Appearance.spacing.large
        text: qsTr("Speed monitor")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("Real-time throughput for this connection")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: speedCard.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        GridLayout {
            id: speedCard

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large

            columns: 2
            rowSpacing: Appearance.spacing.normal
            columnSpacing: Appearance.spacing.large

            // Download
            RowLayout {
                spacing: Appearance.spacing.normal

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: dlIcon.implicitHeight + Appearance.padding.normal * 2
                    radius: Appearance.rounding.normal
                    color: Colours.palette.m3primaryContainer

                    MaterialIcon {
                        id: dlIcon
                        anchors.centerIn: parent
                        text: "download"
                        color: Colours.palette.m3onPrimaryContainer
                    }
                }

                ColumnLayout {
                    spacing: 0
                    StyledText {
                        text: qsTr("Download")
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3outline
                    }
                    StyledText {
                        text: root.network?.active ? root.formatSpeed(root.rxSpeed) : qsTr("—")
                        font.pointSize: Appearance.font.size.normal
                        font.weight: 500
                    }
                }
            }

            // Upload
            RowLayout {
                spacing: Appearance.spacing.normal

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: ulIcon.implicitHeight + Appearance.padding.normal * 2
                    radius: Appearance.rounding.normal
                    color: Colours.palette.m3secondaryContainer

                    MaterialIcon {
                        id: ulIcon
                        anchors.centerIn: parent
                        text: "upload"
                        color: Colours.palette.m3onSecondaryContainer
                    }
                }

                ColumnLayout {
                    spacing: 0
                    StyledText {
                        text: qsTr("Upload")
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3outline
                    }
                    StyledText {
                        text: root.network?.active ? root.formatSpeed(root.txSpeed) : qsTr("—")
                        font.pointSize: Appearance.font.size.normal
                        font.weight: 500
                    }
                }
            }
        }
    }

    // ── Network properties ────────────────────────────────────────────────────
    StyledText {
        Layout.topMargin: Appearance.spacing.large
        text: qsTr("Network properties")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("Details about this network")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: netProps.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: netProps

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.small / 2

            // Signal strength bar
            StyledText {
                text: qsTr("Signal strength")
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small / 2
                Layout.preferredHeight: Appearance.padding.smaller
                spacing: Appearance.spacing.small / 2

                StyledRect {
                    Layout.fillHeight: true
                    implicitWidth: root.network
                        ? parent.width * (root.network.strength / 100)
                        : 0
                    radius: Appearance.rounding.full
                    color: Colours.palette.m3primary

                    Behavior on implicitWidth { Anim {} }
                }

                StyledRect {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Appearance.rounding.full
                    color: Colours.palette.m3secondaryContainer

                    StyledRect {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: parent.height * 0.25
                        implicitWidth: height
                        radius: Appearance.rounding.full
                        color: Colours.palette.m3primary
                    }
                }
            }

            StyledText {
                text: root.network ? qsTr("%1%").arg(root.network.strength) : qsTr("—")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }

            // BSSID
            StyledText {
                Layout.topMargin: Appearance.spacing.normal
                text: qsTr("BSSID")
            }
            StyledText {
                text: root.network?.bssid ?? qsTr("—")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }

            // Frequency
            StyledText {
                Layout.topMargin: Appearance.spacing.normal
                text: qsTr("Frequency")
            }
            StyledText {
                text: {
                    const freq = root.network?.frequency ?? 0;
                    if (freq === 0) return qsTr("—");
                    const band = freq >= 5000 ? qsTr("5 GHz") : qsTr("2.4 GHz");
                    return qsTr("%1 MHz (%2)").arg(freq).arg(band);
                }
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }

            // Security
            StyledText {
                Layout.topMargin: Appearance.spacing.normal
                text: qsTr("Security")
            }
            StyledText {
                text: root.network
                    ? (root.network.security.length > 0 ? root.network.security : qsTr("Open / None"))
                    : qsTr("—")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }
        }
    }

    // ── Danger zone ───────────────────────────────────────────────────────────
    StyledText {
        Layout.topMargin: Appearance.spacing.large
        text: qsTr("Actions")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("Manage this network connection")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: actionsCol.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: actionsCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.normal

            // Forget network button
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: forgetRow.implicitHeight + Appearance.padding.normal * 2

                radius: Appearance.rounding.normal
                color: Qt.alpha(Colours.palette.m3error, 0.12)

                StateLayer {
                    color: Colours.palette.m3error
                    disabled: !root.network

                    function onClicked(): void {
                        Network.forgetNetwork(root.network.ssid);
                        root.session.wifi.active = null;
                    }
                }

                RowLayout {
                    id: forgetRow

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.normal
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        text: "delete_forever"
                        color: Colours.palette.m3error
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Forget network")
                        color: Colours.palette.m3error
                        font.weight: 500
                    }
                }
            }

            // Disconnect button (only show when connected)
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: disconnectRow.implicitHeight + Appearance.padding.normal * 2
                visible: root.network?.active ?? false

                radius: Appearance.rounding.normal
                color: Colours.palette.m3secondaryContainer

                StateLayer {
                    color: Colours.palette.m3onSecondaryContainer
                    disabled: !(root.network?.active ?? false)

                    function onClicked(): void {
                        Network.disconnectFromNetwork();
                    }
                }

                RowLayout {
                    id: disconnectRow

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.normal
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        text: "wifi_off"
                        color: Colours.palette.m3onSecondaryContainer
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Disconnect")
                        color: Colours.palette.m3onSecondaryContainer
                        font.weight: 500
                    }
                }
            }
        }
    }

    // ── Toggle component ──────────────────────────────────────────────────────
    component Toggle: RowLayout {
        required property string label
        property alias checked: toggle.checked
        property alias toggle: toggle

        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: parent.label
        }

        StyledSwitch {
            id: toggle
            cLayer: 2
        }
    }
}

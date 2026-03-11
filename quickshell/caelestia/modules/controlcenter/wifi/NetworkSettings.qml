pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Session session

    spacing: Appearance.spacing.normal

    // ── Speed monitor state ───────────────────────────────────────────────────
    property real rxSpeed: 0
    property real txSpeed: 0
    property real lastRxBytes: -1
    property real lastTxBytes: -1
    property string wifiInterface: ""

    // ── Password reveal state ─────────────────────────────────────────────────
    property string savedPassword: ""
    property bool passwordRevealed: false

    function formatSpeed(bytesPerSec: real): string {
        if (bytesPerSec >= 1048576)
            return (bytesPerSec / 1048576).toFixed(1) + " MB/s";
        if (bytesPerSec >= 1024)
            return (bytesPerSec / 1024).toFixed(1) + " KB/s";
        return bytesPerSec.toFixed(0) + " B/s";
    }

    Timer {
        interval: 1000
        running: true
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
                if (parts.length < 10)
                    continue;
                const iface = parts[0].replace(":", "");
                if (!iface.startsWith("wl"))
                    continue;

                if (root.wifiInterface === "")
                    root.wifiInterface = iface;

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

    // Fetch saved password whenever active network changes
    Process {
        id: passwordProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.savedPassword = text.trim();
                root.passwordRevealed = false;
            }
        }
    }

    Connections {
        target: Network
        function onActiveChanged(): void {
            root.savedPassword = "";
            root.passwordRevealed = false;
            if (Network.active) {
                passwordProc.exec([
                    "nmcli", "-s", "-g",
                    "802-11-wireless-security.psk",
                    "connection", "show", Network.active.ssid
                ]);
            }
        }
    }

    // Also fetch on first load if already connected
    Component.onCompleted: {
        if (Network.active) {
            passwordProc.exec([
                "nmcli", "-s", "-g",
                "802-11-wireless-security.psk",
                "connection", "show", Network.active.ssid
            ]);
        }
    }

    // ── Header ────────────────────────────────────────────────────────────────
    MaterialIcon {
        Layout.alignment: Qt.AlignHCenter
        text: Network.wifiEnabled ? "wifi" : "wifi_off"
        font.pointSize: Appearance.font.size.extraLarge * 3
        font.bold: true
        animate: true
        fill: Network.wifiEnabled ? 1 : 0

        Behavior on fill { Anim {} }
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: qsTr("Wi-Fi settings")
        font.pointSize: Appearance.font.size.large
        font.bold: true
    }

    // ── Wi-Fi status ──────────────────────────────────────────────────────────
    StyledText {
        Layout.topMargin: Appearance.spacing.large
        text: qsTr("Wi-Fi status")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("General Wi-Fi settings")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: wifiStatus.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: wifiStatus

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.larger

            Toggle {
                label: qsTr("Enabled")
                checked: Network.wifiEnabled
                toggle.onToggled: Network.enableWifi(checked)
            }
        }
    }

    // ── Live speed monitor ────────────────────────────────────────────────────
    StyledText {
        Layout.topMargin: Appearance.spacing.large
        text: qsTr("Speed monitor")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("Real-time network throughput")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: speedGrid.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        GridLayout {
            id: speedGrid

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
                        text: Network.wifiEnabled ? root.formatSpeed(root.rxSpeed) : qsTr("—")
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
                        text: Network.wifiEnabled ? root.formatSpeed(root.txSpeed) : qsTr("—")
                        font.pointSize: Appearance.font.size.normal
                        font.weight: 500
                    }
                }
            }

            // Interface
            RowLayout {
                Layout.columnSpan: 2
                Layout.topMargin: Appearance.spacing.small
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    text: "router"
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.normal
                }

                StyledText {
                    text: root.wifiInterface.length > 0
                        ? qsTr("Interface: %1").arg(root.wifiInterface)
                        : qsTr("Interface: not detected")
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.small
                }
            }
        }
    }

    // ── Connection information ────────────────────────────────────────────────
    StyledText {
        Layout.topMargin: Appearance.spacing.large
        text: qsTr("Connection information")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("Details about the current connection")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: connInfo.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: connInfo

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.small / 2

            // Active network
            StyledText {
                text: qsTr("Active network")
            }
            StyledText {
                text: Network.active?.ssid ?? qsTr("Not connected")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }

            // Password row (below network name)
            StyledText {
                Layout.topMargin: Appearance.spacing.normal
                text: qsTr("Password")
                visible: Network.active !== null && Network.active !== undefined
            }

            RowLayout {
                Layout.fillWidth: true
                visible: Network.active !== null && Network.active !== undefined
                spacing: Appearance.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        if (root.savedPassword.length === 0)
                            return qsTr("Not stored / unavailable");
                        return root.passwordRevealed
                            ? root.savedPassword
                            : "•".repeat(Math.min(root.savedPassword.length, 16));
                    }
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.small
                    elide: Text.ElideRight
                }

                // Reveal / hide toggle button
                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: revealIcon.implicitHeight + Appearance.padding.smaller * 2

                    radius: Appearance.rounding.full
                    color: root.passwordRevealed
                        ? Colours.palette.m3primaryContainer
                        : Qt.alpha(Colours.palette.m3onSurface, 0.08)
                    visible: root.savedPassword.length > 0

                    StateLayer {
                        color: root.passwordRevealed
                            ? Colours.palette.m3onPrimaryContainer
                            : Colours.palette.m3onSurface
                        function onClicked(): void {
                            root.passwordRevealed = !root.passwordRevealed;
                        }
                    }

                    MaterialIcon {
                        id: revealIcon
                        anchors.centerIn: parent
                        animate: true
                        text: root.passwordRevealed ? "visibility_off" : "visibility"
                        color: root.passwordRevealed
                            ? Colours.palette.m3onPrimaryContainer
                            : Colours.palette.m3onSurface
                        font.pointSize: Appearance.font.size.normal
                    }
                }
            }

            // Frequency band
            StyledText {
                Layout.topMargin: Appearance.spacing.normal
                text: qsTr("Frequency band")
            }
            StyledText {
                text: {
                    const freq = Network.active?.frequency ?? 0;
                    if (freq === 0) return qsTr("Unknown");
                    return freq >= 5000 ? qsTr("5 GHz") : qsTr("2.4 GHz");
                }
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }

            // Signal strength
            StyledText {
                Layout.topMargin: Appearance.spacing.normal
                text: qsTr("Signal strength")
            }
            Item {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small / 2
                implicitHeight: Appearance.padding.smaller

                // Track background
                StyledRect {
                    anchors.fill: parent
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

                // Fill bar — width Math.min-clamped so it never overflows
                StyledRect {
                    width: Math.min(parent.width,
                               Math.max(0, parent.width * ((Network.active?.strength ?? 0) / 100)))
                    height: parent.height
                    radius: Appearance.rounding.full
                    color: Colours.palette.m3primary
                    Behavior on width { Anim {} }
                }
            }
            StyledText {
                text: Network.active ? qsTr("%1%").arg(Network.active.strength) : qsTr("—")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }

            // Security
            StyledText {
                Layout.topMargin: Appearance.spacing.normal
                text: qsTr("Security")
            }
            StyledText {
                text: Network.active
                    ? (Network.active.security.length > 0 ? Network.active.security : qsTr("Open"))
                    : qsTr("—")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }

            // BSSID
            StyledText {
                Layout.topMargin: Appearance.spacing.normal
                text: qsTr("BSSID")
            }
            StyledText {
                text: Network.active?.bssid ?? qsTr("—")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }
        }
    }

    // ── Actions ───────────────────────────────────────────────────────────────
    StyledText {
        Layout.topMargin: Appearance.spacing.large
        text: qsTr("Actions")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
        visible: Network.active !== null && Network.active !== undefined
    }

    StyledText {
        text: qsTr("Manage the active connection")
        color: Colours.palette.m3outline
        visible: Network.active !== null && Network.active !== undefined
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: actionsCol.implicitHeight + Appearance.padding.large * 2
        visible: Network.active !== null && Network.active !== undefined

        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: actionsCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.normal

            // Disconnect
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: disconnectRow.implicitHeight + Appearance.padding.normal * 2
                radius: Appearance.rounding.normal
                color: Colours.palette.m3secondaryContainer

                StateLayer {
                    color: Colours.palette.m3onSecondaryContainer
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

            // Forget network
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: forgetRow.implicitHeight + Appearance.padding.normal * 2
                radius: Appearance.rounding.normal
                color: Qt.alpha(Colours.palette.m3error, 0.12)

                StateLayer {
                    color: Colours.palette.m3error
                    function onClicked(): void {
                        Network.forgetNetwork(Network.active.ssid);
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

pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Session session

    spacing: Appearance.spacing.small

    // Password dialog state
    property string passwordTarget: ""
    property bool passwordDialogOpen: false

    // ── Top toolbar ──────────────────────────────────────────────────────────
    RowLayout {
        spacing: Appearance.spacing.smaller

        StyledText {
            text: qsTr("Settings")
            font.pointSize: Appearance.font.size.large
            font.weight: 500
        }

        Item { Layout.fillWidth: true }

        // Power toggle only — settings button removed
        ToggleButton {
            toggled: Network.wifiEnabled
            icon: "power"
            accent: "Tertiary"
            function onClicked(): void {
                Network.toggleWifi();
            }
        }
    }

    // ── Network count + rescan button ────────────────────────────────────────
    RowLayout {
        Layout.topMargin: Appearance.spacing.large
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Networks (%1)").arg(Network.networks.length)
                font.pointSize: Appearance.font.size.large
                font.weight: 500
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("All available Wi-Fi networks")
                color: Colours.palette.m3outline
            }
        }

        // Rescan button
        StyledRect {
            id: rescanBtn

            implicitWidth: implicitHeight
            implicitHeight: scanIcon.implicitHeight + Appearance.padding.normal * 2

            radius: Network.scanning
                ? Appearance.rounding.normal
                : implicitHeight / 2 * Math.min(1, Appearance.rounding.scale)
            color: Network.scanning
                ? Colours.palette.m3secondary
                : Colours.palette.m3secondaryContainer

            StateLayer {
                color: Network.scanning
                    ? Colours.palette.m3onSecondary
                    : Colours.palette.m3onSecondaryContainer
                disabled: !Network.wifiEnabled
                function onClicked(): void {
                    Network.rescanWifi();
                }
            }

            MaterialIcon {
                id: scanIcon

                anchors.centerIn: parent
                animate: true
                text: "wifi_find"
                color: Network.scanning
                    ? Colours.palette.m3onSecondary
                    : Colours.palette.m3onSecondaryContainer
                fill: Network.scanning ? 1 : 0

                Behavior on fill { Anim {} }
            }

            Behavior on radius { Anim {} }
        }
    }

    // ── Network list ─────────────────────────────────────────────────────────
    StyledListView {
        id: view

        model: ScriptModel {
            values: [...Network.networks].sort(
                (a, b) => (b.active - a.active) || (b.strength - a.strength)
            )
        }

        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: Appearance.spacing.small / 2

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: view
        }

        delegate: StyledRect {
            id: networkItem

            required property var modelData
            readonly property bool isConnected: modelData.active
            readonly property bool isConnecting: root.passwordTarget === modelData.ssid && !modelData.active

            anchors.left: parent?.left
            anchors.right: parent?.right
            implicitHeight: networkInner.implicitHeight + Appearance.padding.normal * 2

            color: Qt.alpha(
                Colours.tPalette.m3surfaceContainer,
                root.session.wifi.active === modelData
                    ? Colours.tPalette.m3surfaceContainer.a
                    : 0
            )
            radius: Appearance.rounding.normal

            opacity: 0
            scale: 0.85
            Component.onCompleted: { opacity = 1; scale = 1; }
            Behavior on opacity { Anim {} }
            Behavior on scale { Anim {} }

            StateLayer {
                function onClicked(): void {
                    root.session.wifi.active = networkItem.modelData;
                }
            }

            RowLayout {
                id: networkInner

                anchors.fill: parent
                anchors.margins: Appearance.padding.normal
                spacing: Appearance.spacing.normal

                // Signal strength icon badge
                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: sigIcon.implicitHeight + Appearance.padding.normal * 2

                    radius: Appearance.rounding.normal
                    color: networkItem.isConnected
                        ? Colours.palette.m3primaryContainer
                        : networkItem.modelData.isSecure
                            ? Colours.palette.m3secondaryContainer
                            : Colours.tPalette.m3surfaceContainerHigh

                    MaterialIcon {
                        id: sigIcon

                        anchors.centerIn: parent
                        text: Icons.getNetworkIcon(networkItem.modelData.strength)
                        color: networkItem.isConnected
                            ? Colours.palette.m3onPrimaryContainer
                            : networkItem.modelData.isSecure
                                ? Colours.palette.m3onSecondaryContainer
                                : Colours.palette.m3onSurface
                        font.pointSize: Appearance.font.size.large
                        fill: networkItem.isConnected ? 1 : 0

                        Behavior on fill { Anim {} }
                    }
                }

                // SSID on top, lock + security text on the second line
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        text: networkItem.modelData.ssid
                        elide: Text.ElideRight
                        font.weight: networkItem.isConnected ? 500 : 400
                        color: networkItem.isConnected
                            ? Colours.palette.m3primary
                            : Colours.palette.m3onSurface
                    }

                    // Lock icon sits inline with the security/status text on the second row
                    RowLayout {
                        spacing: Appearance.spacing.small / 2

                        MaterialIcon {
                            visible: networkItem.modelData.isSecure
                            text: "lock"
                            font.pointSize: Appearance.font.size.small
                            color: networkItem.isConnected
                                ? Colours.palette.m3primary
                                : Colours.palette.m3outline
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: networkItem.isConnected
                                ? qsTr("Connected")
                                : networkItem.modelData.security.length > 0
                                    ? networkItem.modelData.security
                                    : qsTr("Open")
                            color: networkItem.isConnected
                                ? Colours.palette.m3primary
                                : Colours.palette.m3outline
                            font.pointSize: Appearance.font.size.small
                            elide: Text.ElideRight
                        }
                    }
                }

                // Connect / disconnect button
                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: connectIcon.implicitHeight + Appearance.padding.smaller * 2

                    radius: Appearance.rounding.full
                    color: Qt.alpha(
                        Colours.palette.m3primaryContainer,
                        networkItem.isConnected ? 1 : 0
                    )

                    CircularIndicator {
                        anchors.fill: parent
                        running: networkItem.isConnecting
                    }

                    StateLayer {
                        color: networkItem.isConnected
                            ? Colours.palette.m3onPrimaryContainer
                            : Colours.palette.m3onSurface
                        disabled: networkItem.isConnecting || !Network.wifiEnabled

                        function onClicked(): void {
                            if (networkItem.isConnected) {
                                Network.disconnectFromNetwork();
                            } else if (networkItem.modelData.isSecure) {
                                root.passwordTarget = networkItem.modelData.ssid;
                                root.passwordDialogOpen = true;
                            } else {
                                root.passwordTarget = networkItem.modelData.ssid;
                                Network.connectToNetwork(networkItem.modelData.ssid, "");
                            }
                        }
                    }

                    MaterialIcon {
                        id: connectIcon

                        anchors.centerIn: parent
                        animate: true
                        text: networkItem.isConnected ? "link_off" : "link"
                        color: networkItem.isConnected
                            ? Colours.palette.m3onPrimaryContainer
                            : Colours.palette.m3onSurface
                        opacity: networkItem.isConnecting ? 0 : 1

                        Behavior on opacity { Anim {} }
                    }
                }
            }
        }
    }

    // ── Password dialog ───────────────────────────────────────────────────────
    StyledRect {
        id: passwordDialog

        Layout.fillWidth: true
        implicitHeight: root.passwordDialogOpen
            ? pwInner.implicitHeight + Appearance.padding.large * 2
            : 0
        opacity: root.passwordDialogOpen ? 1 : 0
        clip: true

        radius: Appearance.rounding.normal
        color: Colours.palette.m3secondaryContainer

        ColumnLayout {
            id: pwInner

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.normal

            StyledText {
                text: qsTr("Connect to \"%1\"").arg(root.passwordTarget)
                font.weight: 500
                color: Colours.palette.m3onSecondaryContainer
            }

            StyledTextField {
                id: passwordField

                Layout.fillWidth: true
                placeholderText: qsTr("Password")
                echoMode: TextInput.Password
                color: Colours.palette.m3onSecondaryContainer

                padding: Appearance.padding.normal
                leftPadding: Appearance.padding.normal
                rightPadding: Appearance.padding.normal

                background: StyledRect {
                    radius: Appearance.rounding.small
                    color: Qt.alpha(Colours.palette.m3onSecondaryContainer, 0.1)
                    border.width: 1
                    border.color: Qt.alpha(Colours.palette.m3onSecondaryContainer, 0.3)
                }

                onAccepted: {
                    if (text.length >= 8) {
                        Network.connectToNetwork(root.passwordTarget, text);
                        root.passwordDialogOpen = false;
                        text = "";
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                Item { Layout.fillWidth: true }

                // Cancel
                StyledRect {
                    implicitHeight: cancelLbl.implicitHeight + Appearance.padding.normal * 2
                    implicitWidth: cancelLbl.implicitWidth + Appearance.padding.large * 2
                    radius: Appearance.rounding.full
                    color: Qt.alpha(Colours.palette.m3onSecondaryContainer, 0.12)

                    StateLayer {
                        color: Colours.palette.m3onSecondaryContainer
                        function onClicked(): void {
                            root.passwordDialogOpen = false;
                            root.passwordTarget = "";
                            passwordField.text = "";
                        }
                    }

                    StyledText {
                        id: cancelLbl
                        anchors.centerIn: parent
                        text: qsTr("Cancel")
                        color: Colours.palette.m3onSecondaryContainer
                    }
                }

                // Connect
                StyledRect {
                    implicitHeight: connectLbl.implicitHeight + Appearance.padding.normal * 2
                    implicitWidth: connectLbl.implicitWidth + Appearance.padding.large * 2
                    radius: Appearance.rounding.full
                    color: Colours.palette.m3primary

                    StateLayer {
                        color: Colours.palette.m3onPrimary
                        disabled: passwordField.text.length < 8
                        function onClicked(): void {
                            Network.connectToNetwork(root.passwordTarget, passwordField.text);
                            root.passwordDialogOpen = false;
                            passwordField.text = "";
                        }
                    }

                    StyledText {
                        id: connectLbl
                        anchors.centerIn: parent
                        text: qsTr("Connect")
                        color: Colours.palette.m3onPrimary
                    }
                }
            }
        }

        Behavior on implicitHeight {
            Anim {
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }
        Behavior on opacity { Anim {} }
    }

    // Clear connecting state once network activates
    Connections {
        target: Network
        function onActiveChanged(): void {
            if (Network.active && root.passwordTarget === Network.active.ssid)
                root.passwordTarget = "";
        }
    }

    // ── ToggleButton component ────────────────────────────────────────────────
    component ToggleButton: StyledRect {
        id: toggleBtn

        required property bool toggled
        property string icon: ""
        property string label: ""
        property string accent: "Secondary"

        function onClicked(): void {}

        Layout.preferredWidth: implicitWidth
            + (toggleStateLayer.pressed ? Appearance.padding.normal * 2 : toggled ? Appearance.padding.small * 2 : 0)
        implicitWidth: toggleBtnInner.implicitWidth + Appearance.padding.large * 2
        implicitHeight: toggleBtnIcon.implicitHeight + Appearance.padding.normal * 2

        radius: toggled || toggleStateLayer.pressed
            ? Appearance.rounding.small
            : Math.min(width, height) / 2 * Math.min(1, Appearance.rounding.scale)
        color: toggled
            ? Colours.palette[`m3${accent.toLowerCase()}`]
            : Colours.palette[`m3${accent.toLowerCase()}Container`]

        StateLayer {
            id: toggleStateLayer
            color: toggleBtn.toggled
                ? Colours.palette[`m3on${toggleBtn.accent}`]
                : Colours.palette[`m3on${toggleBtn.accent}Container`]
            function onClicked(): void { toggleBtn.onClicked(); }
        }

        RowLayout {
            id: toggleBtnInner
            anchors.centerIn: parent
            spacing: Appearance.spacing.normal

            MaterialIcon {
                id: toggleBtnIcon
                visible: !!text
                fill: toggleBtn.toggled ? 1 : 0
                text: toggleBtn.icon
                color: toggleBtn.toggled
                    ? Colours.palette[`m3on${toggleBtn.accent}`]
                    : Colours.palette[`m3on${toggleBtn.accent}Container`]
                font.pointSize: Appearance.font.size.large

                Behavior on fill { Anim {} }
            }

            Loader {
                asynchronous: true
                active: !!toggleBtn.label
                visible: active
                sourceComponent: StyledText {
                    text: toggleBtn.label
                    color: toggleBtn.toggled
                        ? Colours.palette[`m3on${toggleBtn.accent}`]
                        : Colours.palette[`m3on${toggleBtn.accent}Container`]
                }
            }
        }

        Behavior on radius {
            Anim {
                duration: Appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
            }
        }
        Behavior on Layout.preferredWidth {
            Anim {
                duration: Appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
            }
        }
    }
}

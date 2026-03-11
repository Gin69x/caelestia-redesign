pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.images
import qs.components.effects
import qs.services
import qs.config
import qs.utils
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    required property var lock

    readonly property list<string> timeComponents: Time.format(Config.services.useTwelveHourClock ? "hh:mm:A" : "hh:mm").split(":")
    readonly property real centerScale: Math.min(1, (lock.screen?.height ?? 1440) / 1440)
    readonly property int centerWidth: Config.lock.sizes.centerWidth * centerScale

    // Accent color extracted from album art
    readonly property color accent: accentExtractor.accentColor
    readonly property color accentDim: Qt.hsla(accent.hslHue, accent.hslSaturation, accent.hslLightness * 0.75, 0.85)

    AlbumAccentColor {
        id: accentExtractor
        imageUrl: Players.active?.trackArtUrl ?? ""
    }

    // ── Fullscreen blurred album art background ──────────────────────────────
    Image {
        id: albumArt

        anchors.fill: parent
        source: Players.active?.trackArtUrl ?? ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize.width: width
        sourceSize.height: height

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            blurMax: 64
            blurMultiplier: 1
        }

        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity {
            Anim { duration: Appearance.anim.durations.large }
        }
    }

    // Dark scrim so text is always readable over any album art
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
    }

    // ── Center column ────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.centerIn: parent
        width: root.centerWidth
        spacing: Appearance.spacing.large * 2

        // Clock
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.spacing.small

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: root.timeComponents[0]
                color: root.accent
                font.pointSize: Math.floor(Appearance.font.size.extraLarge * 3 * root.centerScale)
                font.family: Appearance.font.family.clock
                font.bold: true

                Behavior on color { ColorAnimation { duration: Appearance.anim.durations.large } }
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: ":"
                color: root.accentDim
                font.pointSize: Math.floor(Appearance.font.size.extraLarge * 3 * root.centerScale)
                font.family: Appearance.font.family.clock
                font.bold: true

                Behavior on color { ColorAnimation { duration: Appearance.anim.durations.large } }
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: root.timeComponents[1]
                color: root.accent
                font.pointSize: Math.floor(Appearance.font.size.extraLarge * 3 * root.centerScale)
                font.family: Appearance.font.family.clock
                font.bold: true

                Behavior on color { ColorAnimation { duration: Appearance.anim.durations.large } }
            }

            Loader {
                Layout.leftMargin: Appearance.spacing.small
                Layout.alignment: Qt.AlignVCenter
                asynchronous: true
                active: Config.services.useTwelveHourClock
                visible: active

                sourceComponent: StyledText {
                    text: root.timeComponents[2] ?? ""
                    color: root.accentDim
                    font.pointSize: Math.floor(Appearance.font.size.extraLarge * 2 * root.centerScale)
                    font.family: Appearance.font.family.clock
                    font.bold: true
                }
            }
        }

        // Date
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: -Appearance.padding.large * 2
            text: Time.format("dddd, d MMMM yyyy")
            color: root.accentDim
            font.pointSize: Math.floor(Appearance.font.size.extraLarge * root.centerScale)
            font.family: Appearance.font.family.mono
            font.bold: true

            Behavior on color { ColorAnimation { duration: Appearance.anim.durations.large } }
        }

        // Track info
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.spacing.small

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                animate: true
                text: Players.active?.trackArtist ?? ""
                color: root.accent
                font.pointSize: Appearance.font.size.large
                font.family: Appearance.font.family.mono
                font.weight: 600
                elide: Text.ElideRight

                Behavior on color { ColorAnimation { duration: Appearance.anim.durations.large } }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                animate: true
                text: Players.active?.trackTitle ?? ""
                color: root.accentDim
                font.pointSize: Appearance.font.size.larger
                font.family: Appearance.font.family.mono
                elide: Text.ElideRight

                Behavior on color { ColorAnimation { duration: Appearance.anim.durations.large } }
            }
        }

        // Avatar
        StyledClippingRect {
            Layout.topMargin: Appearance.spacing.large
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: root.centerWidth / 2
            implicitHeight: root.centerWidth / 2
            color: Qt.rgba(1, 1, 1, 0.1)
            radius: Appearance.rounding.full

            MaterialIcon {
                anchors.centerIn: parent
                text: "person"
                color: Qt.rgba(1, 1, 1, 0.4)
                font.pointSize: Math.floor(root.centerWidth / 4)
            }

            CachingImage {
                anchors.fill: parent
                path: `${Paths.home}/.face`
            }
        }

        // Password input
        StyledRect {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: root.centerWidth * 0.8
            implicitHeight: inputRow.implicitHeight + Appearance.padding.small * 2
            color: Qt.rgba(1, 1, 1, 0.15)
            radius: Appearance.rounding.full

            focus: true
            onActiveFocusChanged: {
                if (!activeFocus)
                    forceActiveFocus();
            }

            Keys.onPressed: event => {
                if (root.lock.unlocking)
                    return;
                if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return)
                    mediaInputField.placeholder.animate = false;
                root.lock.pam.handleKey(event);
            }

            StateLayer {
                hoverEnabled: false
                cursorShape: Qt.IBeamCursor
                function onClicked(): void {
                    parent.forceActiveFocus();
                }
            }

            RowLayout {
                id: inputRow

                anchors.fill: parent
                anchors.margins: Appearance.padding.small
                spacing: Appearance.spacing.normal

                Item {
                    implicitWidth: implicitHeight
                    implicitHeight: fprintIcon.implicitHeight + Appearance.padding.small * 2

                    MaterialIcon {
                        id: fprintIcon

                        anchors.centerIn: parent
                        animate: true
                        text: {
                            if (root.lock.pam.fprint.tries >= Config.lock.maxFprintTries)
                                return "fingerprint_off";
                            if (root.lock.pam.fprint.active)
                                return "fingerprint";
                            return "lock";
                        }
                        color: root.lock.pam.fprint.tries >= Config.lock.maxFprintTries
                            ? Colours.palette.m3error
                            : root.accent
                        opacity: root.lock.pam.passwd.active ? 0 : 1

                        Behavior on color { ColorAnimation { duration: Appearance.anim.durations.large } }
                        Behavior on opacity { Anim {} }
                    }

                    CircularIndicator {
                        anchors.fill: parent
                        running: root.lock.pam.passwd.active
                    }
                }

                InputField {
                    id: mediaInputField
                    pam: root.lock.pam
                }

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: enterIcon.implicitHeight + Appearance.padding.small * 2
                    color: root.lock.pam.buffer ? root.accent : Qt.rgba(1, 1, 1, 0.2)
                    radius: Appearance.rounding.full

                    Behavior on color { ColorAnimation { duration: Appearance.anim.durations.small } }

                    StateLayer {
                        color: root.lock.pam.buffer ? Qt.rgba(0, 0, 0, 0.5) : "white"
                        function onClicked(): void {
                            root.lock.pam.passwd.start();
                        }
                    }

                    MaterialIcon {
                        id: enterIcon

                        anchors.centerIn: parent
                        text: "arrow_forward"
                        color: root.lock.pam.buffer ? Qt.rgba(0, 0, 0, 0.8) : "white"
                        font.weight: 500
                    }
                }
            }
        }

        // Auth state + error messages
        Item {
            Layout.fillWidth: true
            Layout.topMargin: -Appearance.spacing.large
            implicitHeight: Math.max(stateMsg.implicitHeight, errorMsg.implicitHeight)

            Behavior on implicitHeight { Anim {} }

            StyledText {
                id: stateMsg

                readonly property string msg: {
                    if (Hypr.kbLayout !== Hypr.defaultKbLayout) {
                        if (Hypr.capsLock && Hypr.numLock)
                            return qsTr("Caps lock and Num lock are ON.\nKeyboard layout: %1").arg(Hypr.kbLayoutFull);
                        if (Hypr.capsLock)
                            return qsTr("Caps lock is ON. Kb layout: %1").arg(Hypr.kbLayoutFull);
                        if (Hypr.numLock)
                            return qsTr("Num lock is ON. Kb layout: %1").arg(Hypr.kbLayoutFull);
                        return qsTr("Keyboard layout: %1").arg(Hypr.kbLayoutFull);
                    }
                    if (Hypr.capsLock && Hypr.numLock)
                        return qsTr("Caps lock and Num lock are ON.");
                    if (Hypr.capsLock)
                        return qsTr("Caps lock is ON.");
                    if (Hypr.numLock)
                        return qsTr("Num lock is ON.");
                    return "";
                }

                property bool shouldBeVisible

                onMsgChanged: {
                    if (msg) {
                        text = msg;
                        shouldBeVisible = true;
                    } else {
                        shouldBeVisible = false;
                    }
                }

                anchors.left: parent.left
                anchors.right: parent.right

                scale: shouldBeVisible && !errorMsg.msg ? 1 : 0.7
                opacity: shouldBeVisible && !errorMsg.msg ? 1 : 0
                color: root.accentDim
                font.family: Appearance.font.family.mono
                horizontalAlignment: Qt.AlignHCenter
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                lineHeight: 1.2

                Behavior on scale { Anim {} }
                Behavior on opacity { Anim {} }
            }

            StyledText {
                id: errorMsg

                readonly property Pam pam: root.lock.pam
                readonly property string msg: {
                    if (pam.fprintState === "error")
                        return qsTr("FP ERROR: %1").arg(pam.fprint.message);
                    if (pam.state === "error")
                        return qsTr("PW ERROR: %1").arg(pam.passwd.message);
                    if (pam.lockMessage)
                        return pam.lockMessage;
                    if (pam.state === "max" && pam.fprintState === "max")
                        return qsTr("Maximum password and fingerprint attempts reached.");
                    if (pam.state === "max")
                        return pam.fprint.available ? qsTr("Maximum password attempts reached. Please use fingerprint.") : qsTr("Maximum password attempts reached.");
                    if (pam.fprintState === "max")
                        return qsTr("Maximum fingerprint attempts reached. Please use password.");
                    if (pam.state === "fail")
                        return pam.fprint.available ? qsTr("Incorrect password. Please try again or use fingerprint.") : qsTr("Incorrect password. Please try again.");
                    if (pam.fprintState === "fail")
                        return qsTr("Fingerprint not recognized (%1/%2). Please try again or use password.").arg(pam.fprint.tries).arg(Config.lock.maxFprintTries);
                    return "";
                }

                anchors.left: parent.left
                anchors.right: parent.right

                scale: msg ? 1 : 0.7
                opacity: msg ? 1 : 0
                color: Colours.palette.m3error
                font.pointSize: Appearance.font.size.small
                font.family: Appearance.font.family.mono
                horizontalAlignment: Qt.AlignHCenter
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere

                Behavior on scale { Anim {} }
                Behavior on opacity { Anim {} }
            }
        }

        // Media controls
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.spacing.large

            MediaControl {
                icon: "skip_previous"
                function onClicked(): void {
                    if (Players.active?.canGoPrevious)
                        Players.active.previous();
                }
            }

            MediaControl {
                animate: true
                icon: isPlaying ? "pause" : "play_arrow"
                highlighted: true
                level: isPlaying ? 2 : 1
                isPlaying: Players.active?.isPlaying ?? false
                function onClicked(): void {
                    if (Players.active?.canTogglePlaying)
                        Players.active.togglePlaying();
                }
            }

            MediaControl {
                icon: "skip_next"
                function onClicked(): void {
                    if (Players.active?.canGoNext)
                        Players.active.next();
                }
            }
        }
    }

    // ── Reusable media control button ────────────────────────────────────────
    component MediaControl: StyledRect {
        id: ctrl

        property alias animate: ctrlIcon.animate
        property alias icon: ctrlIcon.text
        property bool isPlaying: false
        property bool highlighted: false
        property int level: 1

        function onClicked(): void {}

        Layout.preferredWidth: implicitWidth + (ctrlState.pressed ? Appearance.padding.normal * 2 : isPlaying ? Appearance.padding.small * 2 : 0)
        implicitWidth: ctrlIcon.implicitWidth + Appearance.padding.large * 2
        implicitHeight: ctrlIcon.implicitHeight + Appearance.padding.normal * 2

        color: highlighted && isPlaying ? root.accent : Qt.rgba(1, 1, 1, 0.15)
        radius: (highlighted && isPlaying) || ctrlState.pressed ? Appearance.rounding.normal : Math.min(implicitWidth, implicitHeight) / 2 * Math.min(1, Appearance.rounding.scale)

        Behavior on color { ColorAnimation { duration: Appearance.anim.durations.large } }

        StateLayer {
            id: ctrlState
            color: highlighted && ctrl.isPlaying ? Qt.rgba(0, 0, 0, 0.5) : "white"
            function onClicked(): void { ctrl.onClicked(); }
        }

        MaterialIcon {
            id: ctrlIcon

            anchors.centerIn: parent
            color: highlighted && ctrl.isPlaying ? Qt.rgba(0, 0, 0, 0.8) : root.accent
            font.pointSize: Appearance.font.size.large
            fill: ctrl.isPlaying ? 1 : 0

            Behavior on color { ColorAnimation { duration: Appearance.anim.durations.large } }
            Behavior on fill { Anim {} }
        }

        Behavior on Layout.preferredWidth {
            Anim {
                duration: Appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
            }
        }

        Behavior on radius {
            Anim {
                duration: Appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
            }
        }
    }
}

pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + Appearance.padding.large * 2

    radius: Appearance.rounding.normal
    color: Colours.tPalette.m3surfaceContainer

    // Progress 0–1, animated
    property real playerProgress: {
        const active = Players.active;
        return active?.length ? active.position / active.length : 0;
    }

    function lengthStr(length: int): string {
        if (length < 0) return "0:00";
        const hours = Math.floor(length / 3600);
        const mins  = Math.floor((length % 3600) / 60);
        const secs  = Math.floor(length % 60).toString().padStart(2, "0");
        return hours > 0
            ? `${hours}:${mins.toString().padStart(2, "0")}:${secs}`
            : `${mins}:${secs}`;
    }

    Behavior on playerProgress {
        Anim { duration: Appearance.anim.durations.large }
    }

    Timer {
        running: Players.active?.isPlaying ?? false
        interval: 500
        triggeredOnStart: true
        repeat: true
        onTriggered: Players.active?.positionChanged()
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.normal

        // ── Cover art + text row ─────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            // Rounded square cover art
            StyledClippingRect {
                id: cover

                implicitWidth: 56
                implicitHeight: 56
                radius: Appearance.rounding.small
                color: Colours.tPalette.m3surfaceContainerHigh

                    MaterialIcon {
                        anchors.centerIn: parent
                        grade: 200
                        text: "art_track"
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: cover.width * 0.4
                    }

                Image {
                    anchors.fill: parent
                    source: Players.active?.trackArtUrl ?? ""
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: width
                    sourceSize.height: height
                }
            }

            // Title / album / artist
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    animate: true
                    text: (Players.active?.trackTitle ?? qsTr("No media")) || qsTr("Unknown title")
                    color: Colours.palette.m3primary
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 500
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    animate: true
                    visible: !!Players.active
                    text: Players.active?.trackAlbum || qsTr("Unknown album")
                    color: Qt.alpha(Colours.palette.m3primary, 0.6)
                    font.pointSize: Appearance.font.size.small
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    animate: true
                    text: (Players.active?.trackArtist ?? qsTr("Play something!")) || qsTr("Unknown artist")
                    color: Qt.alpha(Colours.palette.m3primary, 0.8)
                    font.pointSize: Appearance.font.size.small
                    elide: Text.ElideRight
                }
            }
        }

        // ── Seek slider ──────────────────────────────────────────────────
        StyledSlider {
            id: slider

            Layout.fillWidth: true
            enabled: !!Players.active
            implicitHeight: Appearance.padding.normal * 3

            onMoved: {
                const active = Players.active;
                if (active?.canSeek && active?.positionSupported)
                    active.position = value * active.length;
            }

            Binding {
                target: slider
                property: "value"
                value: root.playerProgress
                when: !slider.pressed
            }

            CustomMouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton

                function onWheel(event: WheelEvent) {
                    const active = Players.active;
                    if (!active?.canSeek || !active?.positionSupported) return;
                    event.accepted = true;
                    const delta = event.angleDelta.y > 0 ? 10 : -10;
                    Qt.callLater(() => {
                        active.position = Math.max(0, Math.min(active.length, active.position + delta));
                    });
                }
            }
        }

        // ── Timestamps ───────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            implicitHeight: Math.max(posText.implicitHeight, lenText.implicitHeight)

            StyledText {
                id: posText
                anchors.left: parent.left
                text: root.lengthStr(Players.active?.position ?? -1)
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small
            }

            StyledText {
                id: lenText
                anchors.right: parent.right
                text: root.lengthStr(Players.active?.length ?? -1)
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small
            }
        }

        // ── Playback controls ────────────────────────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.spacing.small

            PlayerControl {
                type: IconButton.Text
                icon: "skip_previous"
                font.pointSize: Math.round(Appearance.font.size.large * 1.5)
                disabled: !Players.active?.canGoPrevious
                onClicked: Players.active?.previous()
            }

            PlayerControl {
                icon: Players.active?.isPlaying ? "pause" : "play_arrow"
                label.animate: true
                toggle: true
                padding: Appearance.padding.small / 2
                checked: Players.active?.isPlaying
                font.pointSize: Math.round(Appearance.font.size.large * 1.5)
                disabled: !Players.active?.canTogglePlaying
                onClicked: Players.active?.togglePlaying()
            }

            PlayerControl {
                type: IconButton.Text
                icon: "skip_next"
                font.pointSize: Math.round(Appearance.font.size.large * 1.5)
                disabled: !Players.active?.canGoNext
                onClicked: Players.active?.next()
            }
        }

        // ── Player selector row ──────────────────────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.spacing.small

            PlayerControl {
                type: IconButton.Text
                icon: "move_up"
                inactiveOnColour: Colours.palette.m3secondary
                padding: Appearance.padding.small
                font.pointSize: Appearance.font.size.large
                disabled: !Players.active?.canRaise
                onClicked: Players.active?.raise()
            }

            SplitButton {
                id: playerSelector

                disabled: !Players.list.length
                active: menuItems.find(m => m.modelData === Players.active) ?? menuItems[0]
                menu.onItemSelected: item => Players.manualActive = item.modelData

                menuItems: playerList.instances
                fallbackIcon: "music_off"
                fallbackText: qsTr("No players")
                label.elide: Text.ElideRight
                stateLayer.disabled: true
                menuOnTop: true

                Variants {
                    id: playerList
                    model: Players.list

                    MenuItem {
                        required property MprisPlayer modelData
                        icon: modelData === Players.active ? "check" : ""
                        text: Players.getIdentity(modelData)
                        activeIcon: "animated_images"
                    }
                }
            }

            PlayerControl {
                type: IconButton.Text
                icon: "delete"
                inactiveOnColour: Colours.palette.m3error
                padding: Appearance.padding.small
                font.pointSize: Appearance.font.size.large
                disabled: !Players.active?.canQuit
                onClicked: Players.active?.quit()
            }
        }
    }

    component PlayerControl: IconButton {
        Layout.preferredWidth: implicitWidth + (stateLayer.pressed ? Appearance.padding.large : internalChecked ? Appearance.padding.smaller : 0)
        radius: stateLayer.pressed ? Appearance.rounding.small / 2 : internalChecked ? Appearance.rounding.small : implicitHeight / 2
        radiusAnim.duration: Appearance.anim.durations.expressiveFastSpatial
        radiusAnim.easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial

        Behavior on Layout.preferredWidth {
            Anim {
                duration: Appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
            }
        }
    }
}

import "cards"
import qs.components
import qs.components.controls
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var props
    required property var visibilities

    property string currentPage: "main"

    implicitHeight: {
        switch (currentPage) {
            case "wifi":     return wifiPage.implicitHeight;
            case "bluetooth": return bluetoothPage.implicitHeight;
            case "recorder": return recorderPage.implicitHeight;
            default:         return mainPage.implicitHeight;
        }
    }

    Behavior on implicitHeight {
        Anim {
            duration: Appearance.anim.durations.normal
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }

    // ── Shared back button row component ────────────────────────────────────
    component BackRow: RowLayout {
        required property string title
        signal back()

        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        IconButton {
            icon: "arrow_back"
            type: IconButton.Text
            onClicked: parent.back()
        }

        StyledText {
            Layout.fillWidth: true
            text: parent.title
            font.pointSize: Appearance.font.size.normal
        }
    }

    // ── Shared page animation component ─────────────────────────────────────
    component Page: Item {
        id: page

        property bool active: false
        default property alias content: col.children

        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: col.implicitHeight

        opacity: active ? 1 : 0
        scale: active ? 1 : 0.9
        visible: opacity > 0
        transformOrigin: Item.Top

        Behavior on opacity {
            Anim {
                duration: page.opacity === 0 ? Appearance.anim.durations.small : Appearance.anim.durations.normal
                easing.bezierCurve: page.opacity === 0 ? Appearance.anim.curves.standardAccel : Appearance.anim.curves.standardDecel
            }
        }
        Behavior on scale {
            Anim {
                duration: page.scale === 1 ? Appearance.anim.durations.normal : Appearance.anim.durations.small
                easing.bezierCurve: page.scale === 1 ? Appearance.anim.curves.standardDecel : Appearance.anim.curves.standardAccel
            }
        }

        ColumnLayout {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Appearance.spacing.normal
        }
    }

    // ── Main page ────────────────────────────────────────────────────────────
    Page {
        id: mainPage
        active: root.currentPage === "main"

        MediaCard {
            Layout.fillWidth: true
        }

        Toggles {
            Layout.fillWidth: true
            visibilities: root.visibilities
            onOpenRecorder:   root.currentPage = "recorder"
            onOpenWifi:       root.currentPage = "wifi"
            onOpenBluetooth:  root.currentPage = "bluetooth"
        }

        PowerCard {
            Layout.fillWidth: true
        }
    }

    // ── WiFi page ────────────────────────────────────────────────────────────
    Page {
        id: wifiPage
        active: root.currentPage === "wifi"

        BackRow {
            title: qsTr("Wi-Fi")
            onBack: root.currentPage = "main"
        }

        NetworkPanel {
            Layout.fillWidth: true
        }
    }

    // ── Bluetooth page ───────────────────────────────────────────────────────
    Page {
        id: bluetoothPage
        active: root.currentPage === "bluetooth"

        BackRow {
            title: qsTr("Bluetooth")
            onBack: root.currentPage = "main"
        }

        BluetoothPanel {
            Layout.fillWidth: true
            visibilities: root.visibilities
        }
    }

    // ── Screen recorder page ─────────────────────────────────────────────────
    Page {
        id: recorderPage
        active: root.currentPage === "recorder"

        BackRow {
            title: qsTr("Screen Recorder")
            onBack: root.currentPage = "main"
        }

        Record {
            Layout.fillWidth: true
            props: root.props
            visibilities: root.visibilities
            z: 1
        }
    }

    RecordingDeleteModal {
        props: root.props
    }
}

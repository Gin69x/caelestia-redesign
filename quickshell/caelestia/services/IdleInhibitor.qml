pragma Singleton

import qs.config
import Caelestia
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    property alias enabled: props.enabled
    readonly property alias enabledSince: props.enabledSince

    onEnabledChanged: {
        if (enabled) {
            props.enabledSince = new Date();
            if (Config.utilities.toasts.idleInhibitorChanged)
                Toaster.toast(qsTr("Keep Awake enabled"), qsTr("Preventing system from sleeping"), "coffee");
        } else {
            if (Config.utilities.toasts.idleInhibitorChanged)
                Toaster.toast(qsTr("Keep Awake disabled"), qsTr("Normal power management restored"), "coffee");
        }
    }

    PersistentProperties {
        id: props

        property bool enabled
        property date enabledSince

        reloadableId: "idleInhibitor"
    }

    IdleInhibitor {
        enabled: props.enabled
        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            mask: Region {}
        }
    }

    IpcHandler {
        target: "idleInhibitor"

        function isEnabled(): bool {
            return props.enabled;
        }

        function toggle(): void {
            props.enabled = !props.enabled;
        }

        function enable(): void {
            props.enabled = true;
        }

        function disable(): void {
            props.enabled = false;
        }
    }
}

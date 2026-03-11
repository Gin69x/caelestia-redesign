pragma Singleton
pragma ComponentBehavior: Bound

import qs.components.misc
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Global temperature state represented as 0.0–1.0.
    // 1.0 = 6500K (neutral/daylight, no filter), 0.0 = 1000K (very warm/red).
    // hyprsunset applies temperature globally so per-monitor control is not possible.
    // 0.0 = 1000K (warm red), 0.5 = 6500K (neutral daylight), 1.0 = 10000K (cool blue)
    property real globalBrightness: 0.5

    readonly property int minTemp: 1000
    readonly property int neutralTemp: 6500
    readonly property int maxTemp: 10000

    function valueToTemp(value: real): int {
        if (value <= 0.5)
            return Math.round(root.minTemp + (value / 0.5) * (root.neutralTemp - root.minTemp));
        else
            return Math.round(root.neutralTemp + ((value - 0.5) / 0.5) * (root.maxTemp - root.neutralTemp));
    }

    readonly property list<Monitor> monitors: variants.instances

    function getMonitorForScreen(screen: ShellScreen): var {
        return monitors.find(m => m.modelData === screen);
    }

    function getMonitor(query: string): var {
        if (query === "active") {
            return monitors.find(m => Hypr.monitorFor(m.modelData)?.focused);
        }

        if (query.startsWith("model:")) {
            const model = query.slice(6);
            return monitors.find(m => m.modelData.model === model);
        }

        if (query.startsWith("serial:")) {
            const serial = query.slice(7);
            return monitors.find(m => m.modelData.serialNumber === serial);
        }

        if (query.startsWith("id:")) {
            const id = parseInt(query.slice(3), 10);
            return monitors.find(m => Hypr.monitorFor(m.modelData)?.id === id);
        }

        return monitors.find(m => m.modelData.name === query);
    }

    function increaseBrightness(): void {
        const monitor = getMonitor("active");
        if (monitor)
            monitor.setBrightness(monitor.brightness + 0.1);
    }

    function decreaseBrightness(): void {
        const monitor = getMonitor("active");
        if (monitor)
            monitor.setBrightness(monitor.brightness - 0.1);
    }

    Variants {
        id: variants

        model: Quickshell.screens

        Monitor {}
    }

    CustomShortcut {
        name: "brightnessUp"
        description: "Increase brightness"
        onPressed: root.increaseBrightness()
    }

    CustomShortcut {
        name: "brightnessDown"
        description: "Decrease brightness"
        onPressed: root.decreaseBrightness()
    }

    IpcHandler {
        target: "brightness"

        function get(): real {
            return getFor("active");
        }

        // Allows searching by active/model/serial/id/name
        function getFor(query: string): real {
            return root.getMonitor(query)?.brightness ?? -1;
        }

        function set(value: string): string {
            return setFor("active", value);
        }

        // Handles brightness value like brightnessctl: 0.1, +0.1, 0.1-, 10%, +10%, 10%-
        function setFor(query: string, value: string): string {
            const monitor = root.getMonitor(query);
            if (!monitor)
                return "Invalid monitor: " + query;

            let targetBrightness;
            if (value.endsWith("%-")) {
                const percent = parseFloat(value.slice(0, -2));
                targetBrightness = monitor.brightness - (percent / 100);
            } else if (value.startsWith("+") && value.endsWith("%")) {
                const percent = parseFloat(value.slice(1, -1));
                targetBrightness = monitor.brightness + (percent / 100);
            } else if (value.endsWith("%")) {
                const percent = parseFloat(value.slice(0, -1));
                targetBrightness = percent / 100;
            } else if (value.startsWith("+")) {
                const increment = parseFloat(value.slice(1));
                targetBrightness = monitor.brightness + increment;
            } else if (value.endsWith("-")) {
                const decrement = parseFloat(value.slice(0, -1));
                targetBrightness = monitor.brightness - decrement;
            } else if (value.includes("%") || value.includes("-") || value.includes("+")) {
                return `Invalid brightness format: ${value}\nExpected: 0.1, +0.1, 0.1-, 10%, +10%, 10%-`;
            } else {
                targetBrightness = parseFloat(value);
            }

            if (isNaN(targetBrightness))
                return `Failed to parse value: ${value}\nExpected: 0.1, +0.1, 0.1-, 10%, +10%, 10%-`;

            monitor.setBrightness(targetBrightness);

            return `Set brightness (gamma) to ${+monitor.brightness.toFixed(2)}`;
        }
    }

    // Debounce timer: waits for slider to settle before calling hyprsunset.
    // Prevents rapid pkill/spawn cycles when dragging the slider.
    Timer {
        id: debounceTimer

        interval: 150
        repeat: false
        onTriggered: Quickshell.execDetached(["sh", "-c", `pkill -9 -x hyprsunset; hyprsunset -t ${root.valueToTemp(root.globalBrightness)} &`]);
    }

    component Monitor: QtObject {
        id: monitor

        required property ShellScreen modelData

        // Mirrors the global temperature so Wrapper/Content see per-monitor
        // brightness signals even though hyprsunset applies the value globally.
        readonly property real brightness: root.globalBrightness

        function setBrightness(value: real): void {
            value = Math.max(0.05, Math.min(1, value));
            if (Math.round(root.globalBrightness * 100) === Math.round(value * 100))
                return;

            root.globalBrightness = value;
            debounceTimer.restart();
        }
    }
}

pragma Singleton

import qs.components
import qs.services
import Quickshell
import QtQuick

Singleton {
    id: root

    property var instance: null

    function toggle(): void {
        if (instance) {
            instance.destroy();
            instance = null;
        } else {
            create();
        }
    }

    function create(): void {
        if (!instance)
            instance = windowComp.createObject(null);
    }

    Component {
        id: windowComp

        FloatingWindow {
            id: win

            color: Colours.tPalette.m3surface
            title: qsTr("Task Manager")
            minimumSize.width: 1100
            minimumSize.height: 680
            implicitWidth: 1250
            implicitHeight: 750

            onVisibleChanged: {
                if (!visible) {
                    root.instance = null;
                    destroy();
                }
            }

            TaskManager {
                anchors.fill: parent
            }

            Behavior on color { CAnim {} }
        }
    }
}

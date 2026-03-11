pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property bool active

    // ── Data ─────────────────────────────────────────────────────────────────
    property var services:    []
    property string filterText: ""
    property string filterState: "all"  // "all" | "running" | "stopped" | "failed"
    property bool   showUser: false

    property var actionTarget: ""
    property string actionStatus: ""  // "pending" | "ok" | "error" | ""

    // ── Computed model ────────────────────────────────────────────────────────
    readonly property var filteredServices: {
        let s = services;
        if (filterState === "running") s = s.filter(x => x.sub === "running");
        else if (filterState === "stopped") s = s.filter(x => x.active === "inactive" || x.sub === "dead");
        else if (filterState === "failed") s = s.filter(x => x.active === "failed" || x.sub === "failed");
        if (filterText.trim().length > 0)
            s = s.filter(x => x.unit.toLowerCase().includes(filterText.toLowerCase()) ||
                               x.desc.toLowerCase().includes(filterText.toLowerCase()));
        return s;
    }

    function statusColor(svc) {
        if (svc.active === "failed" || svc.sub === "failed") return Colours.palette.m3error;
        if (svc.sub    === "running")                        return Colours.palette.m3primary;
        if (svc.active === "inactive")                       return Colours.palette.m3outline;
        return Colours.palette.m3tertiary;
    }

    function statusIcon(svc) {
        if (svc.active === "failed" || svc.sub === "failed") return "error";
        if (svc.sub    === "running")                        return "check_circle";
        if (svc.active === "activating")                     return "refresh";
        return "radio_button_unchecked";
    }

    function isRunning(svc) {
        return svc.sub === "running";
    }

    // ── Polling ───────────────────────────────────────────────────────────────
    Timer {
        interval: 5000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            unitsProc.running = true;
        }
    }

    Process {
        id: unitsProc
        command: root.showUser
            ? ["systemctl", "--user", "list-units", "--type=service", "--all", "--plain", "--no-pager", "--no-legend"]
            : ["systemctl",           "list-units", "--type=service", "--all", "--plain", "--no-pager", "--no-legend"]
        environment: ({ LANG: "C.UTF-8", LC_ALL: "C.UTF-8" })
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const parsed = {};
                for (const line of lines) {
                    if (!line.trim() || line.trim().startsWith("UNIT")) continue;
                    const clean = line.replace(/^[\s●○×✗✓▶]+/, "").trim();
                    const parts = clean.split(/\s+/);
                    if (parts.length < 4) continue;
                    const unit = parts[0].replace(/\.service$/, "");
                    parsed[unit] = {
                        unit:   unit,
                        load:   parts[1],
                        active: parts[2],
                        sub:    parts[3],
                        desc:   parts.slice(4).join(" ")
                    };
                }
                const savedY = svcList.contentY;
                root.services = Object.values(parsed).sort((a,b) => a.unit.localeCompare(b.unit));
                Qt.callLater(() => { svcList.contentY = savedY; });
            }
        }
    }

    Process {
        id: actionProc
        onExited: (code) => {
            root.actionStatus = code === 0 ? "ok" : "error";
            Qt.callLater(() => {
                unitsProc.running = true;
            });
            actionFeedbackTimer.restart();
        }
    }

    Timer {
        id: actionFeedbackTimer
        interval: 2500
        onTriggered: root.actionStatus = ""
    }

    function doAction(action, unit) {
        root.actionTarget = unit;
        root.actionStatus = "pending";
        const base = root.showUser
            ? ["systemctl", "--user"]
            : ["systemctl"];
        actionProc.exec([...base, action, unit + ".service"]);
    }

    // ── UI ────────────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: Appearance.spacing.normal

        // ── Toolbar ───────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: searchField.implicitHeight + Appearance.padding.normal * 2
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.normal
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        text: "search"
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.normal
                    }

                    StyledTextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: qsTr("Filter services…")
                        text: root.filterText
                        onTextChanged: root.filterText = text
                    }
                }
            }

            FilterChip { label: qsTr("All");     state_: "all";     currentFilter: root.filterState; onSelected: root.filterState = "all" }
            FilterChip { label: qsTr("Running"); state_: "running"; currentFilter: root.filterState; onSelected: root.filterState = "running" }
            FilterChip { label: qsTr("Stopped"); state_: "stopped"; currentFilter: root.filterState; onSelected: root.filterState = "stopped" }
            FilterChip { label: qsTr("Failed");  state_: "failed";  currentFilter: root.filterState; onSelected: root.filterState = "failed" }
        }

        // ── Stats bar ─────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.large

            StatBadge { label: qsTr("Total");   value: root.services.length.toString();                                      color_: Colours.palette.m3onSurface }
            StatBadge { label: qsTr("Running"); value: root.services.filter(s => s.sub === "running").length.toString();     color_: Colours.palette.m3primary }
            StatBadge { label: qsTr("Stopped"); value: root.services.filter(s => s.active === "inactive").length.toString(); color_: Colours.palette.m3outline }
            StatBadge { label: qsTr("Failed");  value: root.services.filter(s => s.active === "failed").length.toString();   color_: Colours.palette.m3error }

            Item { Layout.fillWidth: true }

            StyledRect {
                visible: root.actionStatus.length > 0
                implicitHeight: fbRow.implicitHeight + Appearance.padding.small * 2
                implicitWidth:  fbRow.implicitWidth  + Appearance.padding.normal * 2
                radius: Appearance.rounding.full
                color: root.actionStatus === "ok"    ? Qt.alpha(Colours.palette.m3primary,   0.15)
                     : root.actionStatus === "error" ? Qt.alpha(Colours.palette.m3error,     0.15)
                     :                                 Qt.alpha(Colours.palette.m3tertiary,  0.15)

                RowLayout {
                    id: fbRow
                    anchors.centerIn: parent
                    spacing: Appearance.spacing.small

                    MaterialIcon {
                        text: root.actionStatus === "ok"    ? "check_circle"
                            : root.actionStatus === "error" ? "error"
                            : "refresh"
                        color: root.actionStatus === "ok"    ? Colours.palette.m3primary
                             : root.actionStatus === "error" ? Colours.palette.m3error
                             :                                 Colours.palette.m3tertiary
                        font.pointSize: Appearance.font.size.normal
                    }
                    StyledText {
                        text: root.actionStatus === "ok"    ? qsTr("%1: done").arg(root.actionTarget)
                            : root.actionStatus === "error" ? qsTr("%1: failed").arg(root.actionTarget)
                            :                                 qsTr("Running %1…").arg(root.actionTarget)
                        font.pointSize: Appearance.font.size.small
                        color: root.actionStatus === "ok"    ? Colours.palette.m3primary
                             : root.actionStatus === "error" ? Colours.palette.m3error
                             :                                 Colours.palette.m3tertiary
                    }
                }
            }
        }

        // ── Column headers ────────────────────────────────────────────────────
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: svcHeaderRow.implicitHeight + Appearance.padding.normal * 2
            topLeftRadius:  Appearance.rounding.normal
            topRightRadius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            RowLayout {
                id: svcHeaderRow
                anchors.left:            parent.left
                anchors.right:           parent.right
                anchors.verticalCenter:  parent.verticalCenter
                anchors.leftMargin:      Appearance.padding.large
                anchors.rightMargin:     Appearance.padding.normal
                spacing:                 Appearance.spacing.normal

                StyledText {
                    Layout.fillWidth:    true
                    text:                qsTr("Service")
                    font.weight:         600
                    font.pointSize:      Appearance.font.size.small
                }

                StyledText {
                    Layout.preferredWidth:   72
                    horizontalAlignment:     Text.AlignHCenter
                    text:                    qsTr("State")
                    font.weight:             600
                    font.pointSize:          Appearance.font.size.small
                }

                StyledText {
                    Layout.preferredWidth:   180
                    horizontalAlignment:     Text.AlignLeft
                    text:                    qsTr("Actions")
                    font.weight:             600
                    font.pointSize:          Appearance.font.size.small
                }
            }
        }

        // ── Service list ──────────────────────────────────────────────────────
        StyledListView {
            id: svcList

            Layout.fillWidth:  true
            Layout.fillHeight: true
            clip:              true
            model:             root.filteredServices
            spacing:           0

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: svcList
            }

            delegate: StyledRect {
                id: svcRow

                required property var modelData
                required property int index

                width:         svcList.width
                implicitHeight: svcInner.implicitHeight + Appearance.padding.normal * 2

                readonly property bool isPending: root.actionStatus === "pending" && root.actionTarget === modelData.unit

                color: Qt.alpha(Colours.tPalette.m3surfaceContainer, index % 2 === 0 ? 0 : 0.04)

                Rectangle {
                    anchors.left:   parent.left
                    anchors.right:  parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color:  Qt.alpha(Colours.palette.m3outline, 0.08)
                }

                RowLayout {
                    id: svcInner
                    anchors.left:            parent.left
                    anchors.right:           parent.right
                    anchors.verticalCenter:  parent.verticalCenter
                    anchors.leftMargin:      Appearance.padding.large
                    anchors.rightMargin:     Appearance.padding.normal
                    spacing:                 Appearance.spacing.normal

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.normal

                        StyledRect {
                            implicitWidth:  dotIcon.implicitWidth  + Appearance.padding.small
                            implicitHeight: dotIcon.implicitHeight + Appearance.padding.small
                            radius: Appearance.rounding.full
                            color:  Qt.alpha(root.statusColor(svcRow.modelData), 0.15)

                            CircularIndicator {
                                anchors.fill: parent
                                running:      svcRow.isPending
                                fgColour:     Colours.palette.m3tertiary
                                bgColour:     "transparent"
                            }

                            MaterialIcon {
                                id: dotIcon
                                anchors.centerIn: parent
                                animate: true
                                text:  svcRow.isPending ? "refresh" : root.statusIcon(svcRow.modelData)
                                color: svcRow.isPending ? Colours.palette.m3tertiary : root.statusColor(svcRow.modelData)
                                font.pointSize: Appearance.font.size.normal
                                opacity: svcRow.isPending ? 0 : 1
                                Behavior on opacity { Anim {} }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text:       svcRow.modelData.unit
                                font.weight: svcRow.modelData.sub === "running" ? 500 : 400
                                elide:      Text.ElideRight
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text:  svcRow.modelData.desc.length > 0 ? svcRow.modelData.desc : svcRow.modelData.load
                                color: Colours.palette.m3outline
                                font.pointSize: Appearance.font.size.small
                                elide: Text.ElideRight
                            }
                        }
                    }

                    StyledRect {
                        Layout.preferredWidth:  72
                        implicitHeight: stateText.implicitHeight + Appearance.padding.smaller * 2
                        radius: Appearance.rounding.full
                        color:  Qt.alpha(root.statusColor(svcRow.modelData), 0.12)

                        StyledText {
                            id: stateText
                            anchors.centerIn: parent
                            text:  svcRow.modelData.sub.length > 0 ? svcRow.modelData.sub : svcRow.modelData.active
                            color: root.statusColor(svcRow.modelData)
                            font.pointSize: Appearance.font.size.small
                            font.weight:    500
                        }
                    }

                    RowLayout {
                        Layout.preferredWidth: 180
                        spacing:               Appearance.spacing.small

                        ActionButton {
                            label:    root.isRunning(svcRow.modelData) ? qsTr("Stop")  : qsTr("Start")
                            icon:     root.isRunning(svcRow.modelData) ? "stop_circle" : "play_circle"
                            accent:   root.isRunning(svcRow.modelData) ? "error"       : "primary"
                            disabled: svcRow.isPending
                            onClicked: root.doAction(root.isRunning(svcRow.modelData) ? "stop" : "start", svcRow.modelData.unit)
                        }

                        ActionButton {
                            label:    qsTr("Restart")
                            icon:     "refresh"
                            accent:   "secondary"
                            visible:  root.isRunning(svcRow.modelData)
                            disabled: svcRow.isPending
                            onClicked: root.doAction("restart", svcRow.modelData.unit)
                        }
                    }
                }
            }
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight:   Appearance.rounding.normal
            bottomLeftRadius:  Appearance.rounding.normal
            bottomRightRadius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer
        }
    }

    // ── Sub-components ────────────────────────────────────────────────────────

    component FilterChip: StyledRect {
        id: chip
        required property string label
        required property string state_
        required property string currentFilter
        signal selected()

        readonly property bool isActive: currentFilter === state_

        implicitHeight: chipLbl.implicitHeight + Appearance.padding.small * 2
        implicitWidth:  chipLbl.implicitWidth  + Appearance.padding.normal * 2
        radius: isActive ? Appearance.rounding.small : Appearance.rounding.full
        color:  isActive ? Colours.palette.m3secondaryContainer : Qt.alpha(Colours.palette.m3onSurface, 0.08)

        StateLayer {
            color: isActive ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
            function onClicked(): void { chip.selected(); }
        }

        StyledText {
            id: chipLbl
            anchors.centerIn: parent
            text:       chip.label
            font.pointSize: Appearance.font.size.small
            font.weight:    chip.isActive ? 600 : 400
            color: chip.isActive ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
        }

        Behavior on radius { Anim {} }
    }

    component StatBadge: Item {
        required property string label
        required property string value
        required property color  color_

        implicitHeight: sbCol.implicitHeight
        implicitWidth:  sbCol.implicitWidth

        ColumnLayout {
            id: sbCol
            anchors.centerIn: parent
            spacing: 0

            StyledText {
                text:       parent.parent.value
                font.pointSize: Appearance.font.size.larger
                font.weight:    600
                color:      parent.parent.color_
            }
            StyledText {
                text:  parent.parent.label
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3outline
            }
        }
    }

    component ActionButton: StyledRect {
        id: actBtn
        required property string label
        required property string icon
        required property string accent
        property bool disabled: false
        signal clicked()

        implicitHeight: actInner.implicitHeight + Appearance.padding.smaller * 2
        implicitWidth:  actInner.implicitWidth  + Appearance.padding.normal  * 2

        radius: Appearance.rounding.full
        color: disabled
            ? Qt.alpha(Colours.palette.m3onSurface, 0.08)
            : Qt.alpha(Colours.palette[`m3${accent}Container`] ?? Colours.palette.m3secondaryContainer, 0.8)

        StateLayer {
            color: Colours.palette[`m3on${actBtn.accent.charAt(0).toUpperCase() + actBtn.accent.slice(1)}Container`] ?? Colours.palette.m3onSecondaryContainer
            disabled: actBtn.disabled
            function onClicked(): void { if (!actBtn.disabled) actBtn.clicked(); }
        }

        RowLayout {
            id: actInner
            anchors.centerIn: parent
            spacing: Appearance.spacing.small / 2

            MaterialIcon {
                text: actBtn.icon
                font.pointSize: Appearance.font.size.small
                color: actBtn.disabled
                    ? Colours.palette.m3outline
                    : Colours.palette[`m3on${actBtn.accent.charAt(0).toUpperCase() + actBtn.accent.slice(1)}Container`] ?? Colours.palette.m3onSecondaryContainer
            }
            StyledText {
                text:       actBtn.label
                font.pointSize: Appearance.font.size.small
                font.weight:    500
                color: actBtn.disabled
                    ? Colours.palette.m3outline
                    : Colours.palette[`m3on${actBtn.accent.charAt(0).toUpperCase() + actBtn.accent.slice(1)}Container`] ?? Colours.palette.m3onSecondaryContainer
            }
        }

        Behavior on color { CAnim {} }
    }

    component Anim: NumberAnimation {
        duration:    Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}

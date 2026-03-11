pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property bool active
    required property int colCpu
    required property int colMem

    // ── Sort state ────────────────────────────────────────────────────────────
    property string sortCol: "name"
    property bool   sortAsc: true

    // ── Raw data ──────────────────────────────────────────────────────────────
    property var rawProcesses: []
    property var appPids:      ({})

    // ── Selection ─────────────────────────────────────────────────────────────
    property int selectedPid: -1

    readonly property var selectedProcess: {
        if (selectedPid < 0) return null;
        return rawProcesses.find(p => p.pid === selectedPid) ?? null;
    }

    readonly property string selectedDisplayName: {
        if (!selectedProcess) return "";
        const p = selectedProcess;
        if (appPids[p.pid]) {
            const title = appPids[p.pid].title ?? "";
            return title.length > 0 ? title : p.comm;
        }
        return p.comm;
    }

    // ── Computed display model ────────────────────────────────────────────────
    property var displayModel: []

    // ── Helpers ───────────────────────────────────────────────────────────────
    function fmtMem(kb) {
        if (kb >= 1048576) return (kb / 1048576).toFixed(1) + " GB";
        if (kb >= 1024)    return (kb / 1024).toFixed(0)    + " MB";
        return kb + " KB";
    }
    function fmtCpu(c) { return c.toFixed(1) + "%"; }

    function isSystem(p) {
        return p.user === "root" || p.ppid === 2 || p.ppid === 0 || p.comm.startsWith("[");
    }
    function isApp(p) { return !!appPids[p.pid]; }

    // preserveScroll: true on background data refreshes, false on user-initiated
    // sort/filter changes (where jumping to top is expected behaviour).
    function rebuildModel(preserveScroll) {
        const procs = rawProcesses;
        if (procs.length === 0) return;

        // Capture scroll position BEFORE the model assignment so we have the
        // correct value.  We then use Qt.callLater() to restore it after the
        // ListView has finished its internal layout pass — this is more reliable
        // than the synchronous onContentYChanged guard because Qt.callLater()
        // is deferred until the end of the current event-loop iteration, by
        // which time the ListView has already reset and laid out its delegates.
        const savedY = preserveScroll ? listView.contentY : -1;

        if (savedY >= 0) Qt.callLater(() => { listView.contentY = savedY; });

        if (sortCol === "name") {
            const apps  = procs.filter(p =>  isApp(p)).sort((a,b) => sortAsc ? a.comm.localeCompare(b.comm) : b.comm.localeCompare(a.comm));
            const sys   = procs.filter(p => !isApp(p) &&  isSystem(p)).sort((a,b) => sortAsc ? a.comm.localeCompare(b.comm) : b.comm.localeCompare(a.comm));
            const other = procs.filter(p => !isApp(p) && !isSystem(p)).sort((a,b) => sortAsc ? a.comm.localeCompare(b.comm) : b.comm.localeCompare(a.comm));
            const out = [];
            if (apps.length > 0)  { out.push({isSection:true, label: qsTr("Apps"),            count: apps.length});  apps.forEach(p  => out.push(Object.assign({}, p, {isSection:false}))); }
            if (other.length > 0) { out.push({isSection:true, label: qsTr("Processes"),        count: other.length}); other.forEach(p => out.push(Object.assign({}, p, {isSection:false}))); }
            if (sys.length > 0)   { out.push({isSection:true, label: qsTr("System Processes"), count: sys.length});   sys.forEach(p   => out.push(Object.assign({}, p, {isSection:false}))); }
            displayModel = out;
        } else {
            const compare = (a, b) => {
                let va, vb;
                if (sortCol === "cpu")      { va = a.cpu; vb = b.cpu; }
                else if (sortCol === "mem") { va = a.rss; vb = b.rss; }
                else                       { va = 0;     vb = 0; }
                return sortAsc ? va - vb : vb - va;
            };
            displayModel = procs.slice().sort(compare).map(p => Object.assign({}, p, {isSection: false}));
        }
    }

    onRawProcessesChanged: {
        if (selectedPid >= 0 && !rawProcesses.find(p => p.pid === selectedPid))
            selectedPid = -1;
        rebuildModel(true);
    }
    onSortColChanged: rebuildModel(false)
    onSortAscChanged: rebuildModel(false)
    onAppPidsChanged: rebuildModel(true)

    // ── App PID sync ─────────────────────────────────────────────────────────
    function refreshAppPids() {
        const map = {};
        const tls = Hyprland.toplevels.values;
        for (const tl of tls) {
            const obj = tl.lastIpcObject;
            if (obj && obj.pid > 0)
                map[obj.pid] = {title: obj.title ?? "", appClass: obj["class"] ?? ""};
        }
        appPids = map;
    }

    Connections {
        target: Hyprland
        function onToplevelsChanged() { root.refreshAppPids(); }
    }
    Component.onCompleted: refreshAppPids()

    // ── Process poller ────────────────────────────────────────────────────────
    Timer {
        interval: 2000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: psProc.running = true
    }

    Process {
        id: psProc
        command: ["ps", "-eo", "pid,ppid,user,pcpu,rss,comm", "--no-headers"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines  = text.trim().split("\n");
                const parsed = [];
                for (const line of lines) {
                    if (!line.trim()) continue;
                    const p = line.trim().split(/\s+/);
                    if (p.length < 6) continue;
                    parsed.push({
                        pid:  parseInt(p[0]),
                        ppid: parseInt(p[1]),
                        user: p[2],
                        cpu:  parseFloat(p[3]),
                        rss:  parseInt(p[4]),
                        comm: p.slice(5).join(" ")
                    });
                }
                root.rawProcesses = parsed;
            }
        }
    }

    // ── Kill logic ────────────────────────────────────────────────────────────
    Process {
        id: killProc
        onExited: (code) => { psProc.running = true; }
    }

    function killProcess(pid) {
        selectedPid = -1;
        killProc.exec(["sh", "-c", "kill -9 " + pid]);
    }

    // ── UI ────────────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Column header row ─────────────────────────────────────────────────
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: _headerSizer.implicitHeight + Appearance.padding.normal * 2

            topLeftRadius:  Appearance.rounding.normal
            topRightRadius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            StyledText {
                id: _headerSizer
                visible: false
                text: "Name"
                font.weight: 600
                font.pointSize: Appearance.font.size.small
            }

            RowLayout {
                id: headerRow
                anchors.fill: parent
                anchors.rightMargin: Appearance.padding.large
                spacing: 0

                HeaderCell {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    label: qsTr("Name")
                    col: "name"
                    alignRight: false
                }
                HeaderCell {
                    Layout.preferredWidth: root.colCpu
                    Layout.fillHeight: true
                    label: qsTr("CPU")
                    col: "cpu"
                    alignRight: true
                }
                HeaderCell {
                    Layout.preferredWidth: root.colMem
                    Layout.fillHeight: true
                    label: qsTr("Memory")
                    col: "mem"
                    alignRight: true
                }
            }
        }

        // ── Process list ──────────────────────────────────────────────────────
        StyledListView {
            id: listView

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true
            model: root.displayModel
            spacing: 0

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: listView
            }

            delegate: Item {
                id: delegateItem
                required property var modelData
                required property int index
                width: listView.width
                implicitHeight: modelData.isSection ? sectionContent.implicitHeight : rowContent.implicitHeight

                // ── Section header ────────────────────────────────────────
                Item {
                    id: sectionContent
                    visible: delegateItem.modelData.isSection
                    width: parent.width
                    implicitHeight: secRow.implicitHeight + Appearance.padding.smaller * 2

                    Rectangle {
                        anchors.fill: parent
                        color: Qt.alpha(Colours.palette.m3secondaryContainer, 0.15)
                    }

                    Rectangle {
                        anchors.left:   parent.left
                        anchors.top:    parent.top
                        anchors.bottom: parent.bottom
                        width: 3
                        radius: 2
                        color: Colours.palette.m3secondary
                    }

                    RowLayout {
                        id: secRow
                        anchors.left:  parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin:  Appearance.padding.large + 6
                        anchors.rightMargin: Appearance.padding.normal
                        spacing: Appearance.spacing.small

                        StyledText {
                            text: delegateItem.modelData.isSection
                                ? (delegateItem.modelData.label ?? "").toUpperCase()
                                : ""
                            font.weight: 700
                            font.pointSize: Appearance.font.size.small
                            font.letterSpacing: 0.8
                            color: Colours.palette.m3secondary
                        }

                        StyledRect {
                            visible: delegateItem.modelData.isSection &&
                                     (delegateItem.modelData.count ?? 0) > 0
                            implicitWidth:  _cntText.implicitWidth  + Appearance.padding.small * 2
                            implicitHeight: _cntText.implicitHeight + Appearance.padding.smaller
                            radius: Appearance.rounding.full
                            color: Qt.alpha(Colours.palette.m3secondary, 0.15)

                            StyledText {
                                id: _cntText
                                anchors.centerIn: parent
                                text: delegateItem.modelData.isSection
                                    ? (delegateItem.modelData.count ?? 0).toString()
                                    : ""
                                font.pointSize: Appearance.font.size.small
                                font.weight: 600
                                color: Colours.palette.m3secondary
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }
                }

                // ── Process row ───────────────────────────────────────────
                StyledRect {
                    id: rowContent
                    visible: !delegateItem.modelData.isSection
                    width: parent.width
                    implicitHeight: rowInner.implicitHeight + Appearance.padding.normal * 2

                    readonly property bool isAppRow:   !delegateItem.modelData.isSection && root.isApp(delegateItem.modelData)
                    readonly property bool isSelected: !delegateItem.modelData.isSection && root.selectedPid === delegateItem.modelData.pid

                    color: {
                        if (isSelected) return Qt.alpha(Colours.palette.m3primaryContainer, 0.28);
                        if (isAppRow)   return Qt.alpha(Colours.palette.m3primaryContainer, 0.10);
                        return Qt.alpha(Colours.tPalette.m3surfaceContainer, delegateItem.index % 2 === 0 ? 0 : 0.04);
                    }
                    Behavior on color { CAnim {} }

                    Rectangle {
                        anchors.left:   parent.left
                        anchors.top:    parent.top
                        anchors.bottom: parent.bottom
                        width: 3
                        radius: 2
                        color: Colours.palette.m3primary
                        opacity: rowContent.isSelected ? 1 : 0
                        Behavior on opacity { Anim {} }
                    }

                    StateLayer {
                        color: rowContent.isSelected
                            ? Colours.palette.m3primary
                            : Colours.palette.m3onSurface
                        function onClicked(): void {
                            if (delegateItem.modelData.isSection) return;
                            const pid = delegateItem.modelData.pid;
                            root.selectedPid = (root.selectedPid === pid) ? -1 : pid;
                        }
                    }

                    Rectangle {
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: Qt.alpha(Colours.palette.m3outline, 0.08)
                    }

                    RowLayout {
                        id: rowInner
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin:  Appearance.padding.large
                        anchors.rightMargin: Appearance.padding.large
                        spacing: 0

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.normal

                            StyledRect {
                                implicitWidth:  _rowIcon.implicitHeight + Appearance.padding.small * 2
                                implicitHeight: _rowIcon.implicitHeight + Appearance.padding.small * 2
                                radius: Appearance.rounding.small
                                color: {
                                    if (rowContent.isSelected)  return Qt.alpha(Colours.palette.m3primary, 0.25);
                                    if (rowContent.isAppRow)    return Qt.alpha(Colours.palette.m3primary, 0.15);
                                    if (!delegateItem.modelData.isSection && root.isSystem(delegateItem.modelData))
                                        return Qt.alpha(Colours.palette.m3tertiary, 0.12);
                                    return Qt.alpha(Colours.palette.m3onSurface, 0.08);
                                }
                                Behavior on color { CAnim {} }

                                MaterialIcon {
                                    id: _rowIcon
                                    anchors.centerIn: parent
                                    text: {
                                        if (delegateItem.modelData.isSection) return "apps";
                                        const d = delegateItem.modelData;
                                        if (rowContent.isAppRow) {
                                            const cls = root.appPids[d.pid]?.appClass ?? "";
                                            if (cls.includes("firefox") || cls.includes("chrome") || cls.includes("brave")) return "globe";
                                            if (cls.includes("code")    || cls.includes("studio"))                          return "code";
                                            if (cls.includes("term")    || cls.includes("kitty") || cls.includes("alacritty")) return "terminal";
                                            if (cls.includes("discord") || cls.includes("vesktop"))                         return "forum";
                                            return "window";
                                        }
                                        if (d.comm.startsWith("[")) return "memory";
                                        if (root.isSystem(d))       return "settings";
                                        return "terminal";
                                    }
                                    font.pointSize: Appearance.font.size.normal
                                    color: {
                                        if (rowContent.isSelected)  return Colours.palette.m3primary;
                                        if (rowContent.isAppRow)    return Colours.palette.m3primary;
                                        if (!delegateItem.modelData.isSection && root.isSystem(delegateItem.modelData))
                                            return Colours.palette.m3tertiary;
                                        return Colours.palette.m3onSurface;
                                    }
                                    Behavior on color { CAnim {} }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    Layout.fillWidth: true
                                    text: {
                                        if (delegateItem.modelData.isSection) return "";
                                        const d = delegateItem.modelData;
                                        if (rowContent.isAppRow) {
                                            const title = root.appPids[d.pid]?.title ?? "";
                                            return title.length > 0 ? title : d.comm;
                                        }
                                        return d.comm;
                                    }
                                    elide: Text.ElideRight
                                    font.weight: (rowContent.isAppRow || rowContent.isSelected) ? 500 : 400
                                    color: rowContent.isSelected
                                        ? Colours.palette.m3primary
                                        : (rowContent.isAppRow ? Colours.palette.m3primary : Colours.palette.m3onSurface)
                                    Behavior on color { CAnim {} }
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: delegateItem.modelData.isSection
                                        ? ""
                                        : qsTr("PID %1  ·  %2").arg(delegateItem.modelData.pid).arg(delegateItem.modelData.user)
                                    font.pointSize: Appearance.font.size.small
                                    color: Colours.palette.m3outline
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        // CPU
                        StyledText {
                            Layout.preferredWidth: root.colCpu
                            text: delegateItem.modelData.isSection ? "" : root.fmtCpu(delegateItem.modelData.cpu)
                            horizontalAlignment: Text.AlignRight
                            color: {
                                if (delegateItem.modelData.isSection) return Colours.palette.m3onSurface;
                                const c = delegateItem.modelData.cpu;
                                if (c >= 50) return Colours.palette.m3error;
                                if (c >= 20) return Colours.palette.m3tertiary;
                                return Colours.palette.m3onSurface;
                            }
                            font.weight: !delegateItem.modelData.isSection && delegateItem.modelData.cpu >= 10 ? 500 : 400
                        }

                        // Memory
                        StyledText {
                            Layout.preferredWidth: root.colMem
                            text: delegateItem.modelData.isSection ? "" : root.fmtMem(delegateItem.modelData.rss)
                            horizontalAlignment: Text.AlignRight
                            color: {
                                if (delegateItem.modelData.isSection) return Colours.palette.m3onSurface;
                                const m = delegateItem.modelData.rss;
                                if (m >= 2097152) return Colours.palette.m3error;
                                if (m >= 524288)  return Colours.palette.m3tertiary;
                                return Colours.palette.m3onSurface;
                            }
                        }
                    }
                }
            }
        }

        // ── Bottom action bar ─────────────────────────────────────────────────
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: _actionRow.implicitHeight + Appearance.padding.normal * 2
            bottomLeftRadius:  Appearance.rounding.normal
            bottomRightRadius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            Rectangle {
                anchors.left:  parent.left
                anchors.right: parent.right
                anchors.top:   parent.top
                height: 1
                color: Qt.alpha(Colours.palette.m3outline, 0.12)
            }

            RowLayout {
                id: _actionRow
                anchors.fill:        parent
                anchors.topMargin:    Appearance.padding.normal
                anchors.bottomMargin: Appearance.padding.normal
                anchors.leftMargin:   Appearance.padding.large
                anchors.rightMargin:  Appearance.padding.normal
                spacing: Appearance.spacing.normal

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small
                    visible: root.selectedPid >= 0

                    MaterialIcon {
                        text: "radio_button_checked"
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3primary
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: root.selectedDisplayName.length > 0
                            ? qsTr("%1  ·  PID %2").arg(root.selectedDisplayName).arg(root.selectedPid)
                            : ""
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3onSurface
                        elide: Text.ElideRight
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: root.selectedPid < 0
                    text: qsTr("Select a process to manage it")
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3outline
                    font.italic: true
                }

                StyledRect {
                    id: _endBtn
                    readonly property bool canKill: root.selectedPid >= 0

                    implicitHeight: _endBtnInner.implicitHeight + Appearance.padding.small * 2
                    implicitWidth:  _endBtnInner.implicitWidth  + Appearance.padding.normal * 2

                    radius: Appearance.rounding.full
                    color: canKill
                        ? Qt.alpha(Colours.palette.m3errorContainer, 0.85)
                        : Qt.alpha(Colours.palette.m3onSurface, 0.06)
                    Behavior on color { CAnim {} }

                    StateLayer {
                        color: Colours.palette.m3onErrorContainer
                        disabled: !_endBtn.canKill
                        function onClicked(): void {
                            if (_endBtn.canKill)
                                root.killProcess(root.selectedPid);
                        }
                    }

                    RowLayout {
                        id: _endBtnInner
                        anchors.centerIn: parent
                        spacing: Appearance.spacing.small / 2

                        MaterialIcon {
                            text: "cancel"
                            font.pointSize: Appearance.font.size.normal
                            color: _endBtn.canKill
                                ? Colours.palette.m3onErrorContainer
                                : Colours.palette.m3outline
                            Behavior on color { CAnim {} }
                        }
                        StyledText {
                            text: qsTr("End Process")
                            font.weight: 500
                            color: _endBtn.canKill
                                ? Colours.palette.m3onErrorContainer
                                : Colours.palette.m3outline
                            Behavior on color { CAnim {} }
                        }
                    }
                }
            }
        }
    }

    // ── Column header cell ────────────────────────────────────────────────────
    component HeaderCell: Item {
        id: cell

        required property string label
        required property string col
        property bool alignRight: false

        implicitHeight: _hRow.implicitHeight
        readonly property bool isActive: root.sortCol === col

        StateLayer {
            anchors.fill: parent
            color: Colours.palette.m3onSurface
            function onClicked(): void {
                if (root.sortCol === cell.col)
                    root.sortAsc = !root.sortAsc;
                else {
                    root.sortCol = cell.col;
                    root.sortAsc = (cell.col === "name");
                }
            }
        }

        RowLayout {
            id: _hRow
            anchors.left:  parent.left
            anchors.right: parent.right
            anchors.leftMargin: !cell.alignRight ? Appearance.padding.large : 0
            anchors.verticalCenter: parent.verticalCenter
            spacing: Appearance.spacing.small / 2

            StyledText {
                Layout.fillWidth: cell.alignRight
                text: cell.label
                font.weight: cell.isActive ? 600 : 400
                color: cell.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
                horizontalAlignment: cell.alignRight ? Text.AlignRight : Text.AlignLeft
            }

            MaterialIcon {
                visible: cell.isActive
                text: root.sortAsc ? "arrow_upward" : "arrow_downward"
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3primary
            }
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}

pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.containers
import qs.components.misc
import qs.components.effects
import qs.components.images
import qs.components.filedialog
import qs.services
import qs.config
import qs.utils
import Caelestia
import Caelestia.Services
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes

Item {
    id: root

    property PersistentProperties dashState: PersistentProperties {
        property int currentTab: 0
        property date currentDate: new Date()
        reloadableId: "dashSidebarState"
    }

    readonly property int sidebarWidth: 440

    readonly property FileDialog facePicker: FileDialog {
        title: qsTr("Select a profile picture")
        filterLabel: qsTr("Image files")
        filters: Images.validImageExtensions
        onAccepted: path => {
            if (CUtils.copyFile(Qt.resolvedUrl(path), Qt.resolvedUrl(`${Paths.home}/.face`)))
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low",
                    "-h", `STRING:image-path:${path}`,
                    "Profile picture changed",
                    `Profile picture changed to ${Paths.shortenHome(path)}`]);
            else
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "critical",
                    "Unable to change profile picture",
                    `Failed to change profile picture to ${Paths.shortenHome(path)}`]);
        }
    }

    implicitWidth:  sidebarWidth
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors.left:  parent.left
        anchors.right: parent.right
        anchors.top:   parent.top
        height: implicitHeight
        spacing: 10

        // ── User / Sysinfo card ───────────────────────────────────────────────
        Card {
            Layout.fillWidth: true
            implicitHeight: userRow.implicitHeight + 28

            RowLayout {
                id: userRow
                anchors.left:   parent.left
                anchors.right:  parent.right
                anchors.top:    parent.top
                anchors.margins: 14
                spacing: 14

                StyledClippingRect {
                    implicitWidth:  info.implicitHeight
                    implicitHeight: info.implicitHeight
                    radius: Appearance.rounding.large
                    color: Colours.palette.m3surfaceContainerHigh

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "person"; fill: 1; grade: 200
                        font.pointSize: Math.floor(info.implicitHeight / 2) || 1
                    }
                    CachingImage {
                        anchors.fill: parent
                        path: `${Paths.home}/.face`
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        // Dim overlay on hover
                        StyledRect {
                            anchors.fill: parent
                            color: Qt.alpha(Colours.palette.m3scrim, 0.5)
                            opacity: parent.containsMouse ? 1 : 0
                            Behavior on opacity { Anim { duration: Appearance.anim.durations.expressiveFastSpatial } }
                        }

                        // Camera icon button
                        StyledRect {
                            anchors.centerIn: parent
                            implicitWidth:  selectIcon.implicitHeight + Appearance.padding.small * 2
                            implicitHeight: selectIcon.implicitHeight + Appearance.padding.small * 2
                            radius: Appearance.rounding.normal
                            color: Colours.palette.m3primary
                            scale:   parent.containsMouse ? 1 : 0.5
                            opacity: parent.containsMouse ? 1 : 0

                            StateLayer {
                                color: Colours.palette.m3onPrimary
                                function onClicked(): void {
                                    root.facePicker.open();
                                }
                            }

                            MaterialIcon {
                                id: selectIcon
                                anchors.centerIn: parent
                                anchors.horizontalCenterOffset: -font.pointSize * 0.02
                                text: "frame_person"
                                color: Colours.palette.m3onPrimary
                                font.pointSize: Appearance.font.size.extraLarge
                            }

                            Behavior on scale   { Anim { duration: Appearance.anim.durations.expressiveFastSpatial; easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial } }
                            Behavior on opacity { Anim { duration: Appearance.anim.durations.expressiveFastSpatial } }
                        }
                    }
                }

                Column {
                    id: info
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Appearance.spacing.normal

                    InfoLine {
                        isIcon: false
                        iconSrc: SysInfo.osLogo
                        txt: `:  ${SysInfo.osPrettyName || SysInfo.osName}`
                        clr: Colours.palette.m3primary
                    }
                    InfoLine {
                        isIcon: true
                        iconMat: "select_window_2"
                        txt: `:  ${SysInfo.wm}`
                        clr: Colours.palette.m3secondary
                    }
                    InfoLine {
                        isIcon: true
                        iconMat: "timer"
                        txt: `:  ${qsTr("up %1").arg(SysInfo.uptime)}`
                        clr: Colours.palette.m3tertiary
                    }
                }

            }
        }

        // ── Weather card ──────────────────────────────────────────────────────
        Card {
            Layout.fillWidth: true
            implicitHeight: weatherRow.implicitHeight + 28

            Component.onCompleted: Weather.reload()

            RowLayout {
                id: weatherRow
                anchors.left:    parent.left
                anchors.right:   parent.right
                anchors.top:     parent.top
                anchors.margins: 14
                spacing: Appearance.spacing.large

                MaterialIcon {
                    id: wIcon
                    animate: true
                    text: Weather.icon
                    color: Colours.palette.m3secondary
                    font.pointSize: Appearance.font.size.extraLarge
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    animate: true
                    text: Weather.temp
                    color: Colours.palette.m3primary
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    animate: true
                    text: Weather.description
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.normal
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item { Layout.fillWidth: true }
            }
        }

        // ── DateTime + Calendar row ───────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // DateTime
            Card {
                implicitWidth:  Config.dashboard.sizes.dateTimeWidth
                implicitHeight: calCard.implicitHeight

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: -(font.pointSize * 0.4)
                        text: Time.format(Config.services.useTwelveHourClock ? "hh:mm:A" : "hh:mm").split(":")[0]
                        color: Colours.palette.m3secondary
                        font.pointSize: Appearance.font.size.extraLarge
                        font.family: Appearance.font.family.clock
                        font.weight: 600
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "•••"
                        color: Colours.palette.m3primary
                        font.pointSize: Appearance.font.size.extraLarge * 0.9
                        font.family: Appearance.font.family.clock
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: -(font.pointSize * 0.4)
                        text: Time.format(Config.services.useTwelveHourClock ? "hh:mm:A" : "hh:mm").split(":")[1]
                        color: Colours.palette.m3secondary
                        font.pointSize: Appearance.font.size.extraLarge
                        font.family: Appearance.font.family.clock
                        font.weight: 600
                    }
                    Loader {
                        Layout.alignment: Qt.AlignHCenter
                        active: Config.services.useTwelveHourClock
                        sourceComponent: StyledText {
                            text: Time.format("hh:mm:A").split(":")[2] ?? ""
                            color: Colours.palette.m3primary
                            font.pointSize: Appearance.font.size.large
                            font.family: Appearance.font.family.clock
                            font.weight: 600
                        }
                    }
                }
            }

            // Calendar
            Card {
                id: calCard
                Layout.fillWidth: true

                readonly property int currMonth: root.dashState.currentDate.getMonth()
                readonly property int currYear:  root.dashState.currentDate.getFullYear()

                implicitHeight: calInner.implicitHeight + Appearance.padding.large * 2

                CustomMouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.MiddleButton
                    onClicked: root.dashState.currentDate = new Date()
                    function onWheel(event: WheelEvent): void {
                        if (event.angleDelta.y > 0)
                            root.dashState.currentDate = new Date(calCard.currYear, calCard.currMonth - 1, 1);
                        else
                            root.dashState.currentDate = new Date(calCard.currYear, calCard.currMonth + 1, 1);
                    }
                }

                ColumnLayout {
                    id: calInner
                    anchors.left:    parent.left
                    anchors.right:   parent.right
                    anchors.top:     parent.top
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.small

                    // Month nav
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        Item {
                            implicitWidth:  implicitHeight
                            implicitHeight: prevIcon.implicitHeight + Appearance.padding.small * 2
                            StateLayer {
                                radius: Appearance.rounding.full
                                function onClicked(): void {
                                    root.dashState.currentDate = new Date(calCard.currYear, calCard.currMonth - 1, 1);
                                }
                            }
                            MaterialIcon {
                                id: prevIcon
                                anchors.centerIn: parent
                                text: "chevron_left"
                                color: Colours.palette.m3tertiary
                                font.pointSize: Appearance.font.size.normal
                                font.weight: 700
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: monthLabel.implicitHeight + Appearance.padding.small * 2
                            StyledText {
                                id: monthLabel
                                anchors.centerIn: parent
                                text: Qt.locale().standaloneMonthName(calCard.currMonth) + " " + calCard.currYear
                                color: Colours.palette.m3primary
                                font.pointSize: Appearance.font.size.normal
                                font.weight: 500
                                font.capitalization: Font.Capitalize
                            }
                        }

                        Item {
                            implicitWidth:  implicitHeight
                            implicitHeight: nextIcon.implicitHeight + Appearance.padding.small * 2
                            StateLayer {
                                radius: Appearance.rounding.full
                                function onClicked(): void {
                                    root.dashState.currentDate = new Date(calCard.currYear, calCard.currMonth + 1, 1);
                                }
                            }
                            MaterialIcon {
                                id: nextIcon
                                anchors.centerIn: parent
                                text: "chevron_right"
                                color: Colours.palette.m3tertiary
                                font.pointSize: Appearance.font.size.normal
                                font.weight: 700
                            }
                        }
                    }

                    // Day-of-week header
                    DayOfWeekRow {
                        Layout.fillWidth: true
                        locale: calGrid.locale
                        delegate: StyledText {
                            required property var model
                            horizontalAlignment: Text.AlignHCenter
                            text: model.shortName
                            font.weight: 500
                            color: (model.day === 0 || model.day === 6)
                                ? Colours.palette.m3secondary
                                : Colours.palette.m3onSurfaceVariant
                        }
                    }

                    // Month grid
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: calGrid.implicitHeight

                        MonthGrid {
                            id: calGrid
                            month: calCard.currMonth
                            year:  calCard.currYear
                            anchors.fill: parent
                            spacing: 3
                            locale: Qt.locale()

                            delegate: Item {
                                id: dayCell
                                required property var model

                                implicitWidth:  implicitHeight
                                implicitHeight: dayText.implicitHeight + Appearance.padding.small * 2

                                StyledText {
                                    id: dayText
                                    anchors.centerIn: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    text: calGrid.locale.toString(dayCell.model.day)
                                    color: {
                                        const dow = dayCell.model.date.getUTCDay();
                                        return (dow === 0 || dow === 6)
                                            ? Colours.palette.m3secondary
                                            : Colours.palette.m3onSurfaceVariant;
                                    }
                                    opacity: dayCell.model.today || dayCell.model.month === calGrid.month ? 1 : 0.4
                                    font.pointSize: Appearance.font.size.normal
                                    font.weight: 500
                                }
                            }
                        }

                        StyledRect {
                            id: todayIndicator
                            readonly property Item todayItem: calGrid.contentItem.children.find(c => c.model?.today) ?? null
                            property Item today

                            onTodayItemChanged: {
                                if (todayItem)
                                    today = todayItem;
                            }

                            x: today ? today.x + (today.width  - implicitWidth)  / 2 : 0
                            y: today ? today.y + (today.height - implicitHeight) / 2 : 0

                            implicitWidth:  today?.implicitWidth  ?? 0
                            implicitHeight: today?.implicitHeight ?? 0

                            clip: true
                            radius: Appearance.rounding.full
                            color: Colours.palette.m3primary

                            opacity: todayItem ? 1 : 0
                            scale:   todayItem ? 1 : 0.7

                            Colouriser {
                                x: -todayIndicator.x
                                y: -todayIndicator.y
                                implicitWidth:  calGrid.width
                                implicitHeight: calGrid.height
                                source:            calGrid
                                sourceColor:       Colours.palette.m3onSurface
                                colorizationColor: Colours.palette.m3onPrimary
                            }

                            Behavior on opacity { Anim {} }
                            Behavior on scale   { Anim {} }
                            Behavior on x { Anim {} }
                            Behavior on y { Anim {} }
                        }
                    }
                }
            }
        }

        // ── Media card ────────────────────────────────────────────────────────
        Card {
            id: mediaCard
            Layout.fillWidth: true
            implicitHeight: mediaInner.implicitHeight + Appearance.padding.large * 2

            property real playerProgress: {
                const a = Players.active;
                return a?.length ? a.position / a.length : 0;
            }
            function lengthStr(t: int): string {
                if (t < 0) return "--:--";
                const m = Math.floor(t / 60);
                const s = Math.floor(t % 60).toString().padStart(2, "0");
                return `${m}:${s}`;
            }
            Behavior on playerProgress { Anim { duration: Appearance.anim.durations.large } }

            Timer {
                running: Players.active?.isPlaying ?? false
                interval: Config.dashboard.mediaUpdateInterval
                repeat: true; triggeredOnStart: true
                onTriggered: Players.active?.positionChanged()
            }
            ServiceRef { service: Audio.cava }
            ServiceRef { service: Audio.beatTracker }

            RowLayout {
                id: mediaInner
                anchors.left:    parent.left
                anchors.right:   parent.right
                anchors.top:     parent.top
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.normal

                // Cover + progress arc
                Item {
                    id: arcItem
                    implicitWidth:  coverSize + progressThickness * 2 + Appearance.spacing.small * 2
                    implicitHeight: implicitWidth

                    readonly property int coverSize: Config.dashboard.sizes.mediaCoverArtSize * 0.55
                    readonly property int progressThickness: Config.dashboard.sizes.mediaProgressThickness

                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: Colours.palette.m3surfaceContainerHigh
                            strokeWidth: arcItem.progressThickness
                            capStyle: Appearance.rounding.scale === 0 ? ShapePath.SquareCap : ShapePath.RoundCap
                            PathAngleArc {
                                centerX: arcItem.width / 2
                                centerY: arcItem.height / 2
                                radiusX: arcItem.coverSize / 2 + arcItem.progressThickness / 2 + Appearance.spacing.small
                                radiusY: radiusX
                                startAngle: -90
                                sweepAngle: 360
                            }
                        }
                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: Colours.palette.m3primary
                            strokeWidth: arcItem.progressThickness
                            capStyle: Appearance.rounding.scale === 0 ? ShapePath.SquareCap : ShapePath.RoundCap
                            PathAngleArc {
                                centerX: arcItem.width / 2
                                centerY: arcItem.height / 2
                                radiusX: arcItem.coverSize / 2 + arcItem.progressThickness / 2 + Appearance.spacing.small
                                radiusY: radiusX
                                startAngle: -90
                                sweepAngle: 360 * mediaCard.playerProgress
                            }
                            Behavior on strokeColor { CAnim {} }
                        }
                    }

                    StyledClippingRect {
                        anchors.centerIn: parent
                        implicitWidth:  parent.coverSize
                        implicitHeight: parent.coverSize
                        radius: Infinity
                        color: Colours.palette.m3surfaceContainerHigh

                        MaterialIcon {
                            anchors.centerIn: parent
                            grade: 200; text: "art_track"
                            color: Colours.palette.m3onSurfaceVariant
                            font.pointSize: (parent.width * 0.4) || 1
                        }
                        Image {
                            anchors.fill: parent
                            source: Players.active?.trackArtUrl ?? ""
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: width; sourceSize.height: height
                        }
                    }
                }

                // Track info + controls
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        animate: true
                        text: (Players.active?.trackTitle ?? qsTr("No media")) || qsTr("Unknown title")
                        color: Players.active ? Colours.palette.m3primary : Colours.palette.m3onSurface
                        font.pointSize: Appearance.font.size.normal
                        font.weight: 500
                        elide: Text.ElideRight
                    }
                    StyledText {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        animate: true
                        visible: !!Players.active
                        text: Players.active?.trackAlbum || qsTr("Unknown album")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                        elide: Text.ElideRight
                    }
                    StyledText {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        animate: true
                        text: (Players.active?.trackArtist ?? qsTr("Play some music!")) || qsTr("Unknown artist")
                        color: Players.active ? Colours.palette.m3secondary : Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                        elide: Text.ElideRight
                    }

                    // Controls row
                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Appearance.spacing.small
                        MediaControl {
                            icon: "skip_previous"
                            canUse: Players.active?.canGoPrevious ?? false
                            onClicked: Players.active?.previous()
                        }
                        MediaControl {
                            icon: Players.active?.isPlaying ? "pause" : "play_arrow"
                            canUse: Players.active?.canTogglePlaying ?? false
                            onClicked: Players.active?.togglePlaying()
                        }
                        MediaControl {
                            icon: "skip_next"
                            canUse: Players.active?.canGoNext ?? false
                            onClicked: Players.active?.next()
                        }
                    }
                }

                // Bongo cat — right of text column, nudged left
                AnimatedImage {
                    Layout.preferredWidth:  90
                    Layout.preferredHeight: 90
                    Layout.maximumWidth:    90
                    Layout.maximumHeight:   90
                    Layout.rightMargin:     Appearance.spacing.large
                    Layout.alignment:       Qt.AlignVCenter
                    playing:  Players.active?.isPlaying ?? false
                    speed:    Audio.beatTracker.bpm / 300
                    source:   Paths.absolutePath(Config.paths.mediaGif)
                    asynchronous: true
                    fillMode: AnimatedImage.PreserveAspectFit
                }

            }
        }

        // ── Frequent apps card ─────────────────────────────────────────────
        Card {
            id: frequentCard
            Layout.fillWidth: true

            // Own AppDb instance — reads the same sqlite as the launcher
            AppDb {
                id: freqDb
                path: `${Paths.state}/apps.sqlite`
                entries: DesktopEntries.applications.values
            }

            // How many icons fit per row
            readonly property int iconSize:    48
            readonly property int iconPad:     Appearance.padding.large
            readonly property int cols:        Math.floor((frequentCard.width - iconPad * 2 + Appearance.spacing.normal)
                                                           / (iconSize + Appearance.spacing.normal))
            readonly property int rows:        2
            readonly property int shown:       cols * rows
            readonly property var topApps:     freqDb.apps.slice(0, shown)

            implicitHeight: iconPad * 2 + iconSize * rows + Appearance.spacing.normal * (rows - 1)

            Grid {
                anchors.centerIn: parent
                columns:  frequentCard.cols
                rows:     frequentCard.rows
                spacing:  Appearance.spacing.normal

                Repeater {
                    model: frequentCard.topApps
                    delegate: Item {
                        id: appIconItem
                        required property var modelData
                        implicitWidth:  frequentCard.iconSize
                        implicitHeight: frequentCard.iconSize

                        StateLayer {
                            radius: Appearance.rounding.normal
                            function onClicked(): void {
                                Quickshell.execDetached({
                                    command: ["app2unit", "--", ...appIconItem.modelData.entry.command]
                                })
                            }
                        }

                        IconImage {
                            anchors.centerIn: parent
                            source: Quickshell.iconPath(appIconItem.modelData.entry?.icon ?? "", "image-missing")
                            implicitSize: frequentCard.iconSize * 0.78
                        }
                    }
                }
            }
        }

        // ── Performance card ──────────────────────────────────────────────────
        Card {
            Layout.fillWidth: true
            implicitHeight: perfInner.implicitHeight + Appearance.padding.large * 2

            Ref { service: SystemUsage }

            function displayTemp(t: real): string {
                return `${Math.ceil(Config.services.useFahrenheit ? t * 1.8 + 32 : t)}°${Config.services.useFahrenheit ? "F" : "C"}`;
            }

            ColumnLayout {
                id: perfInner
                anchors.left:    parent.left
                anchors.right:   parent.right
                anchors.top:     parent.top
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.normal

                StyledText {
                    text: qsTr("Performance")
                    font.weight: 600
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3outline
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 0.8
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Appearance.spacing.large

                    PerfGauge {
                        val1:  Math.min(1, SystemUsage.gpuTemp / 90)
                        val2:  SystemUsage.gpuPerc
                        lbl1:  perfCard.displayTemp(SystemUsage.gpuTemp)
                        lbl2:  `${Math.round(SystemUsage.gpuPerc * 100)}%`
                        sub1:  qsTr("GPU temp")
                        sub2:  qsTr("Usage")
                    }
                    PerfGauge {
                        primary: true
                        val1:  Math.min(1, SystemUsage.cpuTemp / 90)
                        val2:  SystemUsage.cpuPerc
                        lbl1:  perfCard.displayTemp(SystemUsage.cpuTemp)
                        lbl2:  `${Math.round(SystemUsage.cpuPerc * 100)}%`
                        sub1:  qsTr("CPU temp")
                        sub2:  qsTr("Usage")
                    }
                    PerfGauge {
                        val1:  SystemUsage.memPerc
                        val2:  SystemUsage.storagePerc
                        lbl1: {
                            const f = SystemUsage.formatKib(SystemUsage.memUsed);
                            return `${+f.value.toFixed(1)}${f.unit}`;
                        }
                        lbl2: {
                            const f = SystemUsage.formatKib(SystemUsage.storageUsed);
                            return `${Math.floor(f.value)}${f.unit}`;
                        }
                        sub1: qsTr("Memory")
                        sub2: qsTr("Storage")
                    }
                }

            }
            id: perfCard
        }

        // Bottom padding so content doesn't sit flush against the panel edge
        Item { Layout.preferredHeight: Appearance.padding.large }
    }

    // ── Sub-components ────────────────────────────────────────────────────────

    component Card: StyledRect {
        radius: Appearance.rounding.small
        color:  Colours.palette.m3surfaceContainer
    }

    component InfoLine: Item {
        id: il
        property bool   isIcon:   true
        property string iconMat:  ""
        property string iconSrc:  ""
        property string txt:      ""
        property color  clr:      Colours.palette.m3primary

        implicitWidth:  ilIcon.implicitWidth + ilText.implicitWidth + Appearance.spacing.small
        implicitHeight: Math.max(ilIcon.implicitHeight, ilText.implicitHeight)

        Loader {
            id: ilIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            sourceComponent: il.isIcon ? matComp : colComp
            Component {
                id: matComp
                MaterialIcon {
                    fill: 1; text: il.iconMat; color: il.clr
                    font.pointSize: Appearance.font.size.normal
                }
            }
            Component {
                id: colComp
                ColouredIcon {
                    source: il.iconSrc
                    implicitSize: Math.floor(Appearance.font.size.normal * 1.34)
                    colour: il.clr
                }
            }
        }

        StyledText {
            id: ilText
            anchors.left: ilIcon.right
            anchors.leftMargin: Appearance.spacing.small
            anchors.verticalCenter: parent.verticalCenter
            text: il.txt
            color: il.clr
            font.pointSize: Appearance.font.size.normal
            elide: Text.ElideRight
            width: root.sidebarWidth - 56 - Appearance.padding.large * 4 - Appearance.spacing.small
        }
    }

    component MediaControl: StyledRect {
        id: mc
        required property string icon
        required property bool   canUse
        signal clicked()

        implicitWidth:  implicitHeight
        implicitHeight: mcIcon.implicitHeight + Appearance.padding.small

        StateLayer {
            disabled: !mc.canUse
            radius: Appearance.rounding.full
            function onClicked(): void { if (mc.canUse) mc.clicked(); }
        }
        MaterialIcon {
            id: mcIcon
            anchors.centerIn: parent
            animate: true
            text:  mc.icon
            color: mc.canUse ? Colours.palette.m3onSurface : Colours.palette.m3outline
            font.pointSize: Appearance.font.size.large
        }
    }

    component PerfGauge: Column {
        id: pg
        required property real   val1
        required property real   val2
        required property string lbl1
        required property string lbl2
        required property string sub1
        required property string sub2
        property bool primary: false

        readonly property real mult:      primary ? 1.15 : 1
        readonly property real thickness: Config.dashboard.sizes.resourceProgessThickness * mult

        readonly property real arcStart: 45.0
        readonly property real arcSweep: 315.0

        spacing: Appearance.spacing.small

        Item {
            id: gaugeItem
            implicitWidth:  Config.dashboard.sizes.resourceSize * pg.mult * 0.51
            implicitHeight: Config.dashboard.sizes.resourceSize * pg.mult * 0.51
            anchors.horizontalCenter: parent.horizontalCenter

            Column {
                anchors.centerIn: parent
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: pg.lbl1
                    font.pointSize: Appearance.font.size.large * pg.mult * 0.6
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: pg.sub1
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.smaller * pg.mult * 0.6
                }
            }

            Shape {
                id: pgShape
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                readonly property real arcRadius: (Math.min(width, height) - pg.thickness) / 2
                readonly property real arcCx: width  / 2
                readonly property real arcCy: height / 2

                ShapePath {
                    fillColor:   "transparent"
                    strokeColor: Colours.palette.m3primaryContainer
                    strokeWidth: pg.thickness
                    capStyle: Appearance.rounding.scale === 0 ? ShapePath.SquareCap : ShapePath.RoundCap
                    PathAngleArc {
                        centerX: pgShape.arcCx;     centerY: pgShape.arcCy
                        radiusX: pgShape.arcRadius; radiusY: pgShape.arcRadius
                        startAngle: pg.arcStart
                        sweepAngle: pg.arcSweep
                    }
                }
                ShapePath {
                    fillColor:   "transparent"
                    strokeColor: Colours.palette.m3primary
                    strokeWidth: pg.thickness
                    capStyle: Appearance.rounding.scale === 0 ? ShapePath.SquareCap : ShapePath.RoundCap
                    PathAngleArc {
                        centerX: pgShape.arcCx;     centerY: pgShape.arcCy
                        radiusX: pgShape.arcRadius; radiusY: pgShape.arcRadius
                        startAngle: pg.arcStart
                        sweepAngle: pg.arcSweep * pg.val1
                    }
                    Behavior on strokeColor { CAnim {} }
                }
            }

            Behavior on implicitWidth  { Anim {} }
            Behavior on implicitHeight { Anim {} }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 1
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: pg.lbl2
                font.pointSize: Appearance.font.size.tiny * pg.mult
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: pg.sub2
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.tiny * pg.mult
            }
        }

        Behavior on val1 { Anim {} }
        Behavior on val2 { Anim {} }
    }

    component ResBar: Item {
        id: rb
        required property string icon
        required property real   value
        required property color  colour

        implicitWidth:  rbIcon.implicitWidth
        Layout.fillWidth: true
        implicitHeight: 60

        StyledRect {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top:    parent.top
            anchors.bottom: rbIcon.top
            anchors.bottomMargin: Appearance.spacing.small
            implicitWidth: Config.dashboard.sizes.resourceProgessThickness
            radius: Appearance.rounding.full
            color: Colours.palette.m3surfaceContainerHigh
            StyledRect {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                implicitHeight: rb.value * parent.height
                radius: Appearance.rounding.full
                color: rb.colour
            }
        }
        MaterialIcon {
            id: rbIcon
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            text: rb.icon; color: rb.colour
        }
        Behavior on value { Anim { duration: Appearance.anim.durations.large } }
    }

    component Anim: NumberAnimation {
        duration:    Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}

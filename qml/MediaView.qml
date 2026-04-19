import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property color cBg: "#111111"
    property color cFg: "white"
    property color cAccent: cFg
    property color cMuted: "#888888"
    property color cSecondary: cMuted
    property color cBorder: "#444444"
    property color cPrimary: cBorder
    property int cBorderWidth: 2
    property string cFont: "sans"
    property string cNerdFont: "JetBrainsMono Nerd Font"
    property int cFontSize: 16
    property color innerBorderColor: cMuted
    property bool active: true

    property int sectionGap: 12
    property int sectionPadding: 16
    property int sectionRadius: 8
    property int buttonSize: 42
    property int artworkSize: 110
    property int titleTruncationInset: 20
    property real hoverScale: 1.1
    property int hoverAnimMs: 140
    property int artworkSpinDurationMs: 12000
    property int nonSpotifyArtworkRadius: 8
    property real nonSpotifyArtworkScale: 0.9
    property string spinMediaIdentity: ""
    property bool spotifyMedia: MediaInfo.hasMedia
                              && MediaInfo.playerName.toLowerCase().indexOf("spotify") !== -1
    property bool circularArtwork: root.spotifyMedia || !MediaInfo.hasMedia
    property bool spinRunning: root.active && root.spotifyMedia && MediaInfo.status === "Playing"
    property bool seekVisualLock: false
    property real lastBackendPositionSeconds: 0
    property double lastBackendSyncMs: Date.now()
    property int playbackTick: 0
    property int visualizerBarCount: 32
    property real visualizerOpacity: 0.1
    property bool visualizerEnabled: true
    property real visualizerPausedFloor: 0.08
    property int visualizerPauseDebounceMs: 200
    property int visualizerPositionGraceMs: 900
    property real visualizerPositionAdvanceThresholdSeconds: 0.08
    property real visualizerPhase: 0
    property int visualizerPhaseDurationMs: 3000
    property int visualizerPhaseTickMs: 16
    property double visualizerLastTickMs: 0
    property int visualizerPhaseLoopCycles: 3600
    readonly property real visualizerPhaseLoopSpan: (Math.PI * 2) * root.visualizerPhaseLoopCycles
    readonly property int visualizerPhaseLoopDurationMs: Math.max(1, root.visualizerPhaseDurationMs * root.visualizerPhaseLoopCycles)
    readonly property bool visualizerPhaseActive: root.active
        && root.visualizerEnabled
        && MediaInfo.hasMedia
    readonly property bool visualizerPlayingLive: root.active
        && root.visualizerEnabled
        && MediaInfo.hasMedia
        && MediaInfo.status === "Playing"
    property bool visualizerPlaying: visualizerPlayingLive
    property real visualizerEnergy: root.visualizerPlaying ? 1.0 : 0.0
    property double visualizerLastPositionAdvanceMs: 0
    property real visualPlaybackPositionSeconds: {
        const _tick = playbackTick
        const backendPosition = Math.min(MediaInfo.positionSeconds, progressSlider.to)
        if (!MediaInfo.hasMedia) {
            return 0
        }
        if (MediaInfo.status !== "Playing") {
            return backendPosition
        }
        const elapsedSeconds = Math.max(0, (Date.now() - lastBackendSyncMs) / 1000.0)
        return Math.max(0, Math.min(progressSlider.to, lastBackendPositionSeconds + elapsedSeconds))
    }

    function formatTime(seconds) {
        const total = Math.max(0, Math.floor(seconds))
        const hh = Math.floor(total / 3600)
        const mm = Math.floor((total % 3600) / 60)
        const ss = total % 60
        const mmStr = mm < 10 ? "0" + mm : "" + mm
        const ssStr = ss < 10 ? "0" + ss : "" + ss
        if (hh > 0) {
            const hhStr = hh < 10 ? "0" + hh : "" + hh
            return hhStr + ":" + mmStr + ":" + ssStr
        }
        return mmStr + ":" + ssStr
    }

    function currentMediaIdentity() {
        if (!MediaInfo.hasMedia) {
            return ""
        }
        return MediaInfo.playerName + "|" + MediaInfo.title + "|" + MediaInfo.artist + "|" + MediaInfo.artUrl
    }

    function mixColors(fromColor, toColor, amount) {
        return Qt.rgba(
            fromColor.r + (toColor.r - fromColor.r) * amount,
            fromColor.g + (toColor.g - fromColor.g) * amount,
            fromColor.b + (toColor.b - fromColor.b) * amount,
            1
        )
    }

    Behavior on visualizerEnergy {
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: visualizerPauseDebounceTimer
        interval: Math.max(0, root.visualizerPauseDebounceMs)
        repeat: false
        onTriggered: {
            if (root.shouldVisualizerKeepPlaying()) {
                if (!root.visualizerPlayingLive) {
                    visualizerPauseDebounceTimer.start()
                }
                return
            }
            root.visualizerPlaying = false
        }
    }

    Timer {
        id: visualizerPhaseTimer
        interval: Math.max(1, root.visualizerPhaseTickMs)
        repeat: true
        running: root.visualizerPhaseActive
        onRunningChanged: {
            if (!running) {
                root.visualizerLastTickMs = 0
            }
        }
        onTriggered: {
            const nowMs = Date.now()
            if (root.visualizerLastTickMs <= 0) {
                root.visualizerLastTickMs = nowMs
                return
            }

            const elapsedMs = Math.max(0, nowMs - root.visualizerLastTickMs)
            root.visualizerLastTickMs = nowMs
            const phaseStep = (root.visualizerPhaseLoopSpan * elapsedMs) / Math.max(1, root.visualizerPhaseLoopDurationMs)
            const nextPhase = root.visualizerPhase + phaseStep
            root.visualizerPhase = nextPhase >= root.visualizerPhaseLoopSpan
                ? nextPhase % root.visualizerPhaseLoopSpan
                : nextPhase
        }
    }

    Timer {
        id: seekVisualLockTimer
        interval: 1200
        repeat: false
        onTriggered: root.seekVisualLock = false
    }

    Timer {
        id: playbackTickTimer
        interval: 200
        repeat: true
        running: root.active
            && MediaInfo.hasMedia
            && MediaInfo.status === "Playing"
            && !progressSlider.pressed
            && !root.seekVisualLock
        onTriggered: root.playbackTick += 1
    }

    Connections {
        target: MediaInfo

        function onMediaChanged() {
            const nowMs = Date.now()
            const backendPosition = Math.min(MediaInfo.positionSeconds, progressSlider.to)
            if ((backendPosition - root.lastBackendPositionSeconds) > root.visualizerPositionAdvanceThresholdSeconds) {
                root.visualizerLastPositionAdvanceMs = nowMs
            }
            if (root.visualizerPlayingLive) {
                root.visualizerLastPositionAdvanceMs = nowMs
            }

            root.syncVisualizerPlayingState()

            root.lastBackendPositionSeconds = backendPosition
            root.lastBackendSyncMs = nowMs

            if (!root.spotifyMedia) {
                root.spinMediaIdentity = ""
                artworkSpinLayer.rotation = 0
            } else {
                const nextIdentity = root.currentMediaIdentity()
                if (nextIdentity !== root.spinMediaIdentity) {
                    root.spinMediaIdentity = nextIdentity
                    artworkSpinLayer.rotation = 0
                }
            }

            if (!root.seekVisualLock) {
                return
            }

            if (Math.abs(backendPosition - progressSlider.value) <= 0.45) {
                root.seekVisualLock = false
                seekVisualLockTimer.stop()
            }
        }
    }

    function shouldVisualizerKeepPlaying() {
        if (root.visualizerPlayingLive) {
            return true
        }

        if (!root.active || !root.visualizerEnabled || !MediaInfo.hasMedia) {
            return false
        }

        if (root.visualizerLastPositionAdvanceMs <= 0) {
            return false
        }

        return (Date.now() - root.visualizerLastPositionAdvanceMs) <= Math.max(0, root.visualizerPositionGraceMs)
    }

    function syncVisualizerPlayingState() {
        if (root.visualizerPlayingLive) {
            root.visualizerLastPositionAdvanceMs = Date.now()
            visualizerPauseDebounceTimer.stop()
            root.visualizerPlaying = true
            return
        }

        if (!root.active || !root.visualizerEnabled || !MediaInfo.hasMedia || root.visualizerPauseDebounceMs <= 0) {
            visualizerPauseDebounceTimer.stop()
            root.visualizerPlaying = false
            return
        }

        if (root.shouldVisualizerKeepPlaying()) {
            root.visualizerPlaying = true
        }

        if (!visualizerPauseDebounceTimer.running) {
            visualizerPauseDebounceTimer.start()
        }
    }

    onVisualizerPlayingLiveChanged: syncVisualizerPlayingState()
    onActiveChanged: syncVisualizerPlayingState()
    onVisualizerEnabledChanged: syncVisualizerPlayingState()
    Component.onCompleted: syncVisualizerPlayingState()

    Rectangle {
        id: panelBorder
        anchors.fill: parent
        radius: root.sectionRadius
        color: "transparent"
        border.width: root.cBorderWidth
        border.color: root.innerBorderColor
        z: 2
    }

    Item {
        id: visualizerLayer
        anchors.fill: parent
        anchors.margins: root.cBorderWidth
        clip: true
        visible: root.visualizerEnabled && MediaInfo.hasMedia
        opacity: root.visualizerOpacity
        z: 0

        Rectangle {
            anchors.fill: parent
            radius: Math.max(0, root.sectionRadius - root.cBorderWidth)
            color: Qt.rgba(root.cBg.r, root.cBg.g, root.cBg.b, 0.2)
        }

        Row {
            id: visualizerRow
            anchors.fill: parent
            anchors.leftMargin: root.sectionPadding * 0.5
            anchors.rightMargin: root.sectionPadding * 0.5
            anchors.topMargin: root.sectionPadding * 0.35
            anchors.bottomMargin: root.sectionPadding * 0.35
            spacing: 3

            Repeater {
                model: root.visualizerBarCount

                Item {
                    required property int index
                    width: (visualizerRow.width - (visualizerRow.spacing * (root.visualizerBarCount - 1))) / root.visualizerBarCount
                    height: visualizerRow.height

                    Rectangle {
                        width: parent.width
                        height: {
                            const indexPhase = parent.index
                            const phase = root.visualizerPhase
                            const normalizedIndex = indexPhase / Math.max(1, root.visualizerBarCount - 1)
                            const waveA = 0.5 + (0.5 * Math.sin((indexPhase * 0.41) + (phase * (1.05 + (normalizedIndex * 0.72)))))
                            const waveB = 0.5 + (0.5 * Math.sin((indexPhase * 0.17) - (phase * (1.58 + (normalizedIndex * 0.48)))))
                            const ripple = 0.5 + (0.5 * Math.sin((indexPhase * 1.23) + (phase * 2.47)))
                            const travelPhase = ((phase * (0.22 + (normalizedIndex * 0.09))) + (indexPhase * 0.6)) / (Math.PI * 2)
                            const travelFrac = travelPhase - Math.floor(travelPhase)
                            const travel = 1.0 - Math.abs((travelFrac * 2.0) - 1.0)
                            const dynamicLevel = 0.12 + (waveA * 0.33) + (waveB * 0.22) + (ripple * 0.2) + (travel * 0.11)
                            const mixedLevel = root.visualizerPausedFloor + ((dynamicLevel - root.visualizerPausedFloor) * root.visualizerEnergy)
                            const clamped = Math.max(root.visualizerPausedFloor, Math.min(0.96, mixedLevel))
                            return Math.max(2, parent.height * clamped)
                        }
                        anchors.bottom: parent.bottom
                        radius: 0
                        color: {
                            const mixed = root.mixColors(root.cAccent, root.cSecondary, parent.index / Math.max(1, root.visualizerBarCount - 1))
                            return Qt.rgba(mixed.r, mixed.g, mixed.b, 0.95)
                        }
                    }
                }
            }
        }
    }

    ToolButton {
        id: visualizerToggleButton
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: root.cBorderWidth + 6
        anchors.rightMargin: root.cBorderWidth + 8
        z: 3
        hoverEnabled: true
        onClicked: root.visualizerEnabled = !root.visualizerEnabled

        contentItem: Item {
            implicitWidth: 18
            implicitHeight: 18

            Text {
                anchors.centerIn: parent
                text: "≋"
                color: root.cMuted
                font.family: root.cFont
                font.pixelSize: root.cFontSize * 0.9
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                anchors.centerIn: parent
                visible: !root.visualizerEnabled
                text: "/"
                color: root.cMuted
                font.family: root.cFont
                font.pixelSize: root.cFontSize * 1.25
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        background: Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: 14
            color: Qt.rgba(root.cMuted.r, root.cMuted.g, root.cMuted.b, visualizerToggleButton.hovered ? 0.14 : 0.08)
            border.width: 1
            border.color: Qt.rgba(root.cMuted.r, root.cMuted.g, root.cMuted.b, visualizerToggleButton.hovered ? 0.5 : 0.35)
        }
    }

    ColumnLayout {
        z: 1
        anchors.fill: parent
        anchors.margins: root.sectionPadding
        spacing: root.sectionGap

        Item { Layout.fillHeight: true }

        ColumnLayout {
            id: mediaInfoColumn
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.max(320, Math.min(root.width - (root.sectionPadding * 2), 680))
            spacing: 8

            Rectangle {
                id: artworkDisc
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 3
                Layout.preferredWidth: root.artworkSize
                Layout.preferredHeight: root.artworkSize
                radius: root.circularArtwork ? width / 2 : root.nonSpotifyArtworkRadius
                color: "transparent"
                transformOrigin: Item.Center
                scale: (artworkHover.hovered ? root.hoverScale : 1.0) * (root.spotifyMedia ? 1.0 : root.nonSpotifyArtworkScale)
                z: artworkHover.hovered ? 1 : 0
                Behavior on scale {
                    NumberAnimation {
                        duration: root.hoverAnimMs
                        easing.type: Easing.OutCubic
                    }
                }

                HoverHandler {
                    id: artworkHover
                }

                Item {
                    id: artworkSpinLayer
                    anchors.fill: parent
                    anchors.margins: root.cBorderWidth
                    transformOrigin: Item.Center
                    rotation: 0
                    layer.enabled: root.spotifyMedia && MediaInfo.hasMedia
                    layer.smooth: true

                    RotationAnimator {
                        target: artworkSpinLayer
                        from: artworkSpinLayer.rotation
                        to: artworkSpinLayer.rotation + 360
                        duration: Math.max(1000, root.artworkSpinDurationMs)
                        loops: Animation.Infinite
                        running: root.spinRunning
                    }

                    Item {
                        id: artworkCircle
                        anchors.fill: parent

                        Image {
                            id: artworkImage
                            anchors.fill: parent
                            source: MediaInfo.artUrl
                            sourceSize.width: Math.round(root.artworkSize * 2)
                            sourceSize.height: Math.round(root.artworkSize * 2)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            visible: false
                        }

                        OpacityMask {
                            anchors.fill: parent
                            source: artworkImage
                            visible: MediaInfo.hasMedia && MediaInfo.artUrl.length > 0
                            cached: true
                            maskSource: Rectangle {
                                width: artworkCircle.width
                                height: artworkCircle.height
                                radius: root.circularArtwork ? width / 2 : root.nonSpotifyArtworkRadius
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !MediaInfo.hasMedia || MediaInfo.artUrl.length === 0
                        text: MediaInfo.isVideo ? "▣▶" : "♪"
                        color: root.cMuted
                        font.family: root.cFont
                        font.pixelSize: root.cFontSize * 1.35
                        font.bold: true
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: root.circularArtwork ? width / 2 : root.nonSpotifyArtworkRadius
                    color: "transparent"
                    border.width: Math.max(1, root.cBorderWidth)
                    border.color: root.cSecondary
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: root.titleTruncationInset
                Layout.rightMargin: root.titleTruncationInset
                text: MediaInfo.hasMedia
                    ? (MediaInfo.title.length ? MediaInfo.title : "No title")
                    : "No media playing"
                horizontalAlignment: Text.AlignHCenter
                color: root.cFg
                font.family: root.cFont
                font.pixelSize: root.cFontSize * 1.15
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 5
                text: MediaInfo.hasMedia
                    ? (MediaInfo.artist.length ? MediaInfo.artist : "Unknown artist")
                    : "It's quiet…"
                horizontalAlignment: Text.AlignHCenter
                color: root.cSecondary
                font.family: root.cFont
                font.pixelSize: root.cFontSize
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            id: mediaControlsColumn
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: mediaInfoColumn.Layout.preferredWidth
            spacing: 10

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 2
                spacing: 10

                Button {
                    text: "󰒮"
                    enabled: MediaInfo.hasMedia
                    hoverEnabled: true
                    HoverHandler {
                        cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }
                    transformOrigin: Item.Center
                    scale: hovered ? 1.2 : 1.0
                    z: hovered ? 1 : 0
                    Behavior on scale {
                        NumberAnimation {
                            duration: root.hoverAnimMs
                            easing.type: Easing.OutCubic
                        }
                    }
                    onClicked: MediaInfo.previous()

                    contentItem: Text {
                        text: parent.text
                        color: parent.enabled ? root.cAccent : root.cMuted
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: root.cNerdFont
                        font.pixelSize: root.cFontSize * 1.5
                    }

                    background: Rectangle {
                        implicitWidth: root.buttonSize
                        implicitHeight: root.buttonSize
                        radius: root.sectionRadius
                        color: "transparent"
                        border.width: 0
                        opacity: parent.enabled ? 1.0 : 0.55
                    }
                }

                Button {
                    text: ""
                    enabled: MediaInfo.hasMedia
                    hoverEnabled: true
                    HoverHandler {
                        cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }
                    transformOrigin: Item.Center
                    scale: hovered ? 1.2 : 1.0
                    z: hovered ? 1 : 0
                    Behavior on scale {
                        NumberAnimation {
                            duration: root.hoverAnimMs
                            easing.type: Easing.OutCubic
                        }
                    }
                    onClicked: MediaInfo.seekRelative(-10)
                    leftPadding: 0
                    rightPadding: 8

                    contentItem: Text {
                        text: parent.text
                        color: parent.enabled ? root.cAccent : root.cMuted
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: root.cNerdFont
                        font.pixelSize: root.cFontSize
                    }

                    background: Rectangle {
                        implicitWidth: root.buttonSize
                        implicitHeight: root.buttonSize
                        radius: root.sectionRadius
                        color: "transparent"
                        border.width: 0
                        opacity: parent.enabled ? 1.0 : 0.55
                    }
                }

                Button {
                    id: playPauseButton
                    text: MediaInfo.status === "Playing" ? "⏸" : "▶"
                    enabled: MediaInfo.hasMedia
                    hoverEnabled: true
                    HoverHandler {
                        cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }
                    transformOrigin: Item.Center
                    scale: hovered ? 1.1 : 1.0
                    z: hovered ? 1 : 0
                    Behavior on scale {
                        NumberAnimation {
                            duration: root.hoverAnimMs
                            easing.type: Easing.OutCubic
                        }
                    }
                    onClicked: MediaInfo.playPause()

                    contentItem: Text {
                        text: playPauseButton.text
                        color: playPauseButton.enabled ? root.cFg : root.cMuted
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        transform: Translate { x: playPauseButton.text === "▶" ? 1 : 0 }
                        font.family: root.cNerdFont
                        font.pixelSize: root.cFontSize * 1.5
                    }

                    background: Rectangle {
                        implicitWidth: root.buttonSize
                        implicitHeight: root.buttonSize
                        radius: width / 2
                        color: Qt.rgba(root.cMuted.r, root.cMuted.g, root.cMuted.b, 1.0)
                        border.width: root.cBorderWidth
                        border.color: root.cBorder
                        opacity: 1.0
                    }
                }

                Button {
                    text: ""
                    enabled: MediaInfo.hasMedia
                    hoverEnabled: true
                    HoverHandler {
                        cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }
                    transformOrigin: Item.Center
                    scale: hovered ? 1.2 : 1.0
                    z: hovered ? 1 : 0
                    Behavior on scale {
                        NumberAnimation {
                            duration: root.hoverAnimMs
                            easing.type: Easing.OutCubic
                        }
                    }
                    onClicked: MediaInfo.seekRelative(10)
                    rightPadding: 5

                    contentItem: Text {
                        text: parent.text
                        color: parent.enabled ? root.cAccent : root.cMuted
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: root.cNerdFont
                        font.pixelSize: root.cFontSize
                    }

                    background: Rectangle {
                        implicitWidth: root.buttonSize
                        implicitHeight: root.buttonSize
                        radius: root.sectionRadius
                        color: "transparent"
                        border.width: 0
                        opacity: parent.enabled ? 1.0 : 0.55
                    }
                }

                Button {
                    text: "󰒭"
                    enabled: MediaInfo.hasMedia
                    hoverEnabled: true
                    HoverHandler {
                        cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }
                    transformOrigin: Item.Center
                    scale: hovered ? 1.2 : 1.0
                    z: hovered ? 1 : 0
                    Behavior on scale {
                        NumberAnimation {
                            duration: root.hoverAnimMs
                            easing.type: Easing.OutCubic
                        }
                    }
                    onClicked: MediaInfo.next()

                    contentItem: Text {
                        text: parent.text
                        color: parent.enabled ? root.cAccent : root.cMuted
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: root.cNerdFont
                        font.pixelSize: root.cFontSize * 1.5
                    }

                    background: Rectangle {
                        implicitWidth: root.buttonSize
                        implicitHeight: root.buttonSize
                        radius: root.sectionRadius
                        color: "transparent"
                        border.width: 0
                        opacity: parent.enabled ? 1.0 : 0.55
                    }
                }
            }

            Slider {
                id: progressSlider
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.leftMargin: 75
                Layout.rightMargin: 75
                Layout.topMargin: 15
                Layout.minimumWidth: 240
                hoverEnabled: true
                from: 0
                to: Math.max(1, MediaInfo.lengthSeconds)
                enabled: MediaInfo.hasMedia && MediaInfo.lengthSeconds > 0
                value: (pressed || root.seekVisualLock) ? value : root.visualPlaybackPositionSeconds

                HoverHandler {
                    id: progressHover
                    cursorShape: progressSlider.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                }

                onMoved: {
                    if (to > 0) {
                        root.seekVisualLock = true
                        root.lastBackendPositionSeconds = value
                        root.lastBackendSyncMs = Date.now()
                        seekVisualLockTimer.restart()
                        MediaInfo.seekToRatio(value / to)
                    }
                }

                background: Rectangle {
                    implicitWidth: 260
                    implicitHeight: 6
                    radius: 3 * (progressHover.hovered ? 2.0 : 1.0)
                    color: Qt.rgba(root.cMuted.r, root.cMuted.g, root.cMuted.b, 0.8)
                    Behavior on radius {
                        NumberAnimation {
                            duration: root.hoverAnimMs
                            easing.type: Easing.OutCubic
                        }
                    }
                    transform: Scale {
                        origin.x: progressSlider.background.width / 2
                        origin.y: progressSlider.background.height / 2
                        yScale: progressHover.hovered ? 2.0 : 1.0
                        xScale: 1.0
                        Behavior on yScale {
                            NumberAnimation {
                                duration: root.hoverAnimMs
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Rectangle {
                        width: progressSlider.visualPosition * parent.width
                        height: parent.height
                        radius: parent.radius
                        color: root.cPrimary
                    }
                }

                handle: Rectangle {
                    implicitWidth: 0
                    implicitHeight: 0
                    color: "transparent"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 75
                Layout.rightMargin: 75
                Layout.topMargin: 0

                Text {
                    text: MediaInfo.hasMedia ? root.formatTime(root.visualPlaybackPositionSeconds) : "0:00"
                    color: root.cFg
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize * 0.82
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: MediaInfo.hasMedia ? root.formatTime(MediaInfo.lengthSeconds) : "0:00"
                    color: root.cFg
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize * 0.82
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: -6
                spacing: 10

                ComboBox {
                    id: playerSelector
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 0
                    Layout.preferredWidth: Math.round((root.buttonSize * 5 + 40) / 1.65)
                    model: MediaInfo.availablePlayerLabels
                    enabled: MediaInfo.availablePlayers.length > 0
                    currentIndex: -1
                    leftPadding: 12
                    rightPadding: 28
                    topPadding: 6
                    bottomPadding: 6

                    function syncSelectedPlayer() {
                        const selected = MediaInfo.selectedPlayer
                        for (let i = 0; i < MediaInfo.availablePlayers.length; ++i) {
                            if (MediaInfo.availablePlayers[i] === selected) {
                                currentIndex = i
                                return
                            }
                        }
                        currentIndex = -1
                    }

                    Component.onCompleted: syncSelectedPlayer()

                    Connections {
                        target: MediaInfo
                        function onMediaChanged() {
                            playerSelector.syncSelectedPlayer()
                        }
                    }

                    onActivated: (index) => {
                        if (index >= 0 && index < MediaInfo.availablePlayers.length) {
                            MediaInfo.selectPlayerAt(index)
                        }
                    }

                    contentItem: Item {
                        implicitHeight: labelRow.implicitHeight

                        Row {
                            id: labelRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: 1
                            spacing: 8

                            Text {
                                id: selectorGlyph
                                text: MediaInfo.availablePlayers.length > 0 ? "󰎈" : "󰎊"
                                color: playerSelector.enabled ? root.cFg : root.cMuted
                                font.family: root.cNerdFont
                                font.pixelSize: root.cFontSize * 0.92
                                verticalAlignment: Text.AlignVCenter
                                y: -2
                            }

                            Text {
                                width: Math.max(0, labelRow.width - selectorGlyph.implicitWidth - labelRow.spacing)
                                text: MediaInfo.availablePlayers.length > 0
                                    ? (playerSelector.currentText.length > 0 ? playerSelector.currentText : "Select player")
                                    : "No players"
                                color: playerSelector.enabled ? root.cFg : root.cMuted
                                font.family: root.cFont
                                font.pixelSize: root.cFontSize * 0.88
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                clip: true
                            }
                        }
                    }

                    indicator: Text {
                        x: playerSelector.width - width - 10
                        y: (playerSelector.height - height) / 2
                        text: "▾"
                        color: root.cMuted
                        font.family: root.cFont
                        font.pixelSize: root.cFontSize * 0.95
                    }

                    background: Rectangle {
                        implicitHeight: 34
                        radius: Math.round(implicitHeight / 2)
                        color: Qt.rgba(root.cMuted.r, root.cMuted.g, root.cMuted.b, 1.0)
                        border.width: root.cBorderWidth
                        border.color: root.cSecondary
                    }

                    popup: Popup {
                        y: playerSelector.height + 4
                        width: playerSelector.width
                        padding: 4
                        implicitHeight: contentItem.implicitHeight + 8

                        background: Rectangle {
                            radius: root.sectionRadius
                            color: Qt.rgba(root.cBg.r, root.cBg.g, root.cBg.b, 0.96)
                            border.width: root.cBorderWidth
                            border.color: root.cBorder
                        }

                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: playerSelector.popup.visible ? playerSelector.delegateModel : null
                        }
                    }

                    delegate: ItemDelegate {
                        width: playerSelector.width - 8
                        height: 32
                        text: modelData
                        highlighted: playerSelector.highlightedIndex === index

                        contentItem: Text {
                            text: parent.text
                            color: parent.highlighted ? root.cBg : root.cFg
                            font.family: root.cFont
                            font.pixelSize: root.cFontSize * 0.88
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        background: Rectangle {
                            radius: root.sectionRadius
                            border.width: 1
                            border.color: parent.highlighted
                                ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.95)
                                : Qt.rgba(root.cBorder.r, root.cBorder.g, root.cBorder.b, 0.65)
                            color: parent.highlighted
                                ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.95)
                                : Qt.rgba(root.cBg.r, root.cBg.g, root.cBg.b, 0.42)
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}

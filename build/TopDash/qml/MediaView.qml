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
        const lengthIdentity = Math.max(0, Math.round(MediaInfo.lengthSeconds))
        return MediaInfo.playerName + "|" + MediaInfo.title + "|" + MediaInfo.artist + "|" + MediaInfo.artUrl + "|" + lengthIdentity
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
            const backendPosition = Math.min(MediaInfo.positionSeconds, progressSlider.to)
            root.lastBackendPositionSeconds = backendPosition
            root.lastBackendSyncMs = Date.now()

            if (!root.spotifyMedia) {
                root.spinMediaIdentity = ""
                artworkDisc.rotation = 0
            } else {
                const nextIdentity = root.currentMediaIdentity()
                if (nextIdentity !== root.spinMediaIdentity) {
                    root.spinMediaIdentity = nextIdentity
                    artworkDisc.rotation = 0
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

    Rectangle {
        anchors.fill: parent
        radius: root.sectionRadius
        color: "transparent"
        border.width: root.cBorderWidth
        border.color: root.innerBorderColor
    }

    ColumnLayout {
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
                rotation: 0
                z: artworkHover.hovered ? 1 : 0
                Behavior on scale {
                    NumberAnimation {
                        duration: root.hoverAnimMs
                        easing.type: Easing.OutCubic
                    }
                }
                RotationAnimator {
                    target: artworkDisc
                    from: artworkDisc.rotation
                    to: artworkDisc.rotation + 360
                    duration: Math.max(1000, root.artworkSpinDurationMs)
                    loops: Animation.Infinite
                    running: root.spinRunning
                }

                HoverHandler {
                    id: artworkHover
                }

                Item {
                    id: artworkCircle
                    anchors.fill: parent
                    anchors.margins: root.cBorderWidth

                    Image {
                        id: artworkImage
                        anchors.fill: parent
                        source: MediaInfo.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: artworkImage
                        visible: MediaInfo.hasMedia && MediaInfo.artUrl.length > 0
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
                        color: "transparent"
                        border.width: root.cBorderWidth
                        border.color: root.cBorder
                        opacity: parent.enabled ? 1.0 : 0.55
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
                    color: Qt.rgba(root.cMuted.r, root.cMuted.g, root.cMuted.b, 0.35)
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
                    text: MediaInfo.hasMedia ? root.formatTime(root.visualPlaybackPositionSeconds) : "-1:-1"
                    color: root.cFg
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize * 0.82
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: MediaInfo.hasMedia ? root.formatTime(MediaInfo.lengthSeconds) : "-1:-1"
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
                        color: Qt.rgba(root.cMuted.r, root.cMuted.g, root.cMuted.b, 0.22)
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

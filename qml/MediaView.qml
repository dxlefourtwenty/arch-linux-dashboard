import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    property color cBg: "#111111"
    property color cFg: "white"
    property color cMuted: "#888888"
    property color cBorder: "#444444"
    property color cPrimary: cBorder
    property int cBorderWidth: 2
    property string cFont: "sans"
    property string cNerdFont: "JetBrainsMono Nerd Font"
    property int cFontSize: 16
    property color innerBorderColor: cMuted

    property int sectionGap: 12
    property int sectionPadding: 16
    property int sectionRadius: 8
    property int buttonSize: 42
    property int artworkSize: 92
    property int titleTruncationInset: 20
    property real hoverScale: 1.1
    property int hoverAnimMs: 140

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

    ColumnLayout {
        anchors.fill: parent
        spacing: root.sectionGap

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 1
            radius: root.sectionRadius
            color: "transparent"
            border.width: root.cBorderWidth
            border.color: root.innerBorderColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.sectionPadding
                spacing: 8

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: root.artworkSize
                    Layout.preferredHeight: root.artworkSize
                    radius: root.sectionRadius
                    color: "transparent"
                    clip: true
                    transformOrigin: Item.Center
                    scale: artworkHover.hovered ? root.hoverScale : 1.0
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

                    Image {
                        anchors.fill: parent
                        anchors.margins: root.cBorderWidth
                        visible: MediaInfo.hasMedia && MediaInfo.artUrl.length > 0
                        source: MediaInfo.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
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
                        radius: root.sectionRadius
                        color: "transparent"
                        border.width: Math.max(1, root.cBorderWidth)
                        border.color: root.innerBorderColor
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
                    text: MediaInfo.hasMedia
                        ? (MediaInfo.artist.length ? MediaInfo.artist : "Unknown artist")
                        : "It's quiet…"
                    horizontalAlignment: Text.AlignHCenter
                    color: root.cMuted
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: MediaInfo.hasMedia
                        ? (MediaInfo.playerName.length ? MediaInfo.playerName : "player") + " - " + MediaInfo.status
                        : ""
                    visible: MediaInfo.hasMedia
                    horizontalAlignment: Text.AlignHCenter
                    color: root.cMuted
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize * 0.92
                    elide: Text.ElideRight
                }

                Item { Layout.fillHeight: true }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 1
            radius: root.sectionRadius
            color: "transparent"
            border.width: root.cBorderWidth
            border.color: root.innerBorderColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.sectionPadding
                spacing: 10

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    Text {
                        text: MediaInfo.hasMedia ? root.formatTime(MediaInfo.positionSeconds) : "0:00"
                        color: root.cFg
                        font.family: root.cFont
                        font.pixelSize: root.cFontSize * 0.94
                    }

                    Text {
                        text: "/"
                        color: root.cMuted
                        font.family: root.cFont
                        font.pixelSize: root.cFontSize * 0.94
                    }

                    Text {
                        text: MediaInfo.hasMedia ? root.formatTime(MediaInfo.lengthSeconds) : "0:00"
                        color: root.cFg
                        font.family: root.cFont
                        font.pixelSize: root.cFontSize * 0.94
                    }
                }

                Slider {
                    id: progressSlider
                    Layout.fillWidth: true
                    Layout.maximumWidth: Math.max(240, root.width * 0.72)
                    Layout.alignment: Qt.AlignHCenter
                    from: 0
                    to: Math.max(1, MediaInfo.lengthSeconds)
                    enabled: MediaInfo.hasMedia && MediaInfo.lengthSeconds > 0
                    value: pressed ? value : Math.min(MediaInfo.positionSeconds, to)

                    onMoved: {
                        if (to > 0) {
                            MediaInfo.seekToRatio(value / to)
                        }
                    }

                    background: Rectangle {
                        implicitWidth: 260
                        implicitHeight: 8
                        radius: 0
                        color: root.cMuted
                        opacity: 0.2
                        border.width: root.cBorderWidth
                        border.color: root.cBorder

                        Rectangle {
                            width: progressSlider.visualPosition * parent.width
                            height: parent.height
                            color: root.cPrimary
                            opacity: 1.0
                        }
                    }

                    handle: Rectangle {
                        implicitWidth: 14
                        implicitHeight: 14
                        x: progressSlider.leftPadding + progressSlider.visualPosition * (progressSlider.availableWidth - width)
                        y: progressSlider.topPadding + (progressSlider.availableHeight - height) / 2
                        radius: 0
                        color: root.cPrimary
                        border.width: root.cBorderWidth
                        border.color: root.cBorder
                    }
                }

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
                        scale: hovered ? root.hoverScale : 1.0
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
                            color: parent.enabled ? root.cFg : root.cMuted
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
                            border.width: root.cBorderWidth
                            border.color: root.cBorder
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
                        scale: hovered ? root.hoverScale : 1.0
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
                            color: parent.enabled ? root.cFg : root.cMuted
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
                            border.width: root.cBorderWidth
                            border.color: root.cBorder
                            opacity: parent.enabled ? 1.0 : 0.55
                        }
                    }

                    Button {
                        text: MediaInfo.status === "Playing" ? "⏸" : "▶"
                        enabled: MediaInfo.hasMedia
                        hoverEnabled: true
                        HoverHandler {
                            cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        }
                        transformOrigin: Item.Center
                        scale: hovered ? root.hoverScale : 1.0
                        z: hovered ? 1 : 0
                        Behavior on scale {
                            NumberAnimation {
                                duration: root.hoverAnimMs
                                easing.type: Easing.OutCubic
                            }
                        }
                        onClicked: MediaInfo.playPause()

                        contentItem: Text {
                            text: parent.text
                            color: parent.enabled ? root.cFg : root.cMuted
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
                        scale: hovered ? root.hoverScale : 1.0
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
                            color: parent.enabled ? root.cFg : root.cMuted
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
                            border.width: root.cBorderWidth
                            border.color: root.cBorder
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
                        scale: hovered ? root.hoverScale : 1.0
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
                            color: parent.enabled ? root.cFg : root.cMuted
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
                            border.width: root.cBorderWidth
                            border.color: root.cBorder
                            opacity: parent.enabled ? 1.0 : 0.55
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    spacing: 10

                    ComboBox {
                        id: playerSelector
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 12
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
                            border.color: Qt.rgba(root.cBorder.r, root.cBorder.g, root.cBorder.b, 0.8)
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

                Item { Layout.fillHeight: true }
            }
        }
    }
}

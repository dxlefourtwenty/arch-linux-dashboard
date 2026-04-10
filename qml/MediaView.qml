import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

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
                        : "No media"
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
                        : "Play something for media details"
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
                    Layout.topMargin: 8
                    spacing: 10

                    Button {
                        text: "󰒮"
                        enabled: MediaInfo.hasMedia
                        hoverEnabled: true
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

                    Text {
                        text: "VOL"
                        color: root.cMuted
                        font.family: root.cFont
                        font.pixelSize: root.cFontSize * 0.88
                    }

                    Slider {
                        id: volumeSlider
                        Layout.preferredWidth: Math.max(180, root.width * 0.46)
                        from: 0
                        to: 1
                        enabled: MediaInfo.hasMedia
                        value: pressed ? value : MediaInfo.volume
                        onMoved: MediaInfo.setVolume(value)

                        background: Rectangle {
                            implicitWidth: 220
                            implicitHeight: 8
                            radius: 0
                            color: root.cMuted
                            opacity: 0.2
                            border.width: root.cBorderWidth
                            border.color: root.cBorder

                            Rectangle {
                                width: volumeSlider.visualPosition * parent.width
                                height: parent.height
                                color: root.cPrimary
                                opacity: 1.0
                            }
                        }

                        handle: Rectangle {
                            implicitWidth: 12
                            implicitHeight: 12
                            x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                            y: volumeSlider.topPadding + (volumeSlider.availableHeight - height) / 2
                            radius: 0
                            color: root.cPrimary
                            border.width: root.cBorderWidth
                            border.color: root.cBorder
                        }
                    }

                    Text {
                        text: Math.round(MediaInfo.volume * 100) + "%"
                        color: root.cFg
                        font.family: root.cFont
                        font.pixelSize: root.cFontSize * 0.88
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}

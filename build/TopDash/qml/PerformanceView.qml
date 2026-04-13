import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property color  cBg: "#111111"
    property color  cFg: "white"
    property color  cMuted: "#888888"
    property color  cPrimary: cFg
    property color  cAccent: cFg
    property color  cSecondary: cMuted
    property color  cGreen: cSecondary
    property string cFont: "sans"
    property int    cFontSize: 16
    property int    cBorderWidth: 2
    property int    cardRadius: 8

    color: "transparent"

    component UsageCard: Rectangle {
        id: usageCard

        property string glyph: ""
        property string label: ""
        property string detail: ""
        property int value: 0
        property color accent: root.cFg

        radius: root.cardRadius
        color: "transparent"
        border.width: root.cBorderWidth
        border.color: root.cMuted

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Row {
                spacing: 8

                Text {
                    text: usageCard.glyph
                    y: -1
                    color: usageCard.accent
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize * 1.05
                    font.bold: true
                }

                Text {
                    text: usageCard.label
                    color: root.cFg
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize * 0.95
                    font.bold: true
                }
            }

            Text {
                width: parent.width
                text: usageCard.detail
                color: root.cMuted
                font.family: root.cFont
                font.pixelSize: root.cFontSize * 0.78
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Item {
                width: parent.width
                height: 42

                Text {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    text: usageCard.value + "%"
                    color: usageCard.accent
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize * 1.8
                    font.bold: true
                }

                Text {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    text: "Usage"
                    color: root.cMuted
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize * 0.9
                }
            }

            Rectangle {
                width: parent.width
                height: 6
                radius: 3
                color: Qt.rgba(root.cMuted.r, root.cMuted.g, root.cMuted.b, 0.35)

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(100, usageCard.value)) / 100
                    height: parent.height
                    radius: parent.radius
                    color: usageCard.accent
                }
            }
        }
    }

    component RingCard: Rectangle {
        id: ringCard

        property string glyph: ""
        property string label: ""
        property string detail: ""
        property int value: 0
        property color accent: root.cFg

        radius: root.cardRadius
        color: "transparent"
        border.width: root.cBorderWidth
        border.color: root.cMuted

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Row {
                spacing: 8

                Text {
                    text: ringCard.glyph
                    y: -1
                    color: ringCard.accent
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize * 1.05
                    font.bold: true
                }

                Text {
                    text: ringCard.label
                    color: root.cFg
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize * 0.95
                    font.bold: true
                }
            }

            Item {
                width: parent.width
                height: Math.max(98, parent.height - 62)

                Item {
                    id: ringGroup
                    anchors.centerIn: parent
                    width: Math.min(84, parent.height - 2)
                    height: width
                    scale: ringHover.hovered ? 1.1 : 1.0

                    Behavior on scale {
                        NumberAnimation {
                            duration: 140
                            easing.type: Easing.OutQuad
                        }
                    }

                    HoverHandler {
                        id: ringHover
                    }

                    Canvas {
                        id: ring
                        anchors.fill: parent

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()

                            var line = 8
                            var radius = (Math.min(width, height) - line) / 2
                            var cx = width / 2
                            var cy = height / 2

                            ctx.strokeStyle = Qt.rgba(root.cMuted.r, root.cMuted.g, root.cMuted.b, 0.35)
                            ctx.lineWidth = line
                            ctx.beginPath()
                            ctx.arc(cx, cy, radius, 0, Math.PI * 2)
                            ctx.stroke()

                            var pct = Math.max(0, Math.min(100, ringCard.value)) / 100
                            ctx.strokeStyle = ringCard.accent
                            ctx.lineWidth = line
                            ctx.lineCap = "round"
                            ctx.beginPath()
                            ctx.arc(cx, cy, radius, -Math.PI / 2, -Math.PI / 2 + (Math.PI * 2 * pct), false)
                            ctx.stroke()
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: ringCard.value + "%"
                        color: ringCard.accent
                        font.family: root.cFont
                        font.pixelSize: root.cFontSize * 1.25
                        font.bold: true
                    }
                }

                Text {
                    anchors.top: ringGroup.bottom
                    anchors.topMargin: 8
                    anchors.horizontalCenter: ringGroup.horizontalCenter
                    text: ringCard.detail
                    color: root.cFg
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize * 0.82
                }
            }
        }

        onValueChanged: ring.requestPaint()
        Component.onCompleted: ring.requestPaint()
    }

    component InfoCard: Rectangle {
        id: infoCard

        property string glyph: ""
        property string label: ""
        property string line1: ""
        property string line2: ""
        property string line1Glyph: ""
        property string line2Glyph: ""
        property string line1Label: ""
        property string line2Label: ""
        property int lineLabelLeftMargin: 0
        property color glyphColor: root.cFg
        property string line1Value: ""
        property string line2Value: ""
        property color line1ValueColor: root.cFg
        property color line2ValueColor: root.cFg

        radius: root.cardRadius
        color: "transparent"
        border.width: root.cBorderWidth
        border.color: root.cMuted

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            Row {
                spacing: 8

                Text {
                    text: infoCard.glyph
                    y: -1
                    color: infoCard.glyphColor
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize * 1.05
                    font.bold: true
                }

                Text {
                    text: infoCard.label
                    color: root.cFg
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize * 0.95
                    font.bold: true
                }
            }

            RowLayout {
                width: parent.width
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: infoCard.lineLabelLeftMargin

                    Text {
                        visible: infoCard.line1Glyph !== ""
                        text: infoCard.line1Glyph
                        color: root.cFg
                        font.family: root.cFont
                        font.pixelSize: root.cFontSize * 1.05
                    }

                    Text {
                        Layout.fillWidth: true
                        text: infoCard.line1Label !== "" ? infoCard.line1Label : infoCard.line1
                        color: root.cFg
                        font.family: root.cFont
                        font.pixelSize: root.cFontSize * 1.05
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }

                Text {
                    text: infoCard.line1Value
                    color: infoCard.line1ValueColor
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize * 1.05
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            RowLayout {
                width: parent.width
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: infoCard.lineLabelLeftMargin

                    Text {
                        visible: infoCard.line2Glyph !== ""
                        text: infoCard.line2Glyph
                        color: root.cFg
                        font.family: root.cFont
                        font.pixelSize: root.cFontSize * 1.05
                    }

                    Text {
                        Layout.fillWidth: true
                        text: infoCard.line2Label !== "" ? infoCard.line2Label : infoCard.line2
                        color: root.cFg
                        font.family: root.cFont
                        font.pixelSize: root.cFontSize * 1.05
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }

                Text {
                    text: infoCard.line2Value
                    color: infoCard.line2ValueColor
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize * 1.05
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }
    }

    component BatteryCard: Rectangle {
        id: batteryCard

        property string glyph: ""
        property string label: ""
        property int value: -1
        property real ratio: value >= 0 ? Math.max(0, Math.min(100, value)) / 100 : 0
        property real progressScale: 0.8
        property bool lowBattery: value >= 0 && value < 20

        radius: root.cardRadius
        color: "transparent"
        border.width: root.cBorderWidth
        border.color: root.cMuted

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Row {
                spacing: 8

                Text {
                    text: batteryCard.glyph
                    y: -1
                    color: root.cSecondary
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize * 1.05
                    font.bold: true
                }

                Text {
                    text: batteryCard.label
                    color: root.cFg
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize * 0.95
                    font.bold: true
                }
            }

            Item {
                width: parent.width
                height: Math.max(58, parent.height - 36)

                Column {
                    anchors.fill: parent
                    spacing: 0

                    Column {
                        id: batteryStack
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        spacing: 1

                        property real barWidth: parent.width * batteryCard.progressScale

                        Item {
                            id: barContainer
                            width: batteryStack.barWidth
                            height: 44 * batteryCard.progressScale

                            Rectangle {
                                id: batteryBody
                                anchors.left: parent.left
                                anchors.right: batteryCap.left
                                anchors.rightMargin: 0
                                anchors.verticalCenter: parent.verticalCenter
                                height: 36 * batteryCard.progressScale
                                radius: 4
                                color: "transparent"
                                border.width: 2
                                border.color: Qt.rgba(root.cMuted.r, root.cMuted.g, root.cMuted.b, 0.85)
                                clip: true

                                Rectangle {
                                    id: batteryFill
                                anchors.left: parent.left
                                anchors.leftMargin: 2
                                anchors.verticalCenter: parent.verticalCenter
                                height: parent.height - 4
                                    width: (parent.width - 4) * batteryCard.ratio
                                    radius: 2
                                    color: root.cGreen
                                    visible: batteryCard.value >= 0
                                    clip: true

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 180
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    spacing: 2

                                    Repeater {
                                        model: 16
                                        Rectangle {
                                            width: 3
                                            height: parent.height
                                            radius: 1
                                            color: Qt.rgba(root.cFg.r, root.cFg.g, root.cFg.b, 0.85)
                                        }
                                    }
                                }
                                }
                            }

                            Rectangle {
                                id: batteryCap
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 8 * batteryCard.progressScale
                                height: 20 * batteryCard.progressScale
                                radius: 2
                                color: Qt.rgba(root.cMuted.r, root.cMuted.g, root.cMuted.b, 0.85)

                                Rectangle {
                                    anchors.left: parent.left
                                    width: parent.width / 2
                                    height: parent.height
                                    color: parent.color
                                }
                            }

                            Text {
                                id: percentText
                                property real padding: 6
                                property bool fitsInsideFill: batteryCard.value >= 0
                                    && batteryFill.width >= (width + padding * 2)
                                x: fitsInsideFill
                                    ? Math.max(padding, batteryFill.width - width - padding)
                                    : Math.min(
                                        batteryBody.width - width - padding,
                                        Math.max(padding, batteryFill.width + padding)
                                    )
                                y: batteryBody.y + (batteryBody.height - height) / 2
                                text: batteryCard.value >= 0 ? (batteryCard.value + "%") : "N/A"
                                color: batteryCard.lowBattery ? root.cFg : (fitsInsideFill ? root.cBg : root.cFg)
                                font.family: root.cFont
                                font.pixelSize: Math.max(1, (root.cFontSize * 1.45 - 2) / 1.5)
                                font.bold: true
                            }
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 0.8
            spacing: 14

            UsageCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                glyph: "󰍛"
                label: "CPU"
                detail: SystemInfo.cpuName
                value: SystemInfo.cpuUsage
                accent: root.cPrimary
            }

            UsageCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                glyph: "󰨇"
                label: "GPU"
                detail: SystemInfo.gpuName
                value: SystemInfo.gpuUsage
                accent: root.cSecondary
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 1.0
            spacing: 14

            RingCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                glyph: ""
                label: "Memory"
                detail: Number(SystemInfo.ramUsedGiB).toFixed(1) + " / " + Number(SystemInfo.ramTotalGiB).toFixed(1) + " GiB"
                value: SystemInfo.ramUsage
                accent: root.cAccent
            }

            RingCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                glyph: "󰋊"
                label: SystemInfo.diskName ? ("Storage - " + SystemInfo.diskName) : "Storage"
                detail: Number(SystemInfo.diskUsedGiB).toFixed(1) + " / " + Number(SystemInfo.diskTotalGiB).toFixed(1) + " GiB"
                value: SystemInfo.diskUsage
                accent: root.cSecondary
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 0.62
            spacing: 14

            InfoCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                glyph: "󰓢"
                label: "Network"
                glyphColor: root.cSecondary
                line1Glyph: ""
                line1Label: "Download"
                line1Value: Number(SystemInfo.networkDownBps).toFixed(1) + " B/s"
                line2Glyph: ""
                line2Label: "Upload"
                line2Value: Number(SystemInfo.networkUpBps).toFixed(1) + " B/s"
                lineLabelLeftMargin: 8
                line1ValueColor: root.cPrimary
                line2ValueColor: root.cSecondary
            }

            BatteryCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                glyph: "󰁹"
                label: "Battery"
                value: SystemInfo.batteryPercent
            }
        }
    }
}

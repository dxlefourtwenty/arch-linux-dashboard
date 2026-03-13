import QtQuick
import QtQuick.Layouts

// StatsCard.qml
// Each Text is bound individually so SystemInfo property-change signals
// propagate correctly. A JS object array model breaks live QML bindings.

Rectangle {
    id: root

    property color  cFg:       "white"
    property string cFont:     "sans"
    property int    cFontSize: 16
    property real   usageFontSize: cFontSize * 1.012
    // Can be negative to pull stats closer to the title.
    property int    usageToStatsGap: 14

    color: "transparent"

    Column {
        anchors.fill: parent
        spacing: root.usageToStatsGap

        Text {
            width: parent.width
            text: "Usage"
            color: root.cFg
            font.family: root.cFont
            font.pixelSize: root.usageFontSize
            lineHeightMode: Text.ProportionalHeight
            lineHeight: 0.85
            horizontalAlignment: Text.AlignLeft
        }

        GridLayout {
            width: parent.width
            columns: 2
            columnSpacing: 24
            rowSpacing: 4

            Text {
                text: "CPU: " + SystemInfo.cpuUsage + "%"
                color: root.cFg
                font.family: root.cFont
                font.pixelSize: root.usageFontSize
                horizontalAlignment: Text.AlignLeft
            }

            Text {
                text: "RAM: " + SystemInfo.ramUsage + "%"
                color: root.cFg
                font.family: root.cFont
                font.pixelSize: root.usageFontSize
                horizontalAlignment: Text.AlignLeft
            }

            Text {
                text: "GPU: " + SystemInfo.gpuUsage + "%"
                color: root.cFg
                font.family: root.cFont
                font.pixelSize: root.usageFontSize
                horizontalAlignment: Text.AlignLeft
            }

            Text {
                text: "DISK: " + SystemInfo.diskUsage + "%"
                color: root.cFg
                font.family: root.cFont
                font.pixelSize: root.usageFontSize
                horizontalAlignment: Text.AlignLeft
            }
        }
    }
}

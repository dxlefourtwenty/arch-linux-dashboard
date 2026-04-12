import QtQuick

Rectangle {
    id: root

    property color  cFg: "white"
    property color  cAccent: "#ffffff"
    property color  cSecondary: "#888888"
    property string cFont: "sans"
    property int    cFontSize: 16
    property real   timeFontSize: cFontSize * 2.0
    property real   meridiemFontSize: cFontSize * 2.0
    property real   meridiemOffsetX: 5
    property int    colonBlinkMs: 1000
    property string currentHourText: "12"
    property string currentMinuteText: "00"
    property string currentMeridiemText: "AM"

    function refreshTime() {
        const now = new Date()
        const rawHour = now.getHours()
        const hour12 = rawHour % 12 === 0 ? 12 : rawHour % 12
        const hourText = hour12 < 10 ? "0" + hour12 : "" + hour12
        const minuteText = now.getMinutes() < 10 ? "0" + now.getMinutes() : "" + now.getMinutes()
        root.currentHourText = hourText
        root.currentMinuteText = minuteText
        root.currentMeridiemText = rawHour >= 12 ? "PM" : "AM"
    }

    color: "transparent"

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.refreshTime()
    }

    Component.onCompleted: root.refreshTime()

    Row {
        anchors.centerIn: parent
        spacing: 6

        Row {
            spacing: 0

            Text {
                text: root.currentHourText
                color: root.cAccent
                font.family: root.cFont
                font.pixelSize: root.timeFontSize
                font.weight: Font.DemiBold
            }

            Text {
                text: ":"
                color: root.cSecondary
                font.family: root.cFont
                font.pixelSize: root.timeFontSize
                font.weight: Font.DemiBold

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: true
                    NumberAnimation { to: 0.25; duration: root.colonBlinkMs }
                    NumberAnimation { to: 1.0; duration: root.colonBlinkMs }
                }
            }

            Text {
                text: root.currentMinuteText
                color: root.cAccent
                font.family: root.cFont
                font.pixelSize: root.timeFontSize
                font.weight: Font.DemiBold
            }
        }

        Text {
            text: root.currentMeridiemText
            color: root.cSecondary
            font.family: root.cFont
            font.pixelSize: root.meridiemFontSize
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
            transform: Translate { x: root.meridiemOffsetX }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// CalendarView.qml
//
// Exposes:
//   property string selectedKey  -- "YYYY-MM-DD", auto-generates onSelectedKeyChanged
//
// NOTE: do NOT declare "signal selectedKeyChanged" manually -- the property
// already creates that signal and a duplicate causes a compile error.

Item {
    id: root
    clip: true

    property color  cFg:          "white"
    property color  cAccent:      cFg
    property int    dayHoverRingWidth: 2
    property color  cMuted:       "#888888"
    property string cFont:        "sans"
    property int    cFontSize:    16
    property color  cBg:          "#111111"
    property color  cBorder:      "#444444"
    property int    cBorderWidth: 2
    property int    cRadius:      0
    property int    hoverAnimMs:  140
    property int    dateHoverDelayMs: 400

    property date   today:       new Date()
    property int    viewYear:    today.getFullYear()
    property int    viewMonth:   today.getMonth()    // 0-11
    property int    selectedDay: today.getDate()
    property bool   dateHoverActive: false
    property real   dateHoverCenterX: 0
    property real   dateHoverTopY: 0
    property string dateHoverText: ""
    property string dateHoverKey: ""

    property string selectedKey: viewYear + "-" + pad2(viewMonth + 1) + "-" + pad2(selectedDay)
    property string selectedDisplayDate: Qt.formatDate(
                                            new Date(viewYear, viewMonth, selectedDay),
                                            "dddd - MMMM d, yyyy")

    function daysInMonth(y, m0)  { return new Date(y, m0 + 1, 0).getDate() }
    function firstWeekday(y, m0) { return new Date(y, m0, 1).getDay() }
    function pad2(n)             { return (n < 10 ? "0" : "") + n }
    function formatNumericDate(d) {
        return pad2(d.getMonth() + 1) + "/" + pad2(d.getDate()) + "/" + d.getFullYear()
    }
    function setDateHover(cell, d) {
        const pos = cell.mapToItem(root, cell.width / 2, 0)
        root.dateHoverCenterX = pos.x
        root.dateHoverTopY = pos.y
        root.dateHoverText = formatNumericDate(d)
        root.dateHoverKey = root.dateHoverText
        root.dateHoverActive = false
        dateHoverTimer.restart()
    }
    function clearDateHover(key) {
        if (key !== root.dateHoverKey) {
            return
        }
        dateHoverTimer.stop()
        root.dateHoverActive = false
        root.dateHoverKey = ""
    }
    function refreshToToday() {
        root.today = new Date()
        root.viewYear = root.today.getFullYear()
        root.viewMonth = root.today.getMonth()
        root.selectedDay = root.today.getDate()
    }

    Timer {
        id: dateHoverTimer
        interval: root.dateHoverDelayMs
        repeat: false
        onTriggered: root.dateHoverActive = root.dateHoverText.length > 0
    }

    // No implicitHeight override -- let the parent layout control our height
    // via Layout.preferredHeight set in Main.qml.

    ColumnLayout {
        id: calColumn
        anchors.fill: parent
        spacing: 4

        // Month navigation
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Button {
                id: prevBtn
                text: "<"
                Layout.preferredWidth: 32
                Layout.minimumWidth: 32
                Layout.preferredHeight: 32
                Layout.minimumHeight: 32
                hoverEnabled: true

                contentItem: Text {
                    text: prevBtn.text
                    color: root.cFg
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: root.cRadius
                    color: prevBtn.down
                           ? Qt.rgba(root.cBg.r, root.cBg.g, root.cBg.b, 0.55)
                           : (prevBtn.hovered
                              ? Qt.rgba(root.cBg.r, root.cBg.g, root.cBg.b, 0.35)
                              : "transparent")
                    border.width: 0
                    border.color: root.cBorder
                }

                onClicked: {
                    if (root.viewMonth === 0) { root.viewMonth = 11; root.viewYear -= 1 }
                    else root.viewMonth -= 1
                    root.selectedDay = 1
                }
            }

            Text {
                Layout.fillWidth: true
                text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
                color: root.cAccent
                font.family: root.cFont
                font.pixelSize: root.cFontSize + 2
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Button {
                id: nextBtn
                text: ">"
                Layout.preferredWidth: 32
                Layout.minimumWidth: 32
                Layout.preferredHeight: 32
                Layout.minimumHeight: 32
                hoverEnabled: true

                contentItem: Text {
                    text: nextBtn.text
                    color: root.cFg
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: root.cRadius
                    color: nextBtn.down
                           ? Qt.rgba(root.cBg.r, root.cBg.g, root.cBg.b, 0.55)
                           : (nextBtn.hovered
                              ? Qt.rgba(root.cBg.r, root.cBg.g, root.cBg.b, 0.35)
                              : "transparent")
                    border.width: 0
                    border.color: root.cBorder
                }

                onClicked: {
                    if (root.viewMonth === 11) { root.viewMonth = 0; root.viewYear += 1 }
                    else root.viewMonth += 1
                    root.selectedDay = 1
                }
            }
        }

        // Weekday labels
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
                delegate: Text {
                    Layout.fillWidth: true
                    text: modelData
                    color: root.cFg
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize - 2
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Day grid -- fillHeight so it uses available space rather than
        // computing an unconstrained implicit size
        GridLayout {
            id: calGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            rowSpacing: 1
            columnSpacing: 2

            property int lead: root.firstWeekday(root.viewYear, root.viewMonth)
            property int dim:  root.daysInMonth(root.viewYear, root.viewMonth)
            property int totalCells: Math.ceil((lead + dim) / 7) * 7

            Repeater {
                model: calGrid.totalCells
                delegate: Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true   // cells share available height equally

                    property int  dayNum:     index - calGrid.lead + 1
                    property bool inMonth:    dayNum >= 1 && dayNum <= calGrid.dim
                    property bool isSelected: inMonth && dayNum === root.selectedDay
                    property bool isHovered:  inMonth && !isSelected && dayMouse.containsMouse
                    property int prevMonthDayNum: root.daysInMonth(root.viewYear, root.viewMonth - 1)
                    property int cellDayNumber: {
                        if (inMonth) return dayNum
                        if (dayNum < 1) return prevMonthDayNum + dayNum
                        return dayNum - calGrid.dim
                    }
                    property date cellDate: new Date(root.viewYear, root.viewMonth, dayNum)

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.max(0, Math.min(parent.width, parent.height) - 2)
                        height: width
                        radius: width / 2
                        color: isSelected ? root.cAccent : "transparent"
                        border.width: isHovered ? root.dayHoverRingWidth : 0
                        border.color: root.cFg
                    }

                    Text {
                        anchors.centerIn: parent
                        text: cellDayNumber
                        color: isSelected ? root.cBg : (inMonth ? root.cFg : root.cMuted)
                        font.family: root.cFont
                        font.pixelSize: root.cFontSize - 2
                        font.weight: isSelected ? Font.DemiBold : Font.Normal
                    }

                    MouseArea {
                        id: dayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: inMonth
                        onEntered: root.setDateHover(parent, cellDate)
                        onExited: root.clearDateHover(root.formatNumericDate(cellDate))
                        onClicked: root.selectedDay = dayNum
                    }
                }
            }
        }

    }

    Rectangle {
        id: dateHoverPreview
        readonly property int sidePadding: 10

        z: 100
        visible: root.dateHoverActive
        opacity: visible ? 1.0 : 0.0
        width: dateHoverLabel.implicitWidth + sidePadding * 2
        height: Math.max(24, dateHoverLabel.implicitHeight + 8)
        x: Math.max(0, Math.min(root.width - width, root.dateHoverCenterX - width / 2))
        y: Math.max(0, root.dateHoverTopY - height - 8)
        radius: height / 2
        color: root.cBg
        border.width: root.cBorderWidth
        border.color: root.cFg

        Behavior on opacity {
            NumberAnimation {
                duration: root.hoverAnimMs
                easing.type: Easing.OutCubic
            }
        }

        Text {
            id: dateHoverLabel
            anchors.centerIn: parent
            text: root.dateHoverText
            color: root.cFg
            font.family: root.cFont
            font.pixelSize: root.cFontSize * 0.78
        }
    }
}

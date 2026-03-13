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
    property color  cMuted:       "#888888"
    property string cFont:        "sans"
    property int    cFontSize:    16
    property color  cBg:          "#111111"
    property color  cBorder:      "#444444"
    property int    cBorderWidth: 2
    property int    cRadius:      0

    property date   today:       new Date()
    property int    viewYear:    today.getFullYear()
    property int    viewMonth:   today.getMonth()    // 0-11
    property int    selectedDay: today.getDate()

    property string selectedKey: viewYear + "-" + pad2(viewMonth + 1) + "-" + pad2(selectedDay)
    property string selectedDisplayDate: Qt.formatDate(
                                            new Date(viewYear, viewMonth, selectedDay),
                                            "dddd - MMMM d, yyyy")

    function daysInMonth(y, m0)  { return new Date(y, m0 + 1, 0).getDate() }
    function firstWeekday(y, m0) { return new Date(y, m0, 1).getDay() }
    function pad2(n)             { return (n < 10 ? "0" : "") + n }
    function refreshToToday() {
        root.today = new Date()
        root.viewYear = root.today.getFullYear()
        root.viewMonth = root.today.getMonth()
        root.selectedDay = root.today.getDate()
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
                color: root.cFg
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
                    color: root.cMuted
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

            Repeater {
                model: 42
                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true   // cells share available height equally

                    property int  dayNum:     index - calGrid.lead + 1
                    property bool inMonth:    dayNum >= 1 && dayNum <= calGrid.dim
                    property bool isSelected: inMonth && dayNum === root.selectedDay

                    radius: 0
                    color:        isSelected ? root.cBg          : "transparent"
                    border.width: isSelected ? root.cBorderWidth : 0
                    border.color: root.cBorder

                    Text {
                        anchors.centerIn: parent
                        text: inMonth ? dayNum : ""
                        color: root.cFg
                        font.family: root.cFont
                        font.pixelSize: root.cFontSize - 2
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: inMonth
                        onClicked: root.selectedDay = dayNum
                    }
                }
            }
        }

    }
}

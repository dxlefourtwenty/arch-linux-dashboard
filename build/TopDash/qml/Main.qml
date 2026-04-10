import QtQuick
import QtCore
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.layershell 1.0 as LS

Window {
    id: win

    property bool open: false
    property int animMs: 180

    function toggle() {
        if (open) {
            open = false
            hideTimer.restart()
        } else {
            visible = true
            hideTimer.stop()
            open = true
            calendar.refreshToToday()
            stage.forceActiveFocus()
        }
    }

    onActiveChanged: {
        if (!active && open) toggle()
    }

    property string themeBaseSource: StandardPaths.writableLocation(StandardPaths.HomeLocation)
                                   + "/.config/dashboard/theme.qml"
    property string styleBaseSource: StandardPaths.writableLocation(StandardPaths.HomeLocation)
                                   + "/.config/dashboard/style.qml"

    property QtObject theme: ConfigFiles.theme
    property QtObject style: ConfigFiles.style

    property color  cBg:          (theme && theme.bg)                        ? theme.bg          : "#111111"
    property real   cOpacity:     (theme && theme.opacity !== undefined)      ? theme.opacity     : 1.0
    property int    cRadius:      (style && style.radius !== undefined)       ? style.radius
                                : (theme && theme.radius !== undefined)       ? theme.radius      : 0
    property int    cBorderWidth: (style && style.borderWidth !== undefined)  ? style.borderWidth
                                : (theme && theme.borderWidth !== undefined)  ? theme.borderWidth : 2
    property bool   cBorderLeft:  (style && style.borderLeft !== undefined)   ? style.borderLeft
                                : (theme && theme.borderLeft !== undefined)   ? theme.borderLeft : true
    property bool   cBorderRight: (style && style.borderRight !== undefined)  ? style.borderRight
                                : (theme && theme.borderRight !== undefined)  ? theme.borderRight : true
    property bool   cBorderTop:   (style && style.borderTop !== undefined)    ? style.borderTop
                                : (theme && theme.borderTop !== undefined)    ? theme.borderTop : true
    property bool   cBorderBottom:(style && style.borderBottom !== undefined) ? style.borderBottom
                                : (theme && theme.borderBottom !== undefined) ? theme.borderBottom : true
    property color  cBorder:      (theme && theme.border)                    ? theme.border      : "#444444"
    property color  cPrimary:     (theme && theme.primary)                   ? theme.primary
                                : (theme && theme.accent)                    ? theme.accent
                                : (theme && theme.border)                    ? theme.border      : "#444444"
    property color  cFg:          (theme && theme.fg)                        ? theme.fg          : "white"
    property color  cMuted:       (theme && theme.muted)                     ? theme.muted       : "#888888"
    property string cFont:        (style && style.font)                      ? style.font
                                : (theme && theme.font)                      ? theme.font        : "sans"
    property int    cFontSize:    (style && style.fontSize !== undefined)     ? style.fontSize
                                : (theme && theme.fontSize !== undefined)     ? theme.fontSize    : 16
    property int    barHeight:    (style && style.barHeight !== undefined)    ? style.barHeight   : 30
    property int    finalPosition: (style && style.finalPosition !== undefined) ? style.finalPosition : 0
    property int    taskCharCutoff: (style && style.taskCharCutoff !== undefined) ? style.taskCharCutoff : 240
    property int    activeTabIndex: 0

    // Inner card layout tuning (edit these to control per-component padding and sizing)
    property int panelOuterMargin: 16
    property int panelColumnSpacing: 14
    property int panelRowSpacing: 14

    property int profilePaddingTop: 32
    property int profilePaddingLeft: 12
    property int profilePaddingRight: 18
    property int profilePaddingBottom: 12

    property int calendarPaddingTop: 18
    property int calendarPaddingLeft: 18
    property int calendarPaddingRight: 18
    property int calendarPaddingBottom: 18

    property int statsPaddingTop: 18
    property int statsPaddingLeft: 18
    property int statsPaddingRight: 18
    property int statsPaddingBottom: 18

    property int tasksPaddingTop: 18
    property int tasksPaddingLeft: 18
    property int tasksPaddingRight: 18
    property int tasksPaddingBottom: 24

    property real profileCardWidthWeight: 0.95
    property real profileCardHeightWeight: 1.0
    property real calendarCardWidthWeight: 1.55
    property real calendarCardHeightWeight: 1.70
    property real statsCardWidthWeight: 0.95
    property real statsCardHeightWeight: 1.0
    property real tasksCardWidthWeight: 1.55
    property real tasksCardHeightWeight: 1.0

    // Minimum content sizes used to keep cards from clipping when padding/margins increase.
    property int profileMinContentWidth: 180
    property int profileMinContentHeight: 170
    property int calendarMinContentWidth: 300
    property int calendarMinContentHeight: 230
    property int statsMinContentWidth: 180
    property int statsMinContentHeight: 130
    property int tasksMinContentWidth: 300
    property int tasksMinContentHeight: 130

    property int profileMinWidth: profileMinContentWidth + profilePaddingLeft + profilePaddingRight
    property int profileMinHeight: profileMinContentHeight + profilePaddingTop + profilePaddingBottom
    property int calendarMinWidth: calendarMinContentWidth + calendarPaddingLeft + calendarPaddingRight
    property int calendarMinHeight: calendarMinContentHeight + calendarPaddingTop + calendarPaddingBottom
    property int statsMinWidth: statsMinContentWidth + statsPaddingLeft + statsPaddingRight
    property int statsMinHeight: statsMinContentHeight + statsPaddingTop + statsPaddingBottom
    property int tasksMinWidth: tasksMinContentWidth + tasksPaddingLeft + tasksPaddingRight
    property int tasksMinHeight: tasksMinContentHeight + tasksPaddingTop + tasksPaddingBottom

    property int panelBaseWidth: 640
    property int panelBaseHeight: 440
    property int tabsHeaderHeight: 58
    property int tabsHeaderBottomGap: 10
    property int tabLabelToSeparatorGap: 7
    property int tabIndicatorWidth: 62
    property int tabIndicatorHeight: 2
    property int panelMinWidthFromLayout: panelOuterMargin * 2
                                        + panelColumnSpacing
                                        + Math.max(profileMinWidth, statsMinWidth)
                                        + Math.max(calendarMinWidth, tasksMinWidth)
    property int panelMinHeightFromLayout: panelOuterMargin * 2
                                         + panelRowSpacing
                                         + Math.max(profileMinHeight, calendarMinHeight)
                                         + Math.max(statsMinHeight, tasksMinHeight)
    property int panelW: Math.max(panelBaseWidth, panelMinWidthFromLayout)
    property int dashboardContentH: Math.max(panelBaseHeight, panelMinHeightFromLayout)
    property int panelH: dashboardContentH + tabsHeaderHeight + tabsHeaderBottomGap
    property int visibleFinalPosition: Math.max(0, finalPosition)

    function reloadTheme() {
        ConfigFiles.reload()
    }

    function reloadTasks() {
        if (taskView) taskView.reloadCurrent()
    }

    height: panelH + visibleFinalPosition
    minimumHeight: panelH + visibleFinalPosition
    maximumHeight: panelH + visibleFinalPosition
    width: panelW
    minimumWidth: panelW
    maximumWidth: panelW

    visible: false
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    LS.Window.margins.top: barHeight
    LS.Window.layer: LS.Window.LayerOverlay
    LS.Window.anchors: LS.Window.AnchorTop | LS.Window.AnchorLeft | LS.Window.AnchorRight
    LS.Window.exclusionZone: -1
    LS.Window.keyboardInteractivity: open
        ? LS.Window.KeyboardInteractivityOnDemand
        : LS.Window.KeyboardInteractivityNone

    Timer {
        id: hideTimer
        interval: win.animMs
        repeat: false
        onTriggered: { if (!win.open) win.visible = false }
    }

    Item {
        id: stage
        anchors.fill: parent
        focus: true
        clip: true

        Keys.onPressed: (e) => {
            if (e.key === Qt.Key_Escape) { win.toggle(); e.accepted = true }
        }

        Rectangle {
            id: panel
            width: win.panelW
            height: win.panelH
            anchors.horizontalCenter: parent.horizontalCenter
            clip: true

            y: win.open ? win.visibleFinalPosition : (-height - 12)
            Behavior on y { 
                NumberAnimation { 
                  duration: win.animMs; 
                  easing.type: Easing.OutCubic 
                } 
            }

            radius: win.cRadius
            color: Qt.rgba(win.cBg.r, win.cBg.g, win.cBg.b, win.cOpacity)
            border.width: 0

            Canvas {
                id: panelBorder
                anchors.fill: parent
                visible: borderWidth > 0 && (borderLeft || borderRight || borderTop || borderBottom)
                antialiasing: true

                property color borderColor: win.cBorder
                property int borderWidth: win.cBorderWidth
                property int radius: win.cRadius
                property bool borderLeft: win.cBorderLeft
                property bool borderRight: win.cBorderRight
                property bool borderTop: win.cBorderTop
                property bool borderBottom: win.cBorderBottom

                onBorderColorChanged: requestPaint()
                onBorderWidthChanged: requestPaint()
                onRadiusChanged: requestPaint()
                onBorderLeftChanged: requestPaint()
                onBorderRightChanged: requestPaint()
                onBorderTopChanged: requestPaint()
                onBorderBottomChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    ctx.clearRect(0, 0, width, height)

                    if (!visible)
                        return

                    var bw = Math.max(0, borderWidth)
                    var half = bw / 2
                    var left = half
                    var top = half
                    var right = width - half
                    var bottom = height - half

                    var maxRadius = Math.max(0, Math.min(radius, (width - bw) / 2, (height - bw) / 2))
                    var allSides = borderLeft && borderRight && borderTop && borderBottom

                    ctx.strokeStyle = borderColor
                    ctx.lineWidth = bw
                    ctx.lineCap = "butt"
                    ctx.lineJoin = "miter"

                    if (allSides) {
                        ctx.beginPath()
                        ctx.moveTo(left + maxRadius, top)
                        ctx.lineTo(right - maxRadius, top)
                        if (maxRadius > 0) ctx.arc(right - maxRadius, top + maxRadius, maxRadius, -Math.PI / 2, 0)
                        ctx.lineTo(right, bottom - maxRadius)
                        if (maxRadius > 0) ctx.arc(right - maxRadius, bottom - maxRadius, maxRadius, 0, Math.PI / 2)
                        ctx.lineTo(left + maxRadius, bottom)
                        if (maxRadius > 0) ctx.arc(left + maxRadius, bottom - maxRadius, maxRadius, Math.PI / 2, Math.PI)
                        ctx.lineTo(left, top + maxRadius)
                        if (maxRadius > 0) ctx.arc(left + maxRadius, top + maxRadius, maxRadius, Math.PI, 3 * Math.PI / 2)
                        ctx.closePath()
                        ctx.stroke()
                        return
                    }

                    if (borderTop) {
                        ctx.beginPath()
                        ctx.moveTo(left + (borderLeft ? maxRadius : 0), top)
                        ctx.lineTo(right - (borderRight ? maxRadius : 0), top)
                        ctx.stroke()
                    }
                    if (borderBottom) {
                        ctx.beginPath()
                        ctx.moveTo(left + (borderLeft ? maxRadius : 0), bottom)
                        ctx.lineTo(right - (borderRight ? maxRadius : 0), bottom)
                        ctx.stroke()
                    }
                    if (borderLeft) {
                        ctx.beginPath()
                        ctx.moveTo(left, top + (borderTop ? maxRadius : 0))
                        ctx.lineTo(left, bottom - (borderBottom ? maxRadius : 0))
                        ctx.stroke()
                    }
                    if (borderRight) {
                        ctx.beginPath()
                        ctx.moveTo(right, top + (borderTop ? maxRadius : 0))
                        ctx.lineTo(right, bottom - (borderBottom ? maxRadius : 0))
                        ctx.stroke()
                    }

                    if (maxRadius > 0 && borderTop && borderLeft) {
                        ctx.beginPath()
                        ctx.arc(left + maxRadius, top + maxRadius, maxRadius, Math.PI, 3 * Math.PI / 2)
                        ctx.stroke()
                    }
                    if (maxRadius > 0 && borderTop && borderRight) {
                        ctx.beginPath()
                        ctx.arc(right - maxRadius, top + maxRadius, maxRadius, -Math.PI / 2, 0)
                        ctx.stroke()
                    }
                    if (maxRadius > 0 && borderBottom && borderRight) {
                        ctx.beginPath()
                        ctx.arc(right - maxRadius, bottom - maxRadius, maxRadius, 0, Math.PI / 2)
                        ctx.stroke()
                    }
                    if (maxRadius > 0 && borderBottom && borderLeft) {
                        ctx.beginPath()
                        ctx.arc(left + maxRadius, bottom - maxRadius, maxRadius, Math.PI / 2, Math.PI)
                        ctx.stroke()
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: win.tabsHeaderHeight
                    Layout.minimumHeight: win.tabsHeaderHeight

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: win.panelOuterMargin
                        anchors.rightMargin: win.panelOuterMargin
                        spacing: 22

                        Item { Layout.fillWidth: true }

                        Repeater {
                            model: [
                                { icon: "󰕮", label: "Dashboard" },
                                { icon: "󰲸", label: "Media" }
                            ]

                            delegate: Item {
                                Layout.preferredWidth: 120
                                Layout.fillHeight: true

                                Column {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: win.tabIndicatorHeight + win.tabLabelToSeparatorGap
                                    spacing: 3

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.icon
                                        color: win.activeTabIndex === index ? win.cFg : win.cMuted
                                        font.family: win.cFont
                                        font.pixelSize: win.cFontSize * 1.3
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.label
                                        color: win.activeTabIndex === index ? win.cFg : win.cMuted
                                        font.family: win.cFont
                                        font.pixelSize: Math.max(12, win.cFontSize - 2)
                                    }
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 0
                                    width: win.tabIndicatorWidth
                                    height: win.tabIndicatorHeight
                                    radius: 1
                                    color: win.cFg
                                    visible: win.activeTabIndex === index
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.activeTabIndex = index
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: win.cMuted
                    opacity: 0.35
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: win.tabsHeaderBottomGap
                    clip: true

                    StackLayout {
                        id: pages
                        anchors.fill: parent
                        anchors.leftMargin: win.panelOuterMargin
                        anchors.rightMargin: win.panelOuterMargin
                        anchors.bottomMargin: win.panelOuterMargin
                        currentIndex: win.activeTabIndex

                        Item {
                            GridLayout {
                                anchors.fill: parent
                                columns: 2
                                columnSpacing: win.panelColumnSpacing
                                rowSpacing: win.panelRowSpacing

                                Rectangle {
                                    Layout.row: 0
                                    Layout.column: 0
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: win.profileCardWidthWeight
                                    Layout.preferredHeight: win.profileCardHeightWeight
                                    Layout.minimumWidth: win.profileMinWidth
                                    Layout.minimumHeight: win.profileMinHeight
                                    radius: 8
                                    clip: true
                                    color: "transparent"
                                    border.width: win.cBorderWidth
                                    border.color: win.cMuted

                                    ProfileCard {
                                        anchors.fill: parent
                                        anchors.topMargin: win.profilePaddingTop
                                        anchors.leftMargin: win.profilePaddingLeft
                                        anchors.rightMargin: win.profilePaddingRight
                                        anchors.bottomMargin: win.profilePaddingBottom
                                        cFg: win.cFg
                                        cFont: win.cFont
                                        cFontSize: win.cFontSize
                                        cBorder: win.cBorder
                                        cBorderWidth: win.cBorderWidth
                                    }
                                }

                                Rectangle {
                                    id: calView
                                    Layout.row: 0
                                    Layout.column: 1
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: win.calendarCardWidthWeight
                                    Layout.preferredHeight: win.calendarCardHeightWeight
                                    Layout.minimumWidth: win.calendarMinWidth
                                    Layout.minimumHeight: win.calendarMinHeight
                                    radius: 8
                                    clip: true
                                    color: "transparent"
                                    border.width: win.cBorderWidth
                                    border.color: win.cMuted

                                    CalendarView {
                                        id: calendar
                                        anchors.fill: parent
                                        anchors.topMargin: win.calendarPaddingTop
                                        anchors.leftMargin: win.calendarPaddingLeft
                                        anchors.rightMargin: win.calendarPaddingRight
                                        anchors.bottomMargin: win.calendarPaddingBottom

                                        cFg: win.cFg
                                        cMuted: win.cMuted
                                        cFont: win.cFont
                                        cFontSize: win.cFontSize
                                        cBg: win.cBg
                                        cBorder: win.cBorder
                                        cBorderWidth: win.cBorderWidth
                                        cRadius: win.cRadius

                                        onSelectedKeyChanged: taskView.load(calendar.selectedKey)
                                    }
                                }

                                Rectangle {
                                    Layout.row: 1
                                    Layout.column: 0
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: win.statsCardWidthWeight
                                    Layout.preferredHeight: win.statsCardHeightWeight
                                    Layout.minimumWidth: win.statsMinWidth
                                    Layout.minimumHeight: win.statsMinHeight
                                    radius: 8
                                    clip: true
                                    color: "transparent"
                                    border.width: win.cBorderWidth
                                    border.color: win.cMuted

                                    StatsCard {
                                        anchors.fill: parent
                                        anchors.topMargin: win.statsPaddingTop
                                        anchors.leftMargin: win.statsPaddingLeft
                                        anchors.rightMargin: win.statsPaddingRight
                                        anchors.bottomMargin: win.statsPaddingBottom
                                        cFg: win.cFg
                                        cFont: win.cFont
                                        cFontSize: win.cFontSize
                                    }
                                }

                                Rectangle {
                                    Layout.row: 1
                                    Layout.column: 1
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: win.tasksCardWidthWeight
                                    Layout.preferredHeight: win.tasksCardHeightWeight
                                    Layout.minimumWidth: win.tasksMinWidth
                                    Layout.minimumHeight: win.tasksMinHeight
                                    radius: 8
                                    clip: true
                                    color: "transparent"
                                    border.width: win.cBorderWidth
                                    border.color: win.cMuted

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.topMargin: win.tasksPaddingTop
                                        anchors.leftMargin: win.tasksPaddingLeft
                                        anchors.rightMargin: win.tasksPaddingRight
                                        anchors.bottomMargin: win.tasksPaddingBottom

                                        Text {
                                            Layout.fillWidth: true
                                            text: calendar.selectedDisplayDate
                                            color: win.cFg
                                            font.family: win.cFont
                                            font.pixelSize: win.cFontSize * 1.012
                                            elide: Text.ElideRight
                                        }

                                        TasksView {
                                            id: taskView
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            cFg: win.cFg
                                            cMuted: win.cMuted
                                            cFont: win.cFont
                                            cFontSize: win.cFontSize
                                            taskCharCutoff: win.taskCharCutoff
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            MediaView {
                                anchors.fill: parent
                                cFg: win.cFg
                                cMuted: win.cMuted
                                cBorder: win.cBorder
                                cPrimary: win.cPrimary
                                cBorderWidth: win.cBorderWidth
                                cFont: win.cFont
                                cFontSize: win.cFontSize
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        taskView.load(calendar.selectedKey)
    }
}

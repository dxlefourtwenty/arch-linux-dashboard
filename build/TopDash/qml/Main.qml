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
            openWorkTimer.stop()
            hideTimer.restart()
        } else {
            visible = true
            hideTimer.stop()
            open = true
            openWorkTimer.restart()
        }
    }

    property string themeBaseSource: StandardPaths.writableLocation(StandardPaths.HomeLocation)
                                   + "/.config/dashboard/theme.qml"
    property string styleBaseSource: StandardPaths.writableLocation(StandardPaths.HomeLocation)
                                   + "/.config/dashboard/style.qml"

    property QtObject theme: ConfigFiles.theme
    property QtObject style: ConfigFiles.style

    property color  cBg:          (theme && theme.bg)                        ? theme.bg          : "#111111"
    property real   cOpacity:     (theme && theme.opacity !== undefined)      ? theme.opacity     : 1.0
    property int    cRadiusTopLeft: (style && style.radiusTopLeft !== undefined) ? style.radiusTopLeft
                                 : (theme && theme.radiusTopLeft !== undefined) ? theme.radiusTopLeft
                                 : 0
    property int    cRadiusTopRight: (style && style.radiusTopRight !== undefined) ? style.radiusTopRight
                                  : (theme && theme.radiusTopRight !== undefined) ? theme.radiusTopRight
                                  : 0
    property int    cRadiusBottomRight: (style && style.radiusBottomRight !== undefined) ? style.radiusBottomRight
                                     : (theme && theme.radiusBottomRight !== undefined) ? theme.radiusBottomRight
                                     : 0
    property int    cRadiusBottomLeft: (style && style.radiusBottomLeft !== undefined) ? style.radiusBottomLeft
                                    : (theme && theme.radiusBottomLeft !== undefined) ? theme.radiusBottomLeft
                                    : 0
    property int    cRadius:      Math.max(cRadiusTopLeft, cRadiusTopRight, cRadiusBottomRight, cRadiusBottomLeft)
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
    property color  cAccent:      (theme && theme.accent)                    ? theme.accent
                                : (theme && theme.primary)                   ? theme.primary
                                : (theme && theme.border)                    ? theme.border      : "#444444"
    property color  cSecondary:   (theme && theme.secondary)                 ? theme.secondary
                                : (theme && theme.primary)                   ? theme.primary
                                : (theme && theme.accent)                    ? theme.accent
                                : (theme && theme.border)                    ? theme.border      : "#444444"
    property color  cPrimary:     (theme && theme.primary)                   ? theme.primary
                                : (theme && theme.accent)                    ? theme.accent
                                : (theme && theme.border)                    ? theme.border      : "#444444"
    property color  cGreen:       (theme && theme.green)                     ? theme.green
                                : (theme && theme.secondary)                 ? theme.secondary
                                : (theme && theme.accent)                    ? theme.accent      : "#6fbf73"
    property color  cFg:          (theme && theme.fg)                        ? theme.fg          : "white"
    property color  cMuted:       (theme && theme.muted)                     ? theme.muted       : "#888888"
    property string cFont:        (style && style.font)                      ? style.font
                                : (theme && theme.font)                      ? theme.font        : "sans"
    property int    configuredFontSize: (style && style.fontSize !== undefined) ? style.fontSize
                                     : (theme && theme.fontSize !== undefined) ? theme.fontSize    : 16
    property string fontMetricReferenceFont: (style && style.fontMetricReferenceFont)
                                          ? style.fontMetricReferenceFont
                                          : "CaskaydiaMono Nerd Font"
    property bool   fontMetricSafetyEnabled: (style && style.fontMetricSafetyEnabled !== undefined)
                                          ? style.fontMetricSafetyEnabled : true
    property real   minFontMetricScale: (style && style.minFontMetricScale !== undefined)
                                      ? style.minFontMetricScale : 0.78
    property int    minFontSize: (style && style.minFontSize !== undefined) ? style.minFontSize : 10
    property int    maxFontSize: (style && style.maxFontSize !== undefined) ? style.maxFontSize : 30
    property real   fontMetricScale: {
        if (!fontMetricSafetyEnabled) return 1.0
        const selectedHeight = Math.max(1, selectedFontMetrics.height)
        const selectedAscent = Math.max(1, selectedFontMetrics.ascent)
        const selectedX = Math.max(1, selectedFontMetrics.xHeight)
        const refHeight = Math.max(1, referenceFontMetrics.height)
        const refAscent = Math.max(1, referenceFontMetrics.ascent)
        const refX = Math.max(1, referenceFontMetrics.xHeight)
        const heightRatio = refHeight / selectedHeight
        const ascentRatio = refAscent / selectedAscent
        const xRatio = refX / selectedX
        const ratio = Math.min(heightRatio, Math.min(ascentRatio, xRatio))
        const clampedMinScale = Math.max(0.5, Math.min(1.0, minFontMetricScale))
        return Math.max(clampedMinScale, Math.min(1.0, ratio))
    }
    property int    cFontSize: {
        const scaledSize = Math.round(configuredFontSize * fontMetricScale)
        const safeMin = Math.max(1, minFontSize)
        const safeMax = Math.max(safeMin, maxFontSize)
        return Math.max(safeMin, Math.min(safeMax, scaledSize))
    }
    property int    barHeight:    (style && style.barHeight !== undefined)    ? style.barHeight   : 30
    property int    finalPosition: (style && style.finalPosition !== undefined) ? style.finalPosition : 0
    property int    taskCharCutoff: (style && style.taskCharCutoff !== undefined) ? style.taskCharCutoff : 240
    property bool   tabSlideEnabled: (style && style.tabSlideEnabled !== undefined) ? style.tabSlideEnabled : true
    property int    tabSlideDuration: (style && style.tabSlideDuration !== undefined) ? style.tabSlideDuration : 220
    property int    tabSlideEasing: (style && style.tabSlideEasing !== undefined) ? style.tabSlideEasing : Easing.OutCubic
    property real   tabSlideDistanceMultiplier: (style && style.tabSlideDistanceMultiplier !== undefined) ? style.tabSlideDistanceMultiplier : 1.0
    property bool   tabRapidSlideEnabled: (style && style.tabRapidSlideEnabled !== undefined) ? style.tabRapidSlideEnabled : true
    property int    tabRapidSlideWindowMs: (style && style.tabRapidSlideWindowMs !== undefined) ? style.tabRapidSlideWindowMs : 200
    property int    tabRapidSlideMinDuration: (style && style.tabRapidSlideMinDuration !== undefined) ? style.tabRapidSlideMinDuration : 36
    property real   tabRapidSlideFactor: (style && style.tabRapidSlideFactor !== undefined) ? style.tabRapidSlideFactor : 0.75
    property bool   tabSlideLayerCaching: (style && style.tabSlideLayerCaching !== undefined) ? style.tabSlideLayerCaching : true
    property bool   pauseClockAnimationDuringTransitions: (style && style.pauseClockAnimationDuringTransitions !== undefined) ? style.pauseClockAnimationDuringTransitions : true
    property bool   panelSlideLayerCaching: (style && style.panelSlideLayerCaching !== undefined) ? style.panelSlideLayerCaching : false
    property bool   pauseTabPollingDuringTransitions: (style && style.pauseTabPollingDuringTransitions !== undefined) ? style.pauseTabPollingDuringTransitions : true
    property bool   forceRefreshOnOpen: (style && style.forceRefreshOnOpen !== undefined) ? style.forceRefreshOnOpen : true
    property int    forceRefreshOnOpenDelayMs: (style && style.forceRefreshOnOpenDelayMs !== undefined) ? style.forceRefreshOnOpenDelayMs : 180
    property int    mediaArtworkSpinDurationMs: (style && style.mediaArtworkSpinDurationMs !== undefined) ? style.mediaArtworkSpinDurationMs : 12000
    property int    tabCount: 4
    property int    activeTabIndex: 0
    property int    displayedTabIndex: 0
    property bool   tabSwitchAnimating: false
    property double tabLastNavTimestamp: 0
    property int    tabRapidNavStreak: 0
    property int    tabSlideDurationCurrent: Math.max(1, tabSlideDuration)
    property int    tabSlideAnimationDuration: Math.max(1, tabSlideDuration)
    property real   tabTrackTargetX: 0
    property int    tabNavDirectionHint: 0
    property bool   tabTrackSnapImmediate: false
    property bool   tabJumpProxyEnabled: false
    property int    tabJumpProxyTrackIndex: 0

    FontMetrics {
        id: referenceFontMetrics
        font.family: win.fontMetricReferenceFont
        font.pixelSize: Math.max(1, win.configuredFontSize)
    }

    FontMetrics {
        id: selectedFontMetrics
        font.family: win.cFont
        font.pixelSize: Math.max(1, win.configuredFontSize)
    }

    // Inner card layout tuning (edit these to control per-component padding and sizing)
    property int panelOuterMargin: 16
    property int panelColumnSpacing: 14
    property int panelRowSpacing: 14

    property int profilePaddingTop: 20
    property int profilePaddingLeft: 12
    property int profilePaddingRight: 18
    property int profilePaddingBottom: 8

    property int calendarPaddingTop: 18
    property int calendarPaddingLeft: 18
    property int calendarPaddingRight: 18
    property int calendarPaddingBottom: 18

    property int statsPaddingTop: 18
    property int statsPaddingLeft: 18
    property int statsPaddingRight: 18
    property int statsPaddingBottom: 18

    property int timePaddingTop: 12
    property int timePaddingLeft: 16
    property int timePaddingRight: 16
    property int timePaddingBottom: 12

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
    property real timeCardWidthWeight: 0.95
    property real timeCardHeightWeight: 0.72
    property real tasksCardWidthWeight: 1.55
    property real tasksCardHeightWeight: 1.0

    // Minimum content sizes used to keep cards from clipping when padding/margins increase.
    property int profileMinContentWidth: 180
    property int profileMinContentHeight: 134
    property int calendarMinContentWidth: 300
    property int calendarMinContentHeight: 230
    property int statsMinContentWidth: 180
    property int statsMinContentHeight: 108
    property int timeMinContentWidth: 156
    property int timeMinContentHeight: 62
    property int tasksMinContentWidth: 300
    property int tasksMinContentHeight: 130

    property int profileMinWidth: profileMinContentWidth + profilePaddingLeft + profilePaddingRight
    property int profileMinHeight: profileMinContentHeight + profilePaddingTop + profilePaddingBottom
    property int calendarMinWidth: calendarMinContentWidth + calendarPaddingLeft + calendarPaddingRight
    property int calendarMinHeight: calendarMinContentHeight + calendarPaddingTop + calendarPaddingBottom
    property int statsMinWidth: statsMinContentWidth + statsPaddingLeft + statsPaddingRight
    property int statsMinHeight: statsMinContentHeight + statsPaddingTop + statsPaddingBottom
    property int timeMinWidth: timeMinContentWidth + timePaddingLeft + timePaddingRight
    property int timeMinHeight: timeMinContentHeight + timePaddingTop + timePaddingBottom
    property int tasksMinWidth: tasksMinContentWidth + tasksPaddingLeft + tasksPaddingRight
    property int tasksMinHeight: tasksMinContentHeight + tasksPaddingTop + tasksPaddingBottom

    property int panelBaseWidth: 640
    property int panelBaseHeight: 440
    property int tabsHeaderHeight: 63
    property int tabsHeaderBottomGap: 10
    property int tabLabelToSeparatorGap: 7
    property int tabIndicatorWidth: 62
    property int tabIndicatorHeight: 2
    property int panelMinWidthFromLayout: panelOuterMargin * 2
                                        + panelColumnSpacing
                                        + Math.max(profileMinWidth, Math.max(statsMinWidth, timeMinWidth))
                                        + Math.max(calendarMinWidth, tasksMinWidth)
    property int leftColumnMinHeight: profileMinHeight + panelRowSpacing + statsMinHeight + panelRowSpacing + timeMinHeight
    property int rightColumnMinHeight: calendarMinHeight + panelRowSpacing + tasksMinHeight
    property int panelMinHeightFromLayout: panelOuterMargin * 2
                                         + Math.max(leftColumnMinHeight, rightColumnMinHeight)
    property int panelW: Math.max(panelBaseWidth, panelMinWidthFromLayout)
    property int dashboardContentH: Math.max(panelBaseHeight, panelMinHeightFromLayout)
    property int panelH: dashboardContentH + tabsHeaderHeight + tabsHeaderBottomGap
    property int visibleFinalPosition: Math.max(0, finalPosition)
    property bool inputMaskEnabled: (style && style.inputMaskEnabled !== undefined) ? style.inputMaskEnabled : true
    property int inputMaskTop: (style && style.inputMaskTop !== undefined) ? style.inputMaskTop : visibleFinalPosition
    property int inputMaskHeight: (style && style.inputMaskHeight !== undefined) ? style.inputMaskHeight : panelH
    property bool uiTransitionActive: panelSlideAnimation.running || tabSwitchAnimating

    function reloadTheme() {
        ConfigFiles.reload()
    }

    function reloadTasks() {
        if (taskView) taskView.reloadCurrent()
    }

    function tabStepDistance() {
        if (!pagesViewport) return 1
        return Math.max(1, pagesViewport.width * Math.max(0.1, tabSlideDistanceMultiplier))
    }

    function tabDurationForTarget(targetX) {
        var step = tabStepDistance()
        var remainingDistance = Math.abs(targetX - pagesTrack.x)
        var stepUnits = remainingDistance / step
        return Math.max(1, Math.round(Math.max(1, tabSlideDurationCurrent) * stepUnits))
    }

    function tabPageOpacity(index) {
        if (!tabJumpProxyEnabled) return 1.0
        var proxyNormalized = ((tabJumpProxyTrackIndex % tabCount) + tabCount) % tabCount
        if (index === proxyNormalized && index !== activeTabIndex) return 0.0
        return 1.0
    }

    function syncTabTrack(immediate) {
        var boundedIndex = Math.max(0, Math.min(activeTabIndex, tabCount - 1))
        if (boundedIndex !== activeTabIndex) {
            activeTabIndex = boundedIndex
            return
        }

        var fromIndex = displayedTabIndex
        var step = tabStepDistance()
        var targetTrackIndex = boundedIndex
        var useJumpProxy = false

        if (!immediate && tabSlideEnabled && pagesViewport && pagesViewport.width > 0) {
            var forwardSteps = (boundedIndex - fromIndex + tabCount) % tabCount
            var backwardSteps = (fromIndex - boundedIndex + tabCount) % tabCount

            if (forwardSteps > 1 && backwardSteps > 1) {
                var jumpDirection = 1
                if (tabNavDirectionHint < 0) {
                    jumpDirection = -1
                } else if (tabNavDirectionHint === 0) {
                    var rawDelta = boundedIndex - fromIndex
                    jumpDirection = rawDelta < 0 ? -1 : 1
                }
                targetTrackIndex = fromIndex + jumpDirection
                useJumpProxy = true
            }

            if (tabNavDirectionHint > 0 && fromIndex === tabCount - 1 && boundedIndex === 0) {
                targetTrackIndex = fromIndex - 1
                useJumpProxy = true
            } else if (tabNavDirectionHint < 0 && fromIndex === 0 && boundedIndex === tabCount - 1) {
                targetTrackIndex = fromIndex + 1
                useJumpProxy = true
            } else if (tabNavDirectionHint === 0) {
                var isEndpointJump = (fromIndex === 0 && boundedIndex === tabCount - 1)
                                  || (fromIndex === tabCount - 1 && boundedIndex === 0)

                if (isEndpointJump) {
                    var rawDelta = boundedIndex - fromIndex
                    var endpointDirection = rawDelta < 0 ? -1 : 1
                    targetTrackIndex = fromIndex + endpointDirection
                    useJumpProxy = true
                } else if (forwardSteps < backwardSteps) {
                    targetTrackIndex = fromIndex + forwardSteps
                } else if (backwardSteps < forwardSteps) {
                    targetTrackIndex = fromIndex - backwardSteps
                }
            }
        }

        displayedTabIndex = boundedIndex
        tabJumpProxyEnabled = useJumpProxy
        tabJumpProxyTrackIndex = targetTrackIndex
        tabTrackTargetX = -targetTrackIndex * step

        if (immediate || !tabSlideEnabled || !pagesViewport || pagesViewport.width <= 0) {
            tabSlideAnimationDuration = 1
            if (tabConveyorAnimation.running) tabConveyorAnimation.stop()
            tabTrackSnapImmediate = true
            pagesTrack.x = tabTrackTargetX
            tabTrackSnapImmediate = false
            tabSwitchAnimating = false
            tabNavDirectionHint = 0
            tabJumpProxyEnabled = false
            return
        }

        tabSlideAnimationDuration = tabDurationForTarget(tabTrackTargetX)
        pagesTrack.x = tabTrackTargetX
        tabNavDirectionHint = 0
    }

    function normalizeTabTrackAfterWrap() {
        var step = tabStepDistance()
        var normalizedX = -displayedTabIndex * step
        var shouldSnap = tabJumpProxyEnabled

        if (displayedTabIndex === 0 && pagesTrack.x < -(tabCount - 0.5) * step) {
            shouldSnap = true
        } else if (displayedTabIndex === tabCount - 1 && pagesTrack.x > 0.5 * step) {
            shouldSnap = true
        }

        if (!shouldSnap) return

        tabTrackSnapImmediate = true
        pagesTrack.x = normalizedX
        tabTrackTargetX = normalizedX
        tabTrackSnapImmediate = false
        tabJumpProxyEnabled = false
    }

    function registerTabNavigation() {
        if (!tabRapidSlideEnabled) {
            tabRapidNavStreak = 0
            tabSlideDurationCurrent = Math.max(1, tabSlideDuration)
            return
        }

        var now = Date.now()
        if (tabLastNavTimestamp > 0 && (now - tabLastNavTimestamp) <= Math.max(1, tabRapidSlideWindowMs)) {
            tabRapidNavStreak += 1
        } else {
            tabRapidNavStreak = 0
        }
        tabLastNavTimestamp = now

        var accel = 1 + (tabRapidNavStreak * Math.max(0, tabRapidSlideFactor))
        var minDuration = Math.max(1, tabRapidSlideMinDuration)
        tabSlideDurationCurrent = Math.max(minDuration, Math.round(tabSlideDuration / accel))
        tabSlideResetTimer.restart()
    }

    onActiveTabIndexChanged: syncTabTrack(false)
    onTabSlideEnabledChanged: syncTabTrack(true)
    onTabSlideDistanceMultiplierChanged: syncTabTrack(true)
    onTabSlideDurationChanged: {
        if (tabRapidNavStreak === 0) {
            tabSlideDurationCurrent = Math.max(1, tabSlideDuration)
        }
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

    Timer {
        id: openWorkTimer
        interval: win.animMs
        repeat: false
        onTriggered: {
            if (!win.open) return
            calendar.refreshToToday()
            if (win.forceRefreshOnOpen) {
                SystemInfo.setPollingPaused(false)
                MediaInfo.setPollingPaused(false)
                MediaInfo.refresh()
                forceRefreshOnOpenTimer.restart()
            }
            stage.forceActiveFocus()
        }
    }

    Timer {
        id: forceRefreshOnOpenTimer
        interval: Math.max(0, win.forceRefreshOnOpenDelayMs)
        repeat: false
        onTriggered: {
            if (!win.open || !win.forceRefreshOnOpen) return
            MediaInfo.refresh()
        }
    }

    Timer {
        id: tabSlideResetTimer
        interval: Math.max(200, win.tabRapidSlideWindowMs * 2)
        repeat: false
        onTriggered: {
            win.tabRapidNavStreak = 0
            win.tabSlideDurationCurrent = Math.max(1, win.tabSlideDuration)
        }
    }

    Item {
        id: stage
        anchors.fill: parent
        focus: true
        clip: true

        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: win.toggle()
        }

        Keys.onPressed: (e) => {
            var tabCount = win.tabCount
            var current = win.activeTabIndex
            var next = current

            if (e.key === Qt.Key_Escape) { win.toggle(); e.accepted = true }
            else if (win.visible && e.key === Qt.Key_Left) {
                win.registerTabNavigation()
                win.tabNavDirectionHint = -1
                next = (current - 1 + tabCount) % tabCount
                win.activeTabIndex = next
                e.accepted = true
            }
            else if (win.visible && e.key === Qt.Key_Right) {
                win.registerTabNavigation()
                win.tabNavDirectionHint = 1
                next = (current + 1) % tabCount
                win.activeTabIndex = next
                e.accepted = true
            }
            else if (win.visible && (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab)) {
                win.registerTabNavigation()
                if (e.key === Qt.Key_Backtab || (e.modifiers & Qt.ShiftModifier)) {
                    win.tabNavDirectionHint = -1
                    next = (current - 1 + tabCount) % tabCount
                } else {
                    win.tabNavDirectionHint = 1
                    next = (current + 1) % tabCount
                }
                win.activeTabIndex = next
                e.accepted = true
            }
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
                  id: panelSlideAnimation
                  duration: win.animMs; 
                  easing.type: Easing.OutCubic 
                  onRunningChanged: {
                      SystemInfo.setPollingPaused(running)
                      MediaInfo.setPollingPaused(running)
                  }
                } 
            }
            layer.enabled: win.panelSlideLayerCaching && panelSlideAnimation.running

            radius: 0
            color: "transparent"
            border.width: 0

            Canvas {
                id: panelBorder
                anchors.fill: parent
                visible: true
                antialiasing: true

                property color fillColor: Qt.rgba(win.cBg.r, win.cBg.g, win.cBg.b, win.cOpacity)
                property color borderColor: win.cBorder
                property int borderWidth: win.cBorderWidth
                property int radiusTopLeft: win.cRadiusTopLeft
                property int radiusTopRight: win.cRadiusTopRight
                property int radiusBottomRight: win.cRadiusBottomRight
                property int radiusBottomLeft: win.cRadiusBottomLeft
                property bool borderLeft: win.cBorderLeft
                property bool borderRight: win.cBorderRight
                property bool borderTop: win.cBorderTop
                property bool borderBottom: win.cBorderBottom

                onFillColorChanged: requestPaint()
                onBorderColorChanged: requestPaint()
                onBorderWidthChanged: requestPaint()
                onRadiusTopLeftChanged: requestPaint()
                onRadiusTopRightChanged: requestPaint()
                onRadiusBottomRightChanged: requestPaint()
                onRadiusBottomLeftChanged: requestPaint()
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

                    var bw = Math.max(0, borderWidth)
                    var half = bw / 2
                    var allSides = borderLeft && borderRight && borderTop && borderBottom

                    function drawRoundedPath(l, t, r, b, tl, tr, br, bl) {
                        ctx.beginPath()
                        ctx.moveTo(l + tl, t)
                        ctx.lineTo(r - tr, t)
                        if (tr > 0) ctx.arc(r - tr, t + tr, tr, -Math.PI / 2, 0)
                        ctx.lineTo(r, b - br)
                        if (br > 0) ctx.arc(r - br, b - br, br, 0, Math.PI / 2)
                        ctx.lineTo(l + bl, b)
                        if (bl > 0) ctx.arc(l + bl, b - bl, bl, Math.PI / 2, Math.PI)
                        ctx.lineTo(l, t + tl)
                        if (tl > 0) ctx.arc(l + tl, t + tl, tl, Math.PI, 3 * Math.PI / 2)
                        ctx.closePath()
                    }

                    var fillLeft = 0
                    var fillTop = 0
                    var fillRight = width
                    var fillBottom = height
                    var fillCornerLimit = Math.max(0, Math.min(width / 2, height / 2))
                    var fillTopLeft = Math.max(0, Math.min(radiusTopLeft, fillCornerLimit))
                    var fillTopRight = Math.max(0, Math.min(radiusTopRight, fillCornerLimit))
                    var fillBottomRight = Math.max(0, Math.min(radiusBottomRight, fillCornerLimit))
                    var fillBottomLeft = Math.max(0, Math.min(radiusBottomLeft, fillCornerLimit))

                    drawRoundedPath(fillLeft, fillTop, fillRight, fillBottom, fillTopLeft, fillTopRight, fillBottomRight, fillBottomLeft)
                    ctx.fillStyle = fillColor
                    ctx.fill()

                    if (bw <= 0)
                        return

                    var left = half
                    var top = half
                    var right = width - half
                    var bottom = height - half
                    var cornerLimit = Math.max(0, Math.min((width - bw) / 2, (height - bw) / 2))
                    var topLeft = Math.max(0, Math.min(radiusTopLeft, cornerLimit))
                    var topRight = Math.max(0, Math.min(radiusTopRight, cornerLimit))
                    var bottomRight = Math.max(0, Math.min(radiusBottomRight, cornerLimit))
                    var bottomLeft = Math.max(0, Math.min(radiusBottomLeft, cornerLimit))

                    ctx.strokeStyle = borderColor
                    ctx.lineWidth = bw
                    ctx.lineCap = "butt"
                    ctx.lineJoin = "miter"

                    if (allSides) {
                        drawRoundedPath(left, top, right, bottom, topLeft, topRight, bottomRight, bottomLeft)
                        ctx.stroke()
                        return
                    }

                    if (borderTop) {
                        ctx.beginPath()
                        ctx.moveTo(left + (borderLeft ? topLeft : 0), top)
                        ctx.lineTo(right - (borderRight ? topRight : 0), top)
                        ctx.stroke()
                    }
                    if (borderBottom) {
                        ctx.beginPath()
                        ctx.moveTo(left + (borderLeft ? bottomLeft : 0), bottom)
                        ctx.lineTo(right - (borderRight ? bottomRight : 0), bottom)
                        ctx.stroke()
                    }
                    if (borderLeft) {
                        ctx.beginPath()
                        ctx.moveTo(left, top + (borderTop ? topLeft : 0))
                        ctx.lineTo(left, bottom - (borderBottom ? bottomLeft : 0))
                        ctx.stroke()
                    }
                    if (borderRight) {
                        ctx.beginPath()
                        ctx.moveTo(right, top + (borderTop ? topRight : 0))
                        ctx.lineTo(right, bottom - (borderBottom ? bottomRight : 0))
                        ctx.stroke()
                    }

                    if (topLeft > 0 && borderTop && borderLeft) {
                        ctx.beginPath()
                        ctx.arc(left + topLeft, top + topLeft, topLeft, Math.PI, 3 * Math.PI / 2)
                        ctx.stroke()
                    }
                    if (topRight > 0 && borderTop && borderRight) {
                        ctx.beginPath()
                        ctx.arc(right - topRight, top + topRight, topRight, -Math.PI / 2, 0)
                        ctx.stroke()
                    }
                    if (bottomRight > 0 && borderBottom && borderRight) {
                        ctx.beginPath()
                        ctx.arc(right - bottomRight, bottom - bottomRight, bottomRight, 0, Math.PI / 2)
                        ctx.stroke()
                    }
                    if (bottomLeft > 0 && borderBottom && borderLeft) {
                        ctx.beginPath()
                        ctx.arc(left + bottomLeft, bottom - bottomLeft, bottomLeft, Math.PI / 2, Math.PI)
                        ctx.stroke()
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    id: tabsHeader
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
                            id: tabsRepeater
                            model: [
                                { icon: "󰕮", label: "Dashboard" },
                                { icon: "󰲸", label: "Media" },
                                { icon: "󰓅", label: "Performance" },
                                { icon: "", label: "Weather" }
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
                                        text: index === 0
                                              ? (win.activeTabIndex === index ? "󰕮" : "󰨝")
                                              : (index === 3
                                                 ? (win.activeTabIndex === index ? "󰅟" : "")
                                                 : modelData.icon)
                                        color: win.activeTabIndex === index
                                               ? win.cFg
                                               : (tabMouseArea.containsMouse ? win.cFg : win.cMuted)
                                        font.family: win.cFont
                                        font.pixelSize: win.cFontSize * 1.3
                                        scale: index === 3
                                               ? (win.activeTabIndex === index ? 1.15 : 1.40)
                                               : 1.0
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.label
                                        color: win.activeTabIndex === index
                                               ? win.cFg
                                               : (tabMouseArea.containsMouse ? win.cFg : win.cMuted)
                                        font.family: win.cFont
                                        font.pixelSize: Math.max(12, win.cFontSize - 2)
                                    }
                                }

                                MouseArea {
                                    id: tabMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (win.activeTabIndex !== index) {
                                            win.registerTabNavigation()
                                            win.tabNavDirectionHint = 0
                                            win.activeTabIndex = index
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    Rectangle {
                        property Item activeTabItem: tabsRepeater.count > win.activeTabIndex
                                                     ? tabsRepeater.itemAt(win.activeTabIndex)
                                                     : null
                        property real targetX: {
                            if (!activeTabItem) return 0
                            var mapped = activeTabItem.mapToItem(tabsHeader, 0, 0)
                            return mapped.x + (activeTabItem.width - width) / 2
                        }

                        anchors.bottom: parent.bottom
                        x: targetX
                        width: win.tabIndicatorWidth
                        height: win.tabIndicatorHeight
                        radius: 1
                        color: win.cFg
                        visible: activeTabItem !== null

                        Behavior on x {
                            NumberAnimation {
                                duration: Math.max(1, win.tabSlideDurationCurrent)
                                easing.type: win.tabSlideEasing
                            }
                        }
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

                    Item {
                        id: pagesViewport
                        anchors.fill: parent
                        anchors.leftMargin: win.panelOuterMargin
                        anchors.rightMargin: win.panelOuterMargin
                        anchors.bottomMargin: win.panelOuterMargin
                        clip: true
                        onWidthChanged: win.syncTabTrack(true)

                        Item {
                            id: pagesTrack
                            width: Math.max(parent.width * (win.tabCount + 2), win.tabStepDistance() * (win.tabCount + 2))
                            height: parent.height
                            x: win.tabTrackTargetX

                            Behavior on x {
                                enabled: !win.tabTrackSnapImmediate && win.tabSlideEnabled
                                NumberAnimation {
                                    id: tabConveyorAnimation
                                    duration: Math.max(1, win.tabSlideAnimationDuration)
                                    easing.type: win.tabSlideEasing
                                    onRunningChanged: {
                                        win.tabSwitchAnimating = running
                                        if (!running) {
                                            win.normalizeTabTrackAfterWrap()
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            parent: pagesTrack
                            x: win.tabJumpProxyTrackIndex * win.tabStepDistance()
                            width: pagesViewport.width
                            height: pagesViewport.height
                            visible: win.tabJumpProxyEnabled
                            z: 10
                            ShaderEffectSource {
                                anchors.fill: parent
                                sourceItem: win.activeTabIndex === 0 ? dashboardPage
                                           : win.activeTabIndex === 1 ? mediaPage
                                           : win.activeTabIndex === 2 ? performancePage
                                           : weatherPage
                                live: win.tabJumpProxyEnabled
                                hideSource: false
                            }
                        }

                        Item {
                            parent: pagesTrack
                            x: -win.tabStepDistance()
                            width: pagesViewport.width
                            height: pagesViewport.height
                            visible: win.tabSlideEnabled && (win.tabSwitchAnimating || tabConveyorAnimation.running)
                            ShaderEffectSource {
                                anchors.fill: parent
                                sourceItem: weatherPage
                                live: tabConveyorAnimation.running
                                hideSource: false
                            }
                        }

                        Item {
                            id: dashboardPage
                            parent: pagesTrack
                            x: 0
                            width: pagesViewport.width
                            height: pagesViewport.height
                            visible: true
                            opacity: win.tabPageOpacity(0)
                            layer.enabled: win.tabSlideLayerCaching && win.tabSwitchAnimating
                            layer.smooth: true

                            RowLayout {
                                anchors.fill: parent
                                spacing: win.panelColumnSpacing

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: win.profileCardWidthWeight
                                    Layout.minimumWidth: Math.max(win.profileMinWidth, Math.max(win.statsMinWidth, win.timeMinWidth))
                                    spacing: win.panelRowSpacing

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.preferredHeight: win.profileCardHeightWeight
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
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.preferredHeight: win.statsCardHeightWeight
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
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.preferredHeight: win.timeCardHeightWeight
                                        Layout.minimumHeight: win.timeMinHeight
                                        radius: 8
                                        clip: true
                                        color: "transparent"
                                        border.width: win.cBorderWidth
                                        border.color: win.cMuted

                                        TimeCard {
                                            anchors.fill: parent
                                            anchors.topMargin: win.timePaddingTop
                                            anchors.leftMargin: win.timePaddingLeft
                                            anchors.rightMargin: win.timePaddingRight
                                            anchors.bottomMargin: win.timePaddingBottom
                                            cFg: win.cFg
                                            cAccent: win.cAccent
                                            cSecondary: win.cSecondary
                                            cFont: win.cFont
                                            cFontSize: win.cFontSize
                                            use24Hour: AppConfig.use24Hour
                                            animationEnabled: !(win.pauseClockAnimationDuringTransitions && win.uiTransitionActive)
                                            onToggleFormatRequested: AppConfig.setUse24Hour(!AppConfig.use24Hour)
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: win.calendarCardWidthWeight
                                    Layout.minimumWidth: Math.max(win.calendarMinWidth, win.tasksMinWidth)
                                    spacing: win.panelRowSpacing

                                    Rectangle {
                                        id: calView
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.preferredHeight: win.calendarCardHeightWeight
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
                                            cAccent: win.cAccent
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
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.preferredHeight: win.tasksCardHeightWeight
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
                        }

                        Item {
                            id: mediaPage
                            parent: pagesTrack
                            x: win.tabStepDistance()
                            width: pagesViewport.width
                            height: pagesViewport.height
                            visible: true
                            opacity: win.tabPageOpacity(1)
                            layer.enabled: win.tabSlideLayerCaching && win.tabSwitchAnimating
                            layer.smooth: true

                            MediaView {
                                anchors.fill: parent
                                cBg: win.cBg
                                cFg: win.cFg
                                cAccent: win.cAccent
                                cMuted: win.cMuted
                                cSecondary: win.cSecondary
                                cBorder: win.cBorder
                                cPrimary: win.cPrimary
                                cBorderWidth: win.cBorderWidth
                                cFont: win.cFont
                                cFontSize: win.cFontSize
                                artworkSpinDurationMs: win.mediaArtworkSpinDurationMs
                                active: win.activeTabIndex === 1
                                        && (!win.pauseTabPollingDuringTransitions || (win.open && !win.uiTransitionActive))
                            }
                        }

                        Item {
                            id: performancePage
                            parent: pagesTrack
                            x: win.tabStepDistance() * 2
                            width: pagesViewport.width
                            height: pagesViewport.height
                            visible: true
                            opacity: win.tabPageOpacity(2)
                            layer.enabled: win.tabSlideLayerCaching && win.tabSwitchAnimating
                            layer.smooth: true

                            PerformanceView {
                                anchors.fill: parent
                                cBg: win.cBg
                                cFg: win.cFg
                                cMuted: win.cMuted
                                cPrimary: win.cPrimary
                                cAccent: win.cAccent
                                cSecondary: win.cSecondary
                                cGreen: win.cGreen
                                cFont: win.cFont
                                cFontSize: win.cFontSize
                                cBorderWidth: win.cBorderWidth
                            }
                        }

                        Item {
                            id: weatherPage
                            parent: pagesTrack
                            x: win.tabStepDistance() * (win.tabCount - 1)
                            width: pagesViewport.width
                            height: pagesViewport.height
                            visible: true
                            opacity: win.tabPageOpacity(3)
                            layer.enabled: win.tabSlideLayerCaching && win.tabSwitchAnimating
                            layer.smooth: true

                            WeatherView {
                                anchors.fill: parent
                                cBg: win.cBg
                                cFg: win.cFg
                                cSecondary: win.cSecondary
                                cAccent: win.cAccent
                                cMuted: win.cMuted
                                cBorder: win.cBorder
                                cPrimary: win.cPrimary
                                cBorderWidth: win.cBorderWidth
                                cFont: win.cFont
                                cFontSize: win.cFontSize
                                active: win.activeTabIndex === 3
                                        && (!win.pauseTabPollingDuringTransitions || (win.open && !win.uiTransitionActive))
                            }
                        }

                        Item {
                            parent: pagesTrack
                            x: win.tabStepDistance() * win.tabCount
                            width: pagesViewport.width
                            height: pagesViewport.height
                            visible: win.tabSlideEnabled && (win.tabSwitchAnimating || tabConveyorAnimation.running)
                            ShaderEffectSource {
                                anchors.fill: parent
                                sourceItem: dashboardPage
                                live: tabConveyorAnimation.running
                                hideSource: false
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        activeTabIndex = Math.max(0, Math.min(activeTabIndex, tabCount - 1))
        displayedTabIndex = activeTabIndex
        syncTabTrack(true)
        taskView.load(calendar.selectedKey)
    }
}

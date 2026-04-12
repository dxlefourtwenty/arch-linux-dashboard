import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root
    clip: true

    property color cBg: "#111111"
    property color cFg: "white"
    property color cSecondary: cFg
    property color cAccent: cFg
    property color cMuted: "#888888"
    property color cBorder: "#444444"
    property color cPrimary: cBorder
    property int cBorderWidth: 2
    property string cFont: "sans"
    property int cFontSize: 16
    property int sectionRadius: 8
    property int hoverAnimMs: 140

    property real latitude: 34.09
    property real longitude: -117.89
    property string locationDisplayName: "Covina, CA"
    property string locationName: "Loading..."
    property string sunriseText: "--:--"
    property string sunsetText: "--:--"
    property string locationTimeText: "--:--"
    property string currentTemp: "--°F"
    property string currentSummary: "Waiting for weather data"
    property string currentGlyph: "☀"
    property string humidityText: "--%"
    property string feelsLikeText: "--°F"
    property string windText: "-- m/h"
    property int locationUtcOffsetSeconds: 0
    property bool hasLocationTimeOffset: false
    property int refreshIntervalMs: 180000
    property int cacheTtlMs: 180000
    property string lastWeatherSnapshot: ""
    property bool requestInFlight: false
    property bool pendingRefresh: false
    property var weatherCache: ({})
    property var locationOptions: []
    property int selectedLocationIndex: 0
    property real locationSelectorWidth: 120

    ListModel { id: dailyModel }
    TextMetrics {
        id: locationNameMetrics
        font.family: root.cFont
        font.pixelSize: root.cFontSize * 0.88
    }

    function toFahrenheit(celsius) {
        return Math.round((Number(celsius) * 9 / 5) + 32)
    }

    function formatLocalTime(isoString) {
        if (!isoString) return "--:--"
        var dateObj = new Date(isoString)
        if (isNaN(dateObj.getTime())) return "--:--"
        return Qt.formatTime(dateObj, "h:mm AP")
    }

    function formatClockTextForOffset(offsetSeconds) {
        if (!isFinite(offsetSeconds)) return "--:--"

        var locationNow = new Date(Date.now() + (Number(offsetSeconds) * 1000))
        var hour = locationNow.getUTCHours()
        var minute = locationNow.getUTCMinutes()
        if (!isFinite(hour) || !isFinite(minute)) return "--:--"

        var meridiem = hour >= 12 ? "PM" : "AM"
        var hour12 = hour % 12
        if (hour12 === 0) hour12 = 12
        var minuteText = minute < 10 ? "0" + minute : "" + minute
        return hour12 + ":" + minuteText + " " + meridiem
    }

    function updateLocationSelectorWidth() {
        var maxTextWidth = 0
        if (locationOptions && locationOptions.length > 0) {
            for (var i = 0; i < locationOptions.length; ++i) {
                var entry = locationOptions[i]
                var label = entry && entry.displayName ? String(entry.displayName) : ""
                locationNameMetrics.text = label
                maxTextWidth = Math.max(maxTextWidth, locationNameMetrics.width)
            }
        }
        locationSelectorWidth = Math.max(120, Math.ceil(maxTextWidth + 28))
    }

    function resolveLocationName(timezoneName) {
        if (locationDisplayName && locationDisplayName.trim().length > 0) {
            return locationDisplayName
        }
        if (!timezoneName || timezoneName.indexOf("/") === -1) {
            return Number(latitude).toFixed(2) + ", " + Number(longitude).toFixed(2)
        }
        var parts = timezoneName.split("/")
        return parts[parts.length - 1].replace(/_/g, " ")
    }

    function formatCoordinate(value) {
        return Number(value).toFixed(4)
    }

    function locationCacheKey(lat, lon) {
        return Number(lat).toFixed(4) + "," + Number(lon).toFixed(4)
    }

    function readCacheEntry(cacheKey) {
        if (!weatherCache || !weatherCache[cacheKey]) {
            return null
        }
        var entry = weatherCache[cacheKey]
        if (!entry || !entry.payload || !isFinite(entry.fetchedAt)) {
            return null
        }
        if ((Date.now() - Number(entry.fetchedAt)) > cacheTtlMs) {
            return null
        }
        return entry
    }

    function writeCacheEntry(cacheKey, payload) {
        if (!payload) {
            return
        }
        var snapshot = weatherSnapshot(payload)
        weatherCache[cacheKey] = {
            fetchedAt: Date.now(),
            snapshot: snapshot,
            payload: payload
        }
    }

    function applyWeatherPayload(data, snapshot) {
        var nextSnapshot = snapshot || weatherSnapshot(data)
        if (nextSnapshot && nextSnapshot === lastWeatherSnapshot) {
            return
        }
        lastWeatherSnapshot = nextSnapshot
        locationName = resolveLocationName(data.timezone)

        if (data.current) {
            currentTemp = toFahrenheit(data.current.temperature_2m) + "°F"
            feelsLikeText = toFahrenheit(data.current.apparent_temperature) + "°F"
            humidityText = Math.round(Number(data.current.relative_humidity_2m)) + "%"
            windText = Number(data.current.wind_speed_10m).toFixed(1) + " m/h"
            locationUtcOffsetSeconds = Number(data.utc_offset_seconds)
            hasLocationTimeOffset = true
            locationTimeText = formatClockTextForOffset(locationUtcOffsetSeconds)
            var currentCode = Number(data.current.weather_code)
            currentGlyph = weatherGlyphForCode(currentCode)
            currentSummary = summaryForCode(currentCode)
        }

        if (data.daily) {
            sunriseText = formatLocalTime((data.daily.sunrise || [])[0])
            sunsetText = formatLocalTime((data.daily.sunset || [])[0])
        }

        populateDailyForecast(data)
    }

    function selectLocationIndex(index) {
        if (!locationOptions || index < 0 || index >= locationOptions.length) {
            return
        }
        WeatherConfig.selectIndex(index)
    }

    function populateDailyForecast(payload) {
        dailyModel.clear()
        if (!payload || !payload.daily || !payload.daily.time) return

        var times = payload.daily.time
        var maxTemps = payload.daily.temperature_2m_max || []
        var minTemps = payload.daily.temperature_2m_min || []
        var weatherCodes = payload.daily.weather_code || []
        var count = Math.min(7, times.length)

        for (var i = 0; i < count; i++) {
            var dateObj = new Date(times[i])
            var dayName = i === 0 ? "Today" : Qt.formatDate(dateObj, "ddd")
            var dateLabel = Qt.formatDate(dateObj, "MMM d")
            var maxLabel = "--"
            var minLabel = "--"

            if (i < maxTemps.length) maxLabel = toFahrenheit(maxTemps[i]) + "°"
            if (i < minTemps.length) minLabel = toFahrenheit(minTemps[i]) + "°"
            var code = i < weatherCodes.length ? Number(weatherCodes[i]) : -1
            var isRegularCloud = (code === 3 || code === 45 || code === 48)
            var isRainCloud = ((code >= 51 && code <= 67) || (code >= 80 && code <= 82))
            var isPartialCloud = (code === 1 || code === 2)

            dailyModel.append({
                day: dayName,
                dateText: dateLabel,
                high: maxLabel,
                low: minLabel,
                glyph: weatherGlyphForCode(code),
                glyphScale: glyphScaleForCode(code),
                isRegularCloud: isRegularCloud,
                cloudXOffset: isPartialCloud ? -6 : ((isRegularCloud || isRainCloud) ? -6 : 0)
            })
        }
    }

    function weatherGlyphForCode(code) {
        if (code === 0) return "☀"
        if (code === 1 || code === 2) return ""
        if (code === 3 || code === 45 || code === 48) return ""
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return ""
        if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) return "❄"
        if (code >= 95 && code <= 99) return ""
        return "☀"
    }

    function glyphScaleForCode(code) {
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return 2.0
        if (code === 0) return 3.0
        if (code === 1 || code === 2) return 2.0
        if (code === 3 || code === 45 || code === 48) return 2.0
        return 2.0
    }

    function summaryForCode(code) {
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82) || (code >= 95 && code <= 99)) return "Rain"
        if (code === 1 || code === 2 || code === 3 || code === 45 || code === 48) return "Cloudy"
        return "Clear"
    }

    function weatherSnapshot(payload) {
        if (!payload || !payload.current || !payload.daily) return ""
        return JSON.stringify({
            timezone: payload.timezone || "",
            temp: payload.current.temperature_2m,
            feels: payload.current.apparent_temperature,
            humidity: payload.current.relative_humidity_2m,
            wind: payload.current.wind_speed_10m,
            code: payload.current.weather_code,
            sunrise: (payload.daily.sunrise || [])[0] || "",
            sunset: (payload.daily.sunset || [])[0] || "",
            dailyTime: payload.daily.time || [],
            dailyMax: payload.daily.temperature_2m_max || [],
            dailyMin: payload.daily.temperature_2m_min || [],
            dailyCode: payload.daily.weather_code || []
        })
    }

    function fetchWeather(forceNetwork) {
        var shouldForceNetwork = forceNetwork === true
        if (!isFinite(latitude) || !isFinite(longitude)) {
            currentSummary = "Weather unavailable"
            return
        }

        var cacheKey = locationCacheKey(latitude, longitude)
        if (!shouldForceNetwork) {
            var cachedEntry = readCacheEntry(cacheKey)
            if (cachedEntry) {
                applyWeatherPayload(cachedEntry.payload, cachedEntry.snapshot)
                return
            }
        }

        if (requestInFlight) {
            pendingRefresh = true
            return
        }

        requestInFlight = true
        var requestKey = cacheKey
        var url = "https://api.open-meteo.com/v1/forecast"
                + "?latitude=" + latitude
                + "&longitude=" + longitude
                + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code"
                + "&daily=sunrise,sunset,temperature_2m_max,temperature_2m_min,weather_code"
                + "&wind_speed_unit=mph"
                + "&timezone=auto"
        var xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            requestInFlight = false
            if (xhr.status !== 200) {
                if (requestKey === locationCacheKey(latitude, longitude)) {
                    currentSummary = "Weather unavailable"
                }
                if (pendingRefresh) {
                    pendingRefresh = false
                    fetchWeather()
                }
                return
            }

            var data = null
            try {
                data = JSON.parse(xhr.responseText)
            } catch (err) {
                if (requestKey === locationCacheKey(latitude, longitude)) {
                    currentSummary = "Weather unavailable"
                }
                if (pendingRefresh) {
                    pendingRefresh = false
                    fetchWeather()
                }
                return
            }

            writeCacheEntry(requestKey, data)
            if (requestKey === locationCacheKey(latitude, longitude)) {
                var snapshot = weatherSnapshot(data)
                applyWeatherPayload(data, snapshot)
            }

            if (pendingRefresh) {
                pendingRefresh = false
                fetchWeather(true)
            }
        }
        xhr.send()
    }

    Timer {
        id: weatherRefreshTimer
        interval: root.refreshIntervalMs
        triggeredOnStart: true
        running: true
        repeat: true
        onTriggered: root.fetchWeather(true)
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (root.hasLocationTimeOffset) {
                root.locationTimeText = root.formatClockTextForOffset(root.locationUtcOffsetSeconds)
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            WeatherConfig.reload()
        }
    }

    Connections {
        target: WeatherConfig
        function onConfigChanged() {
            var nextOptions = WeatherConfig.locations
            var nextIndex = WeatherConfig.selectedIndex
            if (!nextOptions || nextOptions.length === 0) {
                return
            }
            if (nextIndex < 0 || nextIndex >= nextOptions.length) {
                nextIndex = 0
            }

            var selected = nextOptions[nextIndex]
            if (!selected) {
                return
            }

            var nextDisplayName = selected.displayName || locationDisplayName
            var nextLatitude = Number(selected.latitude)
            var nextLongitude = Number(selected.longitude)
            if (!isFinite(nextLatitude) || !isFinite(nextLongitude)) {
                return
            }

            var changed = selectedLocationIndex !== nextIndex
                || locationDisplayName !== nextDisplayName
                || Math.abs(latitude - nextLatitude) > 0.000001
                || Math.abs(longitude - nextLongitude) > 0.000001

            locationOptions = nextOptions
            updateLocationSelectorWidth()
            selectedLocationIndex = nextIndex
            locationDisplayName = nextDisplayName
            latitude = nextLatitude
            longitude = nextLongitude
            locationName = locationDisplayName

            if (changed || !lastWeatherSnapshot) {
                var cacheKey = locationCacheKey(latitude, longitude)
                var cachedEntry = readCacheEntry(cacheKey)
                if (cachedEntry) {
                    applyWeatherPayload(cachedEntry.payload, cachedEntry.snapshot)
                } else {
                    locationUtcOffsetSeconds = 0
                    hasLocationTimeOffset = false
                    locationTimeText = "--:--"
                    lastWeatherSnapshot = ""
                    fetchWeather(false)
                }
            }
        }
    }

    Component.onCompleted: {
        WeatherConfig.reload()
    }

    onCFontChanged: updateLocationSelectorWidth()
    onCFontSizeChanged: updateLocationSelectorWidth()

    Popup {
        id: locationSelectorPopup
        y: locationAnchor.y + locationAnchor.height + 6
        x: Math.max(0, locationAnchor.x)
        width: root.locationSelectorWidth
        padding: 4
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent | Popup.CloseOnPressOutside
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
            model: locationOptions
            spacing: 4

            delegate: ItemDelegate {
                id: locationDelegate
                required property var modelData
                required property int index
                width: locationSelectorPopup.width - 8
                height: 42
                highlighted: root.selectedLocationIndex === index
                onClicked: {
                    root.selectLocationIndex(index)
                    locationSelectorPopup.close()
                }

                contentItem: Column {
                    spacing: 1

                    Text {
                        text: modelData.displayName
                        color: locationDelegate.highlighted ? root.cBg : root.cFg
                        font.family: root.cFont
                        font.pixelSize: root.cFontSize * 0.88
                        elide: Text.ElideRight
                    }

                    Text {
                        text: root.formatCoordinate(modelData.latitude) + ", " + root.formatCoordinate(modelData.longitude)
                        color: locationDelegate.highlighted
                            ? Qt.rgba(root.cBg.r, root.cBg.g, root.cBg.b, 0.78)
                            : root.cMuted
                        font.family: root.cFont
                        font.pixelSize: root.cFontSize * 0.72
                        elide: Text.ElideRight
                    }
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

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(34, root.cFontSize + 12)

            Item {
                id: locationAnchor
                Layout.fillWidth: true
                Layout.leftMargin: 5
                Layout.topMargin: 15
                implicitHeight: locationTitle.implicitHeight

                Text {
                    id: locationTitle
                    anchors.left: parent.left
                    anchors.right: parent.right
                    text: root.locationName
                    color: locationMouseArea.containsMouse ? root.cAccent : root.cFg
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize + 2
                    font.bold: true
                    elide: Text.ElideRight
                    transformOrigin: Item.Left
                    scale: locationMouseArea.containsMouse ? 1.1 : 1.0
                    Behavior on color {
                        ColorAnimation {
                            duration: root.hoverAnimMs
                        }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration: root.hoverAnimMs
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea {
                    id: locationMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        locationSelectorPopup.open()
                    }
                }
            }

            RowLayout {
                Layout.topMargin: 15
                spacing: 12

                Row {
                    spacing: 6

                    Item {
                        width: timeIcon.implicitWidth + 1 + 2
                        height: timeIcon.implicitHeight

                        Text {
                            id: timeIcon
                            anchors.verticalCenter: parent.verticalCenter
                            text: ""
                            color: root.cAccent
                            font.family: root.cFont
                            font.pixelSize: Math.max(11, root.cFontSize - 2) * 1.8
                        }
                    }

                    Column {
                        spacing: 1

                        Text {
                            text: "Time"
                            color: root.cFg
                            font.family: root.cFont
                            font.pixelSize: Math.max(10, root.cFontSize - 4) * 1.1
                        }

                        Text {
                            text: root.locationTimeText
                            color: root.cFg
                            font.family: root.cFont
                            font.pixelSize: Math.max(11, root.cFontSize - 2)
                            font.bold: true
                        }
                    }
                }

                Row {
                    spacing: 6

                    Item {
                        width: sunriseIcon.implicitWidth + 1 + 6
                        height: sunriseIcon.implicitHeight

                        Text {
                            id: sunriseIcon
                            x: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: ""
                            color: root.cAccent
                            font.family: root.cFont
                            font.pixelSize: Math.max(11, root.cFontSize - 2) * 2.0
                        }
                    }

                    Column {
                        spacing: 1

                        Text {
                            text: "Sunrise"
                            color: root.cFg
                            font.family: root.cFont
                            font.pixelSize: Math.max(10, root.cFontSize - 4) * 1.1
                        }

                        Text {
                            text: root.sunriseText
                            color: root.cFg
                            font.family: root.cFont
                            font.pixelSize: Math.max(11, root.cFontSize - 2)
                            font.bold: true
                        }
                    }
                }

                Row {
                    Layout.rightMargin: 8
                    spacing: 6

                    Item {
                        width: sunsetIcon.implicitWidth + 1 + 10
                        height: sunsetIcon.implicitHeight

                        Text {
                            id: sunsetIcon
                            x: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: ""
                            color: root.cAccent
                            font.family: root.cFont
                            font.pixelSize: Math.max(11, root.cFontSize - 2) * 2.0
                        }
                    }

                    Column {
                        spacing: 1

                        Text {
                            text: "Sunset"
                            color: root.cFg
                            font.family: root.cFont
                            font.pixelSize: Math.max(10, root.cFontSize - 4) * 1.1
                        }

                        Text {
                            text: root.sunsetText
                            color: root.cFg
                            font.family: root.cFont
                            font.pixelSize: Math.max(11, root.cFontSize - 2)
                            font.bold: true
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 10
            Layout.preferredHeight: 112
            radius: 14
            color: Qt.rgba(root.cBg.r, root.cBg.g, root.cBg.b, 0.7)
            border.width: root.cBorderWidth
            border.color: root.cMuted

            Row {
                anchors.centerIn: parent
                spacing: 10

                Item {
                    width: (currentConditionIcon.implicitWidth * currentConditionIcon.scale) + 6
                    height: currentConditionIcon.implicitHeight * currentConditionIcon.scale

                    Text {
                        id: currentConditionIcon
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.currentGlyph
                        color: root.cFg
                        font.family: root.cFont
                        font.pixelSize: root.cFontSize * 4.6
                        scale: root.currentGlyph === "☀" ? 1.5 : 1.0
                    }
                }

                Column {
                    id: currentConditionsStack
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: root.currentTemp
                        color: root.cSecondary
                        font.family: root.cFont
                        font.pixelSize: root.cFontSize * 3.0
                        font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: root.currentSummary
                        color: root.cFg
                        font.family: root.cFont
                        font.pixelSize: Math.max(11, root.cFontSize - 2)
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [
                    { label: "Humidity", value: root.humidityText, icon: "󱡕", iconColor: root.cSecondary },
                    { label: "Feels Like", value: root.feelsLikeText, icon: "", iconColor: root.cSecondary },
                    { label: "Wind", value: root.windText, icon: "", iconColor: root.cAccent }
                ]

                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 58
                    radius: 10
                    color: Qt.rgba(root.cBg.r, root.cBg.g, root.cBg.b, 0.7)
                    border.width: root.cBorderWidth
                    border.color: root.cMuted

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Item {
                            width: metricIcon.implicitWidth + 1 + 3
                            height: metricIcon.implicitHeight

                            Text {
                                id: metricIcon
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: 5
                                text: modelData.icon
                                color: modelData.iconColor
                                font.family: root.cFont
                                font.pixelSize: Math.max(11, root.cFontSize - 2) * 1.5
                            }
                        }

                        Column {
                            spacing: 2
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: modelData.label
                                color: root.cFg
                                font.family: root.cFont
                                font.pixelSize: Math.max(11, root.cFontSize - 3)
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.value
                                color: root.cFg
                                font.family: root.cFont
                                font.pixelSize: Math.max(12, root.cFontSize - 1)
                                font.bold: true
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.topMargin: 22
            text: "7-Day Forecast"
            color: root.cFg
            font.family: root.cFont
            font.pixelSize: Math.max(12, root.cFontSize - 1) * 1.1
            font.bold: true
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6

            Repeater {
                model: dailyModel

                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10
                    color: Qt.rgba(root.cBg.r, root.cBg.g, root.cBg.b, 0.7)
                    border.width: root.cBorderWidth
                    border.color: root.cMuted

                    Column {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        anchors.topMargin: 8
                        anchors.bottomMargin: 8
                        spacing: 3

                        Item { width: 1; height: 3 }

                        Text {
                            text: model.day
                            color: root.cSecondary
                            font.family: root.cFont
                            font.pixelSize: Math.max(10, root.cFontSize - 4)
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                            elide: Text.ElideRight
                        }

                        Text {
                            text: model.dateText
                            color: root.cSecondary
                            font.family: root.cFont
                            font.pixelSize: Math.max(10, root.cFontSize - 5)
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                            elide: Text.ElideRight
                        }

                        Item { width: 1; height: 16 }

                        Text {
                            text: model.glyph
                            color: root.cFg
                            font.family: root.cFont
                            font.pixelSize: Math.max(13, root.cFontSize - 1)
                            scale: model.glyphScale
                            x: model.cloudXOffset
                            y: model.isRegularCloud ? -4 : 0
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                            elide: Text.ElideRight
                        }

                        Item { width: 1; height: 16 }

                        Text {
                            text: "Hi: " + model.high
                            color: root.cAccent
                            font.family: root.cFont
                            font.pixelSize: Math.max(10, root.cFontSize - 4)
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "Lo: " + model.low
                            color: root.cAccent
                            font.family: root.cFont
                            font.pixelSize: Math.max(10, root.cFontSize - 4)
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts

Item {
    id: root
    clip: true

    property color cBg: "#111111"
    property color cFg: "white"
    property color cSecondary: cFg
    property color cAccent: cFg
    property color cMuted: "#888888"
    property color cBorder: "#444444"
    property int cBorderWidth: 2
    property string cFont: "sans"
    property int cFontSize: 16

    property real latitude: 34.09
    property real longitude: -117.89
    property string locationDisplayName: "Covina, CA"
    property string locationName: "Loading..."
    property string sunriseText: "--:--"
    property string sunsetText: "--:--"
    property string currentTemp: "--°F"
    property string currentSummary: "Waiting for weather data"
    property string currentGlyph: "☀"
    property string humidityText: "--%"
    property string feelsLikeText: "--°F"
    property string windText: "-- km/h"
    property int refreshIntervalMs: 60000
    property string lastWeatherSnapshot: ""
    property bool requestInFlight: false
    property bool pendingRefresh: false

    ListModel { id: dailyModel }

    function toFahrenheit(celsius) {
        return Math.round((Number(celsius) * 9 / 5) + 32)
    }

    function formatLocalTime(isoString) {
        if (!isoString) return "--:--"
        var dateObj = new Date(isoString)
        if (isNaN(dateObj.getTime())) return "--:--"
        return Qt.formatTime(dateObj, "h:mm AP")
    }

    function resolveLocationName(timezoneName) {
        if (locationDisplayName && locationDisplayName.trim().length > 0) {
            return locationDisplayName
        }
        if (!timezoneName || timezoneName.indexOf("/") === -1) {
            return "34.09, -117.89"
        }
        var parts = timezoneName.split("/")
        return parts[parts.length - 1].replace(/_/g, " ")
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

            dailyModel.append({
                day: dayName,
                dateText: dateLabel,
                high: maxLabel,
                low: minLabel,
                glyph: weatherGlyphForCode(code),
                glyphScale: glyphScaleForCode(code),
                isRegularCloud: isRegularCloud,
                cloudXOffset: (isRegularCloud || isRainCloud) ? -6 : 0
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
        if (code === 1 || code === 2) return 4.0
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

    function fetchWeather() {
        if (requestInFlight) {
            pendingRefresh = true
            return
        }

        requestInFlight = true
        var url = "https://api.open-meteo.com/v1/forecast"
                + "?latitude=" + latitude
                + "&longitude=" + longitude
                + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code"
                + "&daily=sunrise,sunset,temperature_2m_max,temperature_2m_min,weather_code"
                + "&timezone=auto"
        var xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            requestInFlight = false
            if (xhr.status !== 200) {
                currentSummary = "Weather unavailable"
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
                currentSummary = "Weather unavailable"
                if (pendingRefresh) {
                    pendingRefresh = false
                    fetchWeather()
                }
                return
            }

            var snapshot = weatherSnapshot(data)
            if (snapshot && snapshot === lastWeatherSnapshot) {
                if (pendingRefresh) {
                    pendingRefresh = false
                    fetchWeather()
                }
                return
            }
            lastWeatherSnapshot = snapshot
            locationName = resolveLocationName(data.timezone)

            if (data.current) {
                currentTemp = toFahrenheit(data.current.temperature_2m) + "°F"
                feelsLikeText = toFahrenheit(data.current.apparent_temperature) + "°F"
                humidityText = Math.round(Number(data.current.relative_humidity_2m)) + "%"
                windText = Number(data.current.wind_speed_10m).toFixed(1) + " km/h"
                var currentCode = Number(data.current.weather_code)
                currentGlyph = weatherGlyphForCode(currentCode)
                currentSummary = summaryForCode(currentCode)
            }

            if (data.daily) {
                sunriseText = formatLocalTime((data.daily.sunrise || [])[0])
                sunsetText = formatLocalTime((data.daily.sunset || [])[0])
            }

            populateDailyForecast(data)

            if (pendingRefresh) {
                pendingRefresh = false
                fetchWeather()
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
        onTriggered: root.fetchWeather()
    }

    onVisibleChanged: {
        if (visible) {
            fetchWeather()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(34, root.cFontSize + 12)

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 5
                Layout.topMargin: 15
                text: root.locationName
                color: root.cFg
                font.family: root.cFont
                font.pixelSize: root.cFontSize + 2
                font.bold: true
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.topMargin: 15
                spacing: 12

                Row {
                    spacing: 6

                    Item {
                        width: sunriseIcon.implicitWidth + 1
                        height: sunriseIcon.implicitHeight

                        Text {
                            id: sunriseIcon
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
                    width: currentConditionIcon.implicitWidth + 1 + 5
                    height: currentConditionIcon.implicitHeight

                    Text {
                        id: currentConditionIcon
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.currentGlyph
                        color: root.cFg
                        font.family: root.cFont
                        font.pixelSize: root.cFontSize * 4.6
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

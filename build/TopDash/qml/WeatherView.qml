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
    property string locationName: "Loading..."
    property string sunriseText: "--:--"
    property string sunsetText: "--:--"
    property string currentTemp: "--°F"
    property string currentSummary: "Waiting for weather data"
    property string humidityText: "--%"
    property string feelsLikeText: "--°F"
    property string windText: "-- km/h"

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

    function fetchWeather() {
        var url = "https://api.open-meteo.com/v1/forecast"
                + "?latitude=" + latitude
                + "&longitude=" + longitude
                + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m"
                + "&daily=sunrise,sunset,temperature_2m_max,temperature_2m_min,weather_code"
                + "&timezone=auto"
        var xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status !== 200) {
                currentSummary = "Weather unavailable"
                return
            }

            var data = null
            try {
                data = JSON.parse(xhr.responseText)
            } catch (err) {
                currentSummary = "Weather unavailable"
                return
            }

            locationName = resolveLocationName(data.timezone)

            if (data.current) {
                currentTemp = toFahrenheit(data.current.temperature_2m) + "°F"
                feelsLikeText = toFahrenheit(data.current.apparent_temperature) + "°F"
                humidityText = Math.round(Number(data.current.relative_humidity_2m)) + "%"
                windText = Number(data.current.wind_speed_10m).toFixed(1) + " km/h"
                currentSummary = "Current Conditions"
            }

            if (data.daily) {
                sunriseText = formatLocalTime((data.daily.sunrise || [])[0])
                sunsetText = formatLocalTime((data.daily.sunset || [])[0])
            }

            populateDailyForecast(data)
        }
        xhr.send()
    }

    Timer {
        interval: 600000
        running: true
        repeat: true
        onTriggered: root.fetchWeather()
    }

    Component.onCompleted: fetchWeather()

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(34, root.cFontSize + 12)

            Text {
                Layout.fillWidth: true
                text: root.locationName
                color: root.cFg
                font.family: root.cFont
                font.pixelSize: root.cFontSize + 2
                font.bold: true
                elide: Text.ElideRight
            }

            RowLayout {
                spacing: 12

                Text {
                    text: "Sunrise " + root.sunriseText
                    color: root.cFg
                    font.family: root.cFont
                    font.pixelSize: Math.max(11, root.cFontSize - 2)
                }

                Text {
                    text: "Sunset " + root.sunsetText
                    color: root.cFg
                    font.family: root.cFont
                    font.pixelSize: Math.max(11, root.cFontSize - 2)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 112
            radius: 14
            color: Qt.rgba(root.cBg.r, root.cBg.g, root.cBg.b, 0.7)
            border.width: root.cBorderWidth
            border.color: root.cMuted

            Column {
                anchors.centerIn: parent
                spacing: 2

                Row {
                    spacing: 10
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        text: "☀"
                        color: root.cFg
                        font.family: root.cFont
                        font.pixelSize: root.cFontSize * 2.3
                    }

                    Text {
                        text: root.currentTemp
                        color: root.cFg
                        font.family: root.cFont
                        font.pixelSize: root.cFontSize * 2.5
                        font.bold: true
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.currentSummary
                    color: root.cFg
                    font.family: root.cFont
                    font.pixelSize: Math.max(11, root.cFontSize - 2)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [
                    { label: "Humidity", value: root.humidityText },
                    { label: "Feels Like", value: root.feelsLikeText },
                    { label: "Wind", value: root.windText }
                ]

                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 58
                    radius: 10
                    color: Qt.rgba(root.cBg.r, root.cBg.g, root.cBg.b, 0.7)
                    border.width: root.cBorderWidth
                    border.color: root.cMuted

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 12
                        spacing: 2

                        Text {
                            text: modelData.label
                            color: root.cFg
                            font.family: root.cFont
                            font.pixelSize: Math.max(11, root.cFontSize - 3)
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.value
                            color: root.cFg
                            font.family: root.cFont
                            font.pixelSize: Math.max(12, root.cFontSize - 1)
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "7-Day Forecast"
            color: root.cFg
            font.family: root.cFont
            font.pixelSize: Math.max(12, root.cFontSize - 1)
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

import QtQuick
import WeatherApp

Rectangle {
    id: chartsRoot
    radius: 16
    color: Theme.surface
    border.color: Theme.border
    border.width: 1
    property var dailyData: weatherController.dailyForecast

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Text { text: "7\u5929\u5929\u6c14\u9884\u62a5"; font.pixelSize: 18; font.bold: true; color: Theme.textPrimary }

        Row {
            width: parent.width
            height: parent.height - 40
            spacing: 16

            Rectangle {
                width: (parent.width - 16) / 2
                height: parent.height
                radius: 12
                color: Theme.cardBg

                Column {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4
                    Text { text: "\u6c14\u6e29\u8d8b\u52bf (\u00b0C)"; color: Theme.textPrimary; font.pixelSize: 13; font.bold: true }
                    Row {
                        spacing: 12
                        Rectangle { width: 12; height: 3; radius: 1; color: Theme.chartTempMax }
                        Text { text: "\u6700\u9ad8\u6e29"; color: Theme.textSecondary; font.pixelSize: 11 }
                        Rectangle { width: 12; height: 3; radius: 1; color: Theme.chartLine }
                        Text { text: "\u6700\u4f4e\u6e29"; color: Theme.textSecondary; font.pixelSize: 11 }
                    }
                    Canvas {
                        id: tempCanvas
                        width: parent.width
                        height: parent.height - 50
                        onPaint: { chartsRoot.paintTempChart(getContext("2d")) }
                    }
                }
            }

            Rectangle {
                width: (parent.width - 16) / 2
                height: parent.height
                radius: 12
                color: Theme.cardBg

                Column {
                    anchors.fill: parent
                    anchors.margins: 8
                    Text { text: "7\u5929\u6e7f\u5ea6 (%)"; color: Theme.textPrimary; font.pixelSize: 13; font.bold: true }
                    Canvas {
                        id: humidityCanvas
                        width: parent.width
                        height: parent.height - 30
                        onPaint: { chartsRoot.paintHumidityChart(getContext("2d")) }
                        Component.onCompleted: requestPaint()
                    }
                }
            }
        }
    }

    function chartColor(c) {
        return Qt.color(c).toString()
    }

    function labelColor() {
        return chartColor(Theme.isDark ? "#f0f0f0" : "#212121")
    }

    function paintTempChart(ctx) {
        ctx.clearRect(0, 0, tempCanvas.width, tempCanvas.height)
        if (!dailyData || dailyData.length === 0) return
        var w = tempCanvas.width, h = tempCanvas.height
        var padL = 36, padT = 18, padB = 28
        var chartW = w - padL - 12, chartH = h - padT - padB
        var minT = 100, maxT = -100
        for (var i = 0; i < dailyData.length; i++) {
            minT = Math.min(minT, dailyData[i].tempMin)
            maxT = Math.max(maxT, dailyData[i].tempMax)
        }
        minT = Math.floor(minT - 2); maxT = Math.ceil(maxT + 2)
        if (maxT === minT) maxT = minT + 1
        var maxColor = chartColor(Theme.chartTempMax)
        var minColor = chartColor(Theme.chartLine)
        var maxPoints = []
        var minPoints = []

        function drawLine(key, color, points) {
            ctx.strokeStyle = color; ctx.lineWidth = 2.5; ctx.beginPath()
            for (var j = 0; j < dailyData.length; j++) {
                var x = padL + chartW * j / Math.max(dailyData.length - 1, 1)
                var y = padT + chartH * (1 - (dailyData[j][key] - minT) / (maxT - minT))
                points.push({ x: x, y: y, val: dailyData[j][key] })
                if (j === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
            }
            ctx.stroke()
        }
        drawLine("tempMax", maxColor, maxPoints)
        drawLine("tempMin", minColor, minPoints)

        ctx.font = "bold 10px sans-serif"
        ctx.textAlign = "center"
        ctx.fillStyle = labelColor()
        for (var k = 0; k < maxPoints.length; k++) {
            var maxLabel = Math.round(maxPoints[k].val) + "\u00b0"
            var maxY = maxPoints[k].y - 5
            if (maxY < 12) maxY = maxPoints[k].y + 14
            ctx.textBaseline = "bottom"
            ctx.fillText(maxLabel, maxPoints[k].x, maxY)
        }
        for (var m = 0; m < minPoints.length; m++) {
            var minLabel = Math.round(minPoints[m].val) + "\u00b0"
            var minY = minPoints[m].y + 14
            if (minY > h - 6) minY = minPoints[m].y - 5
            ctx.textBaseline = "top"
            ctx.fillText(minLabel, minPoints[m].x, minY)
        }
    }

    function paintHumidityChart(ctx) {
        ctx.clearRect(0, 0, humidityCanvas.width, humidityCanvas.height)
        if (!dailyData || dailyData.length === 0) return
        var w = humidityCanvas.width, h = humidityCanvas.height
        var padL = 36, padT = 8, padB = 28
        var chartW = w - padL - 12, chartH = h - padT - padB
        var gap = chartW / dailyData.length, barW = gap * 0.6
        ctx.fillStyle = chartColor(Theme.chartBar)
        for (var i = 0; i < dailyData.length; i++) {
            var hum = dailyData[i].humidity || 0
            var bx = padL + gap * i + (gap - barW) / 2
            var bh = chartH * hum / 100
            ctx.fillRect(bx, padT + chartH - bh, barW, bh)
        }
    }

    Connections {
        target: weatherController
        function onWeatherChanged() {
            dailyData = weatherController.dailyForecast
            tempCanvas.requestPaint()
            humidityCanvas.requestPaint()
        }
    }

    Connections {
        target: settingsManager
        function onDarkThemeChanged() {
            tempCanvas.requestPaint()
            humidityCanvas.requestPaint()
        }
    }
}
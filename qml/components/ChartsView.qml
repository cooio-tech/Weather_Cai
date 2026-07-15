import QtQuick
import QtQuick.Layouts
import WeatherApp

Rectangle {
    id: chartsRoot
    radius: 16
    color: Theme.surface
    border.color: Theme.border
    border.width: 1
    property var dailyData: weatherController.dailyForecast
    property real animProgress: 0
    readonly property real chartPadL: 18
    readonly property real chartPadR: 16
    readonly property real tempLineNudgeX: 4
    readonly property real tempPadB: 20
    property int activeDay: {
        if (weatherController.hoverDayIndex >= 0)
            return weatherController.hoverDayIndex
        return weatherController.selectedDayIndex
    }

    NumberAnimation {
        id: chartAnim
        target: chartsRoot
        property: "animProgress"
        from: 0
        to: 1
        duration: settingsManager.animationsEnabled ? 1700 : 1
        easing.type: Easing.OutQuad
    }

    onAnimProgressChanged: {
        if (tempCanvas) tempCanvas.requestPaint()
        if (humidityCanvas) humidityCanvas.requestPaint()
    }

    onActiveDayChanged: {
        if (tempCanvas) tempCanvas.requestPaint()
        if (humidityCanvas) humidityCanvas.requestPaint()
    }

    function replayAnim() {
        chartAnim.stop()
        animProgress = 0
        chartAnim.start()
    }

    function formatDate(dateStr) {
        if (!dateStr || dateStr.length < 10) return dateStr || ""
        return dateStr.substring(5, 10)
    }

    function dayIndexFromX(x, width) {
        if (!dailyData || dailyData.length === 0) return -1
        var padL = chartPadL + tempLineNudgeX
        var chartW = Math.max(1, width - padL - chartPadR)
        var n = dailyData.length
        if (n === 1) return 0
        var t = (x - padL) / chartW
        var idx = Math.round(t * (n - 1))
        if (idx < 0) idx = 0
        if (idx > n - 1) idx = n - 1
        return idx
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "7\u5929\u5929\u6c14\u9884\u62a5"
                font.pixelSize: 18
                font.bold: true
                color: Theme.textPrimary
                Layout.fillWidth: true
            }
            Text {
                visible: chartsRoot.activeDay >= 0 && dailyData && chartsRoot.activeDay < dailyData.length
                text: {
                    if (chartsRoot.activeDay < 0 || !dailyData) return ""
                    var d = dailyData[chartsRoot.activeDay]
                    return chartsRoot.formatDate(d.date) + "  "
                           + Math.round(d.tempMin) + "\u00b0~" + Math.round(d.tempMax) + "\u00b0  "
                           + (d.textDay || "")
                }
                color: Theme.selectedDay
                font.pixelSize: 12
                elide: Text.ElideRight
                Layout.maximumWidth: parent.width * 0.55
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: Theme.cardBg

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 2

                    Text {
                        text: "\u6c14\u6e29\u8d8b\u52bf (\u00b0C)"
                        color: Theme.textPrimary
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Row {
                        spacing: 12
                        Rectangle { width: 12; height: 3; radius: 1; color: Theme.chartTempMax; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "\u6700\u9ad8\u6e29"; color: Theme.textSecondary; font.pixelSize: 11 }
                        Rectangle { width: 12; height: 3; radius: 1; color: Theme.chartLine; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "\u6700\u4f4e\u6e29"; color: Theme.textSecondary; font.pixelSize: 11 }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Canvas {
                            id: tempCanvas
                            anchors.fill: parent
                            onPaint: { chartsRoot.paintTempChart(getContext("2d")) }
                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPositionChanged: function(mouse) {
                                weatherController.setHoverDayIndex(
                                    chartsRoot.dayIndexFromX(mouse.x, tempCanvas.width))
                            }
                            onExited: weatherController.setHoverDayIndex(-1)
                            onClicked: function(mouse) {
                                var idx = chartsRoot.dayIndexFromX(mouse.x, tempCanvas.width)
                                weatherController.setSelectedDayIndex(idx)
                            }
                        }
                    }

                    Item {
                        id: dayAlignStrip
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        Layout.topMargin: 6
                        visible: dailyData && dailyData.length > 0

                        readonly property real effectivePadL: chartsRoot.chartPadL + chartsRoot.tempLineNudgeX
                        readonly property real chartW: Math.max(0, width - effectivePadL - chartsRoot.chartPadR)

                        Repeater {
                            model: dailyData ? dailyData.length : 0
                            Item {
                                width: 36
                                height: dayAlignStrip.height
                                x: {
                                    var n = dailyData.length
                                    var cx = dayAlignStrip.effectivePadL
                                            + dayAlignStrip.chartW * index / Math.max(n - 1, 1)
                                    return cx - width / 2
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 30
                                    height: parent.height
                                    radius: 8
                                    color: chartsRoot.activeDay === index
                                           ? (Theme.isDark ? "#335a8ec4" : "#3342a5f5")
                                           : "transparent"
                                }

                                Column {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    spacing: 2

                                    WeatherIcon {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 20
                                        height: 20
                                        iconCode: dailyData[index].iconDay || ""
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: chartsRoot.formatDate(dailyData[index].date)
                                        font.pixelSize: 9
                                        color: chartsRoot.activeDay === index
                                               ? Theme.selectedDay : Theme.textSecondary
                                        font.bold: chartsRoot.activeDay === index
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: weatherController.setHoverDayIndex(index)
                                    onExited: weatherController.setHoverDayIndex(-1)
                                    onClicked: weatherController.setSelectedDayIndex(index)
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: Theme.cardBg

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4
                    Text {
                        text: "7\u5929\u6e7f\u5ea6 (%)"
                        color: Theme.textPrimary
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Canvas {
                            id: humidityCanvas
                            anchors.fill: parent
                            onPaint: { chartsRoot.paintHumidityChart(getContext("2d")) }
                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()
                            Component.onCompleted: requestPaint()
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPositionChanged: function(mouse) {
                                if (!dailyData || dailyData.length === 0) return
                                var padL = chartsRoot.chartPadL
                                var chartW = Math.max(1, humidityCanvas.width - padL - chartsRoot.chartPadR)
                                var gap = chartW / dailyData.length
                                var idx = Math.floor((mouse.x - padL) / gap)
                                if (idx < 0) idx = 0
                                if (idx > dailyData.length - 1) idx = dailyData.length - 1
                                weatherController.setHoverDayIndex(idx)
                            }
                            onExited: weatherController.setHoverDayIndex(-1)
                            onClicked: function(mouse) {
                                if (!dailyData || dailyData.length === 0) return
                                var padL = chartsRoot.chartPadL
                                var chartW = Math.max(1, humidityCanvas.width - padL - chartsRoot.chartPadR)
                                var gap = chartW / dailyData.length
                                var idx = Math.floor((mouse.x - padL) / gap)
                                if (idx < 0) idx = 0
                                if (idx > dailyData.length - 1) idx = dailyData.length - 1
                                weatherController.setSelectedDayIndex(idx)
                            }
                        }
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
        var padL = chartsRoot.chartPadL + chartsRoot.tempLineNudgeX
        var padT = 18, padB = chartsRoot.tempPadB, padR = chartsRoot.chartPadR
        var chartW = w - padL - padR, chartH = h - padT - padB
        if (chartH < 20) return
        var minT = 100, maxT = -100
        for (var i = 0; i < dailyData.length; i++) {
            minT = Math.min(minT, dailyData[i].tempMin)
            maxT = Math.max(maxT, dailyData[i].tempMax)
        }
        minT = Math.floor(minT - 2); maxT = Math.ceil(maxT + 2)
        if (maxT === minT) maxT = minT + 1
        var maxColor = chartColor(Theme.chartTempMax)
        var minColor = chartColor(Theme.chartLine)
        var p = Math.max(0, Math.min(1, chartsRoot.animProgress))
        var maxPoints = []
        var minPoints = []
        var n = dailyData.length

        for (var j = 0; j < n; j++) {
            var x = padL + chartW * j / Math.max(n - 1, 1)
            var yMaxFull = padT + chartH * (1 - (dailyData[j].tempMax - minT) / (maxT - minT))
            var yMinFull = padT + chartH * (1 - (dailyData[j].tempMin - minT) / (maxT - minT))
            var yBase = padT + chartH
            maxPoints.push({ x: x, y: yBase + (yMaxFull - yBase) * p, val: dailyData[j].tempMax })
            minPoints.push({ x: x, y: yBase + (yMinFull - yBase) * p, val: dailyData[j].tempMin })
        }

        // Area between max/min lines
        if (maxPoints.length > 1) {
            ctx.beginPath()
            ctx.moveTo(maxPoints[0].x, maxPoints[0].y)
            for (var a = 1; a < maxPoints.length; a++)
                ctx.lineTo(maxPoints[a].x, maxPoints[a].y)
            for (var b = minPoints.length - 1; b >= 0; b--)
                ctx.lineTo(minPoints[b].x, minPoints[b].y)
            ctx.closePath()
            ctx.fillStyle = Theme.isDark ? "rgba(100,149,237,0.14)" : "rgba(33,150,243,0.12)"
            ctx.globalAlpha = p
            ctx.fill()
            ctx.globalAlpha = 1
        }

        // Highlight selected / hovered day
        var hi = chartsRoot.activeDay
        if (hi >= 0 && hi < n) {
            var hx = maxPoints[hi].x
            ctx.strokeStyle = chartColor(Theme.selectedDay)
            ctx.lineWidth = 1
            ctx.setLineDash([4, 4])
            ctx.beginPath()
            ctx.moveTo(hx, padT)
            ctx.lineTo(hx, padT + chartH)
            ctx.stroke()
            ctx.setLineDash([])
            ctx.beginPath()
            ctx.arc(hx, maxPoints[hi].y, 5, 0, Math.PI * 2)
            ctx.fillStyle = maxColor
            ctx.fill()
            ctx.beginPath()
            ctx.arc(hx, minPoints[hi].y, 5, 0, Math.PI * 2)
            ctx.fillStyle = minColor
            ctx.fill()
        }

        function strokePts(points, color) {
            ctx.strokeStyle = color
            ctx.lineWidth = 2.5
            ctx.lineJoin = "round"
            ctx.lineCap = "round"
            ctx.beginPath()
            for (var k = 0; k < points.length; k++) {
                if (k === 0) ctx.moveTo(points[k].x, points[k].y)
                else ctx.lineTo(points[k].x, points[k].y)
            }
            ctx.stroke()
        }
        strokePts(maxPoints, maxColor)
        strokePts(minPoints, minColor)

        ctx.globalAlpha = p
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
            if (minY > h - 4) minY = minPoints[m].y - 5
            ctx.textBaseline = "top"
            ctx.fillText(minLabel, minPoints[m].x, minY)
        }
        ctx.globalAlpha = 1
    }

    function paintHumidityChart(ctx) {
        ctx.clearRect(0, 0, humidityCanvas.width, humidityCanvas.height)
        if (!dailyData || dailyData.length === 0) return
        var w = humidityCanvas.width, h = humidityCanvas.height
        var padL = chartsRoot.chartPadL, padT = 8, padB = 12, padR = chartsRoot.chartPadR
        var chartW = w - padL - padR, chartH = h - padT - padB
        if (chartH < 20) return
        var n = dailyData.length
        var gap = chartW / n, barW = gap * 0.55
        var base = chartColor(Theme.chartBar)
        var hi = chartsRoot.activeDay

        for (var i = 0; i < n; i++) {
            var hum = parseFloat(dailyData[i].humidity) || 0
            var staggerMax = 0.32
            var start = (n <= 1) ? 0 : staggerMax * i / (n - 1)
            var local = Math.max(0, Math.min(1, (chartsRoot.animProgress - start) / (1 - staggerMax)))
            local = local * local * (3 - 2 * local)
            var bx = padL + gap * i + (gap - barW) / 2
            var bh = chartH * (hum / 100) * local
            var radius = Math.min(4, barW / 2)

            ctx.fillStyle = (i === hi) ? chartColor(Theme.selectedDay) : base
            ctx.globalAlpha = (i === hi ? 0.95 : 0.85) * local
            roundTopBar(ctx, bx, padT + chartH - bh, barW, bh, radius)
            ctx.fill()

            if (local > 0.82 && hum > 0) {
                ctx.globalAlpha = Math.min(1, (local - 0.82) / 0.18)
                ctx.fillStyle = labelColor()
                ctx.font = (i === hi ? "bold " : "") + "10px sans-serif"
                ctx.textAlign = "center"
                ctx.textBaseline = "bottom"
                ctx.fillText(Math.round(hum) + "%", bx + barW / 2, padT + chartH - bh - 2)
            }
        }
        ctx.globalAlpha = 1
    }

    function roundTopBar(ctx, x, y, w, h, r) {
        if (h <= 0) {
            ctx.beginPath()
            return
        }
        if (r > h) r = h
        ctx.beginPath()
        ctx.moveTo(x, y + h)
        ctx.lineTo(x, y + r)
        ctx.quadraticCurveTo(x, y, x + r, y)
        ctx.lineTo(x + w - r, y)
        ctx.quadraticCurveTo(x + w, y, x + w, y + r)
        ctx.lineTo(x + w, y + h)
        ctx.closePath()
    }

    Connections {
        target: weatherController
        function onWeatherChanged() {
            dailyData = weatherController.dailyForecast
            chartsRoot.replayAnim()
        }
        function onSelectionChanged() {
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

    Component.onCompleted: {
        if (dailyData && dailyData.length > 0)
            replayAnim()
        else
            animProgress = 1
    }
}

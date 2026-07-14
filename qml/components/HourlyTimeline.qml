import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import WeatherApp

Rectangle {
    id: hourlyRoot
    radius: 16
    color: Theme.surface
    border.color: Theme.border
    border.width: 1
    property bool expanded: true
    property var hourlyData: weatherController.hourlyForecast
    property bool hasData: hourlyData && hourlyData.length > 0
    readonly property int colWidth: 56

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: "24\u5c0f\u65f6\u9010\u5c0f\u65f6\u9884\u62a5"
                font.pixelSize: 13
                font.bold: true
                color: Theme.textPrimary
            }
            Row {
                spacing: 10
                visible: hourlyRoot.hasData
                Layout.alignment: Qt.AlignVCenter
                Rectangle { width: 10; height: 2; radius: 1; color: Theme.chartTempMax; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "\u6c14\u6e29"; color: Theme.textSecondary; font.pixelSize: 10 }
                Rectangle { width: 10; height: 6; radius: 1; color: Theme.chartLine; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "\u964d\u6c34"; color: Theme.textSecondary; font.pixelSize: 10 }
                Rectangle { width: 10; height: 2; radius: 1; color: Theme.chartWind; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "\u98ce\u901f"; color: Theme.textSecondary; font.pixelSize: 10 }
            }
            Item { Layout.fillWidth: true }
            ToolButton {
                text: hourlyRoot.expanded ? "\u25b2" : "\u25bc"
                font.pixelSize: 10
                implicitWidth: 28
                implicitHeight: 24
                onClicked: hourlyRoot.expanded = !hourlyRoot.expanded
            }
        }

        Text {
            Layout.fillWidth: true
            visible: hourlyRoot.expanded && !hourlyRoot.hasData
            text: "\u6682\u65e0\u9010\u5c0f\u65f6\u6570\u636e\uff0c\u8bf7\u641c\u7d22\u57ce\u5e02\u6216\u6e05\u7406\u7f13\u5b58\u540e\u91cd\u8bd5"
            font.pixelSize: 12
            color: Theme.textSecondary
            horizontalAlignment: Text.AlignHCenter
            Layout.preferredHeight: 48
        }

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: hourlyRoot.expanded && hourlyRoot.hasData
            clip: true
            interactive: true
            flickableDirection: Flickable.HorizontalFlick
            contentWidth: Math.max(width, hourlyData.length * hourlyRoot.colWidth)
            contentHeight: height
            boundsBehavior: Flickable.StopAtBounds

            Item {
                width: flick.contentWidth
                height: flick.height

                Canvas {
                    id: hourlyCanvas
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: footerCol.top
                    onPaint: hourlyRoot.paintChart(getContext("2d"))
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    Component.onCompleted: requestPaint()
                }

                Column {
                    id: footerCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    spacing: 0

                    Row {
                        spacing: 0
                        Repeater {
                            model: hourlyData.length
                            Item {
                                width: hourlyRoot.colWidth
                                height: 24
                                Text {
                                    anchors.centerIn: parent
                                    text: hourlyRoot.iconGlyph(hourlyData[index].icon)
                                    font.pixelSize: 15
                                    color: Theme.textPrimary
                                }
                            }
                        }
                    }

                    Row {
                        spacing: 0
                        Repeater {
                            model: hourlyData.length
                            Item {
                                width: hourlyRoot.colWidth
                                height: 20
                                Text {
                                    anchors.centerIn: parent
                                    width: parent.width - 4
                                    horizontalAlignment: Text.AlignHCenter
                                    text: hourlyRoot.formatHour(hourlyData[index].fxTime)
                                    font.pixelSize: 10
                                    color: Theme.textSecondary
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            ScrollBar.horizontal: ScrollBar {
                policy: ScrollBar.AsNeeded
                height: 6
            }
        }
    }

    Connections {
        target: weatherController
        function onWeatherChanged() { hourlyCanvas.requestPaint() }
    }

    Connections {
        target: settingsManager
        function onDarkThemeChanged() { hourlyCanvas.requestPaint() }
    }

    function chartColor(c) {
        return Qt.color(c).toString()
    }

    function formatHour(fxTime) {
        if (!fxTime || fxTime.length < 16) return fxTime || ""
        return fxTime.substring(11, 16)
    }

    function iconGlyph(icon) {
        var code = parseInt(icon)
        if (isNaN(code)) return "\u2601"
        if (code >= 400 && code <= 499) return "\u2744"
        if (code >= 300 && code <= 399) return "\u2602"
        if (code >= 150 && code <= 199) return "\u2601"
        if (code >= 100 && code <= 103) return "\u2600"
        if (code >= 104 && code <= 149) return "\u26C5"
        return "\u2601"
    }

    function paintChart(ctx) {
        ctx.clearRect(0, 0, hourlyCanvas.width, hourlyCanvas.height)
        if (!hourlyData || hourlyData.length === 0) return
        var w = hourlyCanvas.width, h = hourlyCanvas.height
        var padT = 16, padB = 6, padL = 0, chartH = h - padT - padB
        if (chartH < 20) return
        var n = hourlyData.length
        var gap = hourlyRoot.colWidth
        var minT = 100, maxT = -100, maxWind = 1
        for (var i = 0; i < n; i++) {
            minT = Math.min(minT, hourlyData[i].temp)
            maxT = Math.max(maxT, hourlyData[i].temp)
            maxWind = Math.max(maxWind, hourlyData[i].windSpeed || 0)
        }
        minT = Math.floor(minT - 1); maxT = Math.ceil(maxT + 1)
        if (maxT === minT) maxT = minT + 1

        for (var b = 0; b < n; b++) {
            var pop = hourlyData[b].pop || 0
            var bx = padL + gap * b + gap * 0.2
            var bw = gap * 0.6
            var bh = chartH * pop / 100
            ctx.fillStyle = Theme.isDark ? "rgba(90,138,176,0.35)" : "rgba(33,150,243,0.3)"
            ctx.fillRect(bx, padT + chartH - bh, bw, bh)
        }

        ctx.strokeStyle = chartColor(Theme.chartWind); ctx.lineWidth = 1.5; ctx.beginPath()
        for (var wj = 0; wj < n; wj++) {
            var wx = padL + gap * wj + gap / 2
            var wy = padT + chartH * (1 - (hourlyData[wj].windSpeed || 0) / Math.max(maxWind, 1))
            if (wj === 0) ctx.moveTo(wx, wy); else ctx.lineTo(wx, wy)
        }
        ctx.stroke()

        ctx.strokeStyle = chartColor(Theme.chartTempMax); ctx.lineWidth = 2; ctx.beginPath()
        var points = []
        for (var j = 0; j < n; j++) {
            var x = padL + gap * j + gap / 2
            var y = padT + chartH * (1 - (hourlyData[j].temp - minT) / (maxT - minT))
            points.push({ x: x, y: y, temp: hourlyData[j].temp })
            if (j === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
        }
        ctx.stroke()

        ctx.fillStyle = Theme.isDark ? "#f0f0f0" : "#212121"
        ctx.font = "bold 11px sans-serif"
        ctx.textAlign = "center"
        ctx.textBaseline = "bottom"
        for (var k = 0; k < points.length; k++) {
            var label = Math.round(points[k].temp) + "\u00b0"
            var ly = points[k].y - 5
            if (ly < 12) ly = points[k].y + 14
            ctx.fillText(label, points[k].x, ly)
        }

        ctx.fillStyle = chartColor(Theme.chartTempMax)
        for (var d = 0; d < points.length; d++) {
            ctx.beginPath()
            ctx.arc(points[d].x, points[d].y, 2.5, 0, Math.PI * 2)
            ctx.fill()
        }
    }
}
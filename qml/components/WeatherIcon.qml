import QtQuick
import WeatherApp

Item {
    id: root
    width: 22
    height: 22
    property string iconCode: ""
    property string weatherType: ""
    // soft：图表用；gray：桌面小组件用
    property string cloudStyle: "soft"

    readonly property string kind: {
        if (weatherType.length > 0)
            return weatherType
        var code = parseInt(iconCode)
        if (isNaN(code))
            return "cloudy"
        if (code >= 400 && code <= 499)
            return "snow"
        if (code >= 300 && code <= 399)
            return "rain"
        if (code >= 200 && code <= 299)
            return "thunder"
        // 100/150 晴；101–103/151–153 多云类；104/154 阴
        if (code === 100 || code === 150)
            return "sunny"
        if ((code >= 101 && code <= 103) || (code >= 151 && code <= 153))
            return "partly"
        if (code === 104 || code === 154 || (code >= 104 && code <= 149))
            return "cloudy"
        if (code >= 500 && code <= 515)
            return "fog"
        return "cloudy"
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        onPaint: root.paintIcon(getContext("2d"))
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    onKindChanged: canvas.requestPaint()
    onCloudStyleChanged: canvas.requestPaint()
    Connections {
        target: settingsManager
        function onDarkThemeChanged() { canvas.requestPaint() }
    }
    Component.onCompleted: canvas.requestPaint()

    function paintIcon(ctx) {
        var w = canvas.width, h = canvas.height
        ctx.clearRect(0, 0, w, h)
        ctx.save()
        ctx.scale(w / 24, h / 24)

        switch (kind) {
        case "sunny":
            drawSun(ctx); break
        case "partly":
            drawSunSmall(ctx)
            drawCloud(ctx, 1, 8); break
        case "cloudy":
            drawCloud(ctx, 2, 6); break
        case "rain":
            drawCloud(ctx, 2, 4)
            drawRain(ctx); break
        case "thunder":
            drawCloud(ctx, 2, 4)
            drawBolt(ctx); break
        case "snow":
            drawCloud(ctx, 2, 4)
            drawSnow(ctx); break
        case "fog":
            drawFog(ctx); break
        default:
            drawCloud(ctx, 2, 6); break
        }
        ctx.restore()
    }

    function cloudFill() {
        if (cloudStyle === "gray")
            return Theme.isDark ? "#7d8b97" : "#5f6f7a"
        return Theme.isDark ? "#edf2f7" : "#c5d0d8"
    }

    function sunFill() {
        return Theme.isDark ? "#ffd54f" : "#f9a825"
    }

    function rainFill() {
        return Theme.isDark ? "#81d4fa" : "#42a5f5"
    }

    function drawSun(ctx) {
        ctx.fillStyle = sunFill()
        ctx.beginPath()
        ctx.arc(12, 12, 5, 0, Math.PI * 2)
        ctx.fill()
        ctx.strokeStyle = sunFill()
        ctx.lineWidth = 1.6
        ctx.lineCap = "round"
        for (var i = 0; i < 8; i++) {
            var a = i * Math.PI / 4
            ctx.beginPath()
            ctx.moveTo(12 + Math.cos(a) * 7.2, 12 + Math.sin(a) * 7.2)
            ctx.lineTo(12 + Math.cos(a) * 10, 12 + Math.sin(a) * 10)
            ctx.stroke()
        }
    }

    function drawSunSmall(ctx) {
        ctx.fillStyle = sunFill()
        ctx.beginPath()
        ctx.arc(17, 7, 3, 0, Math.PI * 2)
        ctx.fill()
        ctx.strokeStyle = sunFill()
        ctx.lineWidth = 1.2
        ctx.lineCap = "round"
        for (var i = 0; i < 6; i++) {
            var a = i * Math.PI / 3
            ctx.beginPath()
            ctx.moveTo(17 + Math.cos(a) * 4.2, 7 + Math.sin(a) * 4.2)
            ctx.lineTo(17 + Math.cos(a) * 6.2, 7 + Math.sin(a) * 6.2)
            ctx.stroke()
        }
    }

    function drawCloud(ctx, ox, oy) {
        ctx.fillStyle = cloudFill()
        ctx.beginPath()
        ctx.arc(ox + 7, oy + 10, 4.8, 0, Math.PI * 2)
        ctx.arc(ox + 12.5, oy + 8, 6.2, 0, Math.PI * 2)
        ctx.arc(ox + 18, oy + 10.5, 4.2, 0, Math.PI * 2)
        ctx.fill()
        ctx.fillRect(ox + 3.5, oy + 10, 17, 5)
    }

    function drawRain(ctx) {
        ctx.strokeStyle = rainFill()
        ctx.lineWidth = 1.7
        ctx.lineCap = "round"
        var drops = [
            [7.5, 16.2, 6.2, 20.2],
            [12.2, 16.8, 10.9, 20.8],
            [16.8, 16.2, 15.5, 20.2]
        ]
        for (var i = 0; i < drops.length; i++) {
            var d = drops[i]
            ctx.beginPath()
            ctx.moveTo(d[0], d[1])
            ctx.lineTo(d[2], d[3])
            ctx.stroke()
        }
    }

    function drawBolt(ctx) {
        ctx.fillStyle = Theme.isDark ? "#ffeb3b" : "#fbc02d"
        ctx.beginPath()
        ctx.moveTo(12.8, 14.2)
        ctx.lineTo(10.2, 18.4)
        ctx.lineTo(13.0, 18.4)
        ctx.lineTo(11.4, 22.4)
        ctx.lineTo(16.6, 16.8)
        ctx.lineTo(13.6, 16.8)
        ctx.closePath()
        ctx.fill()
    }

    function drawSnow(ctx) {
        ctx.fillStyle = Theme.isDark ? "#e3f2fd" : "#90caf9"
        var pts = [[8, 17.6], [12.2, 18.6], [16.4, 17.6]]
        for (var i = 0; i < pts.length; i++) {
            ctx.beginPath()
            ctx.arc(pts[i][0], pts[i][1], 1.25, 0, Math.PI * 2)
            ctx.fill()
        }
    }

    function drawFog(ctx) {
        ctx.strokeStyle = cloudFill()
        ctx.lineWidth = 1.7
        ctx.lineCap = "round"
        for (var i = 0; i < 3; i++) {
            var y = 9 + i * 4
            ctx.beginPath()
            ctx.moveTo(5, y)
            ctx.lineTo(19, y)
            ctx.stroke()
        }
    }
}

import QtQuick
import QtQuick.Controls
import WeatherApp

Rectangle {
    id: aqiCard
    property string aqi: weatherController.aqi
    property string category: weatherController.aqiCategory
    property string level: weatherController.aqiLevel
    property string mode: "aqi"
    property real animProgress: 1
    property bool readyToAnimate: false

    radius: 18
    border.width: 1
    border.color: Theme.isDark ? "#2e3a58" : "#e2e8f0"
    clip: true

    readonly property bool hasUv: (weatherController.uvCategory && weatherController.uvCategory.length)
                                  || (weatherController.uvLevel && weatherController.uvLevel.length)
    readonly property bool hasAqi: !!(aqi && String(aqi).length)
    readonly property bool hasData: mode === "aqi" ? hasAqi : hasUv

    readonly property real gaugeStart: Math.PI * 0.80
    readonly property real gaugeSweep: Math.PI * 1.40
    readonly property real aqiMax: 500

    color: Theme.isDark ? "#182034" : "#f8fafc"

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: aqiCard.washTop }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    readonly property color washTop: {
        if (Theme.isDark) {
            return mode === "uv" ? "#243556" : "#1f2d48"
        }
        if (mode === "uv") return "#e7f0fb"
        var n = aqiNumeric(aqi)
        if (n <= 50) return "#e9f7ec"
        if (n <= 100) return "#f6f7e5"
        if (n <= 150) return "#f8eee4"
        if (n <= 200) return "#f8e9e7"
        return "#f1e9f5"
    }

    NumberAnimation {
        id: gaugeAnim
        target: aqiCard
        property: "animProgress"
        from: 0
        to: 1
        duration: settingsManager.animationsEnabled ? 900 : 1
        easing.type: Easing.OutCubic
    }

    onAnimProgressChanged: gaugeCanvas.requestPaint()

    function playAnim() {
        if (!readyToAnimate || !hasData) {
            animProgress = hasData ? 1 : 0
            gaugeCanvas.requestPaint()
            return
        }
        if (!settingsManager.animationsEnabled) {
            animProgress = 1
            gaugeCanvas.requestPaint()
            return
        }
        gaugeAnim.stop()
        animProgress = 0
        gaugeAnim.start()
    }

    function aqiNumeric(v) {
        var n = parseFloat(v)
        if (isNaN(n)) return 0
        return Math.max(0, Math.min(aqiCard.aqiMax, n))
    }

    function uvNumeric() {
        var n = parseInt(weatherController.uvLevel)
        if (!isNaN(n) && n > 0) return Math.max(1, Math.min(5, n))
        var c = (weatherController.uvCategory || "") + (weatherController.uvLevel || "")
        if (c.indexOf("\u5f88\u5f3a") >= 0) return 5
        if (c.indexOf("\u5f3a") >= 0) return 4
        if (c.indexOf("\u4e2d") >= 0) return 3
        if (c.indexOf("\u6700\u5f31") >= 0) return 1
        if (c.indexOf("\u5f31") >= 0) return 2
        return 1
    }

    function mix(a, b, t) {
        return Math.round(a + (b - a) * t)
    }

    function lerpColor(t) {
        var stops = [
            { t: 0.00, c: [76, 175, 80] },
            { t: 0.18, c: [139, 195, 74] },
            { t: 0.32, c: [205, 220, 57] },
            { t: 0.45, c: [255, 213, 79] },
            { t: 0.58, c: [255, 167, 38] },
            { t: 0.72, c: [244, 81, 67] },
            { t: 0.86, c: [171, 71, 188] },
            { t: 1.00, c: [123, 31, 162] }
        ]
        t = Math.max(0, Math.min(1, t))
        for (var i = 0; i < stops.length - 1; i++) {
            if (t >= stops[i].t && t <= stops[i + 1].t) {
                var u = (t - stops[i].t) / (stops[i + 1].t - stops[i].t)
                u = u * u * (3 - 2 * u)
                var r = mix(stops[i].c[0], stops[i + 1].c[0], u)
                var g = mix(stops[i].c[1], stops[i + 1].c[1], u)
                var b = mix(stops[i].c[2], stops[i + 1].c[2], u)
                return "rgb(" + r + "," + g + "," + b + ")"
            }
        }
        return "rgb(123,31,162)"
    }

    function uvColor(t) {
        return lerpColor(Math.max(0, Math.min(1, t * 0.9)))
    }

    Column {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 2

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 5
            z: 2
            Repeater {
                model: [
                    { id: "aqi", label: "AQI" },
                    { id: "uv", label: "UV" }
                ]
                Rectangle {
                    width: 36
                    height: 18
                    radius: 9
                    opacity: (modelData.id === "uv" && !aqiCard.hasUv) ? 0.4 : 1
                    color: aqiCard.mode === modelData.id
                           ? (Theme.isDark ? "#4d74a8" : "#4aa3f0")
                           : (Theme.isDark ? "#243048" : "#ffffffcc")
                    border.width: aqiCard.mode === modelData.id ? 0 : 1
                    border.color: Theme.isDark ? "#33415f" : "#e6ebf2"
                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        font.pixelSize: 10
                        font.bold: true
                        color: aqiCard.mode === modelData.id ? "#ffffff" : Theme.textSecondary
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: modelData.id !== "uv" || aqiCard.hasUv
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            aqiCard.mode = modelData.id
                            aqiCard.playAnim()
                        }
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: parent.height - 22

            Canvas {
                id: gaugeCanvas
                anchors.fill: parent
                antialiasing: true
                onPaint: aqiCard.paintGauge(getContext("2d"))
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                Component.onCompleted: {
                    aqiCard.animProgress = aqiCard.hasData ? 1 : 0
                    requestPaint()
                }
            }

            // 当前数值居中显示在马蹄形仪表空心处
            Column {
                id: centerReadout
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 4
                spacing: 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        if (!aqiCard.hasData) return "--"
                        if (aqiCard.mode === "aqi")
                            return String(Math.round(aqiCard.aqiNumeric(aqiCard.aqi) * aqiCard.animProgress))
                        return weatherController.uvCategory || weatherController.uvLevel || "--"
                    }
                    font.pixelSize: aqiCard.mode === "aqi" ? 36 : 18
                    font.bold: true
                    color: Theme.isDark ? "#f4f7fb" : "#1f2a37"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: aqiCard.mode === "aqi" ? "AQI" : "UV"
                    font.pixelSize: 10
                    color: Theme.isDark ? "#a7b3c7" : "#7b8799"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        if (!aqiCard.hasData) return "\u641c\u7d22\u57ce\u5e02\u540e\u663e\u793a"
                        if (aqiCard.mode === "aqi") {
                            // 用当前显示数值推导等级文案，保证数字与类别一致
                            var fromValue = Theme.aqiLabel(aqiCard.aqiNumeric(aqiCard.aqi))
                            return fromValue || aqiCard.category || ""
                        }
                        return weatherController.uvLevel ? ("Lv." + weatherController.uvLevel) : ""
                    }
                    font.pixelSize: aqiCard.hasData ? 13 : 10
                    font.bold: aqiCard.hasData
                    color: Theme.isDark ? "#e6ebf4" : "#334155"
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (!aqiCard.hasUv) return
                    aqiCard.mode = aqiCard.mode === "aqi" ? "uv" : "aqi"
                    aqiCard.playAnim()
                }
            }
        }
    }

    function paintGauge(ctx) {
        var w = gaugeCanvas.width, h = gaugeCanvas.height
        ctx.clearRect(0, 0, w, h)

        var cx = w / 2
        var cy = h * 0.54
        var outer = Math.min(w, h) * 0.46
        var thickness = Math.max(24, outer * 0.38)
        var midR = outer - thickness / 2
        var start = aqiCard.gaugeStart
        var sweep = aqiCard.gaugeSweep
        var p = Math.max(0, Math.min(1, aqiCard.animProgress))

        if (!aqiCard.hasData) {
            ctx.beginPath()
            ctx.arc(cx, cy, midR, start, start + sweep)
            ctx.strokeStyle = Theme.isDark ? "rgba(255,255,255,0.08)" : "rgba(0,0,0,0.06)"
            ctx.lineWidth = thickness
            ctx.lineCap = "round"
            ctx.stroke()
            return
        }

        ctx.beginPath()
        ctx.arc(cx, cy, midR, start, start + sweep)
        ctx.strokeStyle = Theme.isDark ? "rgba(255,255,255,0.10)" : "rgba(15,23,42,0.07)"
        ctx.lineWidth = thickness
        ctx.lineCap = "round"
        ctx.stroke()

        var steps = 48
        var drawSweep = sweep * p
        for (var i = 0; i < steps; i++) {
            var t0 = i / steps
            var t1 = (i + 1.05) / steps
            if (t0 * sweep > drawSweep) break
            var a0 = start + Math.min(drawSweep, t0 * sweep)
            var a1 = start + Math.min(drawSweep, t1 * sweep)
            if (a1 <= a0) continue
            ctx.beginPath()
            ctx.arc(cx, cy, midR, a0, a1)
            ctx.strokeStyle = (aqiCard.mode === "aqi") ? lerpColor(t0) : uvColor(t0)
            ctx.lineWidth = thickness
            ctx.lineCap = i === 0 || t1 * sweep >= drawSweep ? "round" : "butt"
            ctx.stroke()
        }

        var ticks = (aqiCard.mode === "aqi") ? [0, 100, 200, 300, 500] : [1, 2, 3, 4, 5]
        var maxV = (aqiCard.mode === "aqi") ? aqiCard.aqiMax : 5
        ctx.font = "bold 9px sans-serif"
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        for (var k = 0; k < ticks.length; k++) {
            var tt = Math.max(0, Math.min(1, ticks[k] / maxV))
            var ang = start + sweep * tt
            var lx = cx + Math.cos(ang) * midR
            var ly = cy + Math.sin(ang) * midR

            var ir = midR - thickness * 0.28
            var or = midR + thickness * 0.28
            ctx.beginPath()
            ctx.moveTo(cx + Math.cos(ang) * ir, cy + Math.sin(ang) * ir)
            ctx.lineTo(cx + Math.cos(ang) * or, cy + Math.sin(ang) * or)
            ctx.strokeStyle = "rgba(255,255,255,0.55)"
            ctx.lineWidth = 1.2
            ctx.lineCap = "butt"
            ctx.stroke()

            ctx.lineWidth = 2.5
            ctx.strokeStyle = "rgba(0,0,0,0.35)"
            ctx.fillStyle = "#ffffff"
            ctx.strokeText(String(ticks[k]), lx, ly)
            ctx.fillText(String(ticks[k]), lx, ly)
        }

        var value = (aqiCard.mode === "aqi") ? aqiCard.aqiNumeric(aqiCard.aqi) : aqiCard.uvNumeric()
        var vt = Math.max(0, Math.min(1, value / maxV)) * p
        var na = start + sweep * vt
        var nx = cx + Math.cos(na) * midR
        var ny = cy + Math.sin(na) * midR

        ctx.beginPath()
        ctx.arc(nx, ny, thickness * 0.34, 0, Math.PI * 2)
        ctx.fillStyle = "#ffffff"
        ctx.fill()
        ctx.beginPath()
        ctx.arc(nx, ny, thickness * 0.16, 0, Math.PI * 2)
        ctx.fillStyle = (aqiCard.mode === "aqi") ? lerpColor(vt) : uvColor(vt)
        ctx.fill()
    }

    Connections {
        target: weatherController
        function onWeatherChanged() {
            aqiCard.readyToAnimate = aqiCard.hasAqi || aqiCard.hasUv
            if (!aqiCard.hasUv && aqiCard.mode === "uv")
                aqiCard.mode = "aqi"
            aqiCard.playAnim()
        }
    }

    Connections {
        target: settingsManager
        function onDarkThemeChanged() { gaugeCanvas.requestPaint() }
    }

    ToolTip.visible: mode === "uv" && weatherController.uvText.length > 0 && tipMa.containsMouse
    ToolTip.text: weatherController.uvText
    ToolTip.delay: 450
    MouseArea {
        id: tipMa
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        z: -1
    }
}

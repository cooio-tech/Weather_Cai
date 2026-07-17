import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import WeatherApp

Window {
    id: widgetWin
    width: settingsManager.widgetWidth
    height: settingsManager.widgetHeight
    minimumWidth: 140
    minimumHeight: 60
    maximumWidth: 360
    maximumHeight: 160
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "transparent"
    visible: false

    property bool hovered: false
    property string weatherType: weatherController.animationType || "sunny"
    readonly property real uiScale: Math.max(0.85, Math.min(1.55, height / 78.0))

    Connections {
        target: settingsManager
        function onWidgetSizeChanged() {
            if (resizeHandle.dragging) return
            widgetWin.width = settingsManager.widgetWidth
            widgetWin.height = settingsManager.widgetHeight
        }
    }
    function baseColor() {
        // 略不透明（约 42%）
        if (Theme.isDark) {
            if (weatherType === "rain") return "#6a152028"
            if (weatherType === "snow") return "#6a182024"
            if (weatherType === "cloudy") return "#6a191e20"
            return "#6a1a1c16"
        }
        if (weatherType === "rain") return "#6ae8f3f8"
        if (weatherType === "snow") return "#6aeef4f7"
        if (weatherType === "cloudy") return "#6ae9efec"
        return "#6afff6e8"
    }

    function borderColor() {
        if (Theme.isDark) return "#55a8c4b8"
        if (weatherType === "rain") return "#66a0c4d4"
        if (weatherType === "snow") return "#66b0c4cc"
        if (weatherType === "cloudy") return "#66a8bbb4"
        return "#66d4b878"
    }

    Rectangle {
        id: shadow
        anchors.fill: card
        anchors.margins: -1
        anchors.topMargin: 3
        radius: 15
        color: "#000000"
        opacity: Theme.isDark ? 0.18 : 0.08
        z: -1
    }

    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: 2
        radius: 14
        border.color: widgetWin.borderColor()
        border.width: 1
        clip: true
        color: widgetWin.baseColor()

        Item {
            id: weatherBg
            anchors.fill: parent
            z: 0

            // 晴天：缓慢旋转（限制在圆角卡片内）
            Item {
                id: sunnyLayer
                anchors.fill: parent
                visible: widgetWin.weatherType === "sunny" || widgetWin.weatherType === ""
                clip: true

                Item {
                    id: sunGroup
                    width: 48
                    height: 48
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.top: parent.top
                    anchors.topMargin: 4

                    Rectangle {
                        anchors.centerIn: parent
                        width: 28
                        height: 28
                        radius: 14
                        color: Theme.isDark ? "#66e6c45a" : "#66ffc94a"
                    }
                    Repeater {
                        model: 6
                        Rectangle {
                            width: 2
                            height: 7
                            radius: 1
                            color: Theme.isDark ? "#55e6c45a" : "#55ffb830"
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            transform: [
                                Rotation { angle: index * 60 },
                                Translate { y: -18 }
                            ]
                        }
                    }
                    RotationAnimation on rotation {
                        from: 0; to: 360
                        duration: 22000
                        loops: Animation.Infinite
                        running: sunnyLayer.visible && widgetWin.visible && settingsManager.animationsEnabled
                    }
                }
            }

            // 多云：简单柔和云朵
            Item {
                id: cloudyLayer
                anchors.fill: parent
                visible: widgetWin.weatherType === "cloudy"

                Item {
                    id: cloud
                    width: 72
                    height: 36
                    x: parent.width - 78
                    y: 6
                    opacity: Theme.isDark ? 0.55 : 0.70

                    Rectangle {
                        width: 28; height: 28; radius: 14
                        x: 4; y: 6
                        color: Theme.isDark ? "#9aadb8" : "#ffffff"
                    }
                    Rectangle {
                        width: 34; height: 34; radius: 17
                        x: 20; y: 0
                        color: Theme.isDark ? "#a8bac4" : "#ffffff"
                    }
                    Rectangle {
                        width: 26; height: 26; radius: 13
                        x: 44; y: 8
                        color: Theme.isDark ? "#90a4b0" : "#f2f6f8"
                    }
                    Rectangle {
                        width: 56; height: 18; radius: 9
                        x: 8; y: 18
                        color: Theme.isDark ? "#9aadb8" : "#ffffff"
                    }

                    SequentialAnimation on x {
                        loops: Animation.Infinite
                        running: cloudyLayer.visible && widgetWin.visible && settingsManager.animationsEnabled
                        NumberAnimation { from: 90; to: 82; duration: 8000; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 82; to: 90; duration: 8000; easing.type: Easing.InOutSine }
                    }
                }

                Rectangle {
                    width: 22; height: 14; radius: 7
                    x: 12
                    y: parent.height - 24
                    color: Theme.isDark ? "#66788894" : "#66ffffff"
                    opacity: 0.6
                }
            }

            // 雨：柔和下落
            Item {
                anchors.fill: parent
                visible: widgetWin.weatherType === "rain"

                Rectangle {
                    width: 48
                    height: 22
                    radius: 11
                    x: parent.width - 56
                    y: 4
                    color: Theme.isDark ? "#44708898" : "#66dceaf0"
                }
                Repeater {
                    model: 6
                    Rectangle {
                        id: drop
                        width: 2
                        height: 11
                        radius: 1
                        rotation: 18
                        color: Theme.isDark ? "#887eb8d4" : "#8870a8c8"
                        x: 18 + index * 24
                        opacity: 0.5
                        SequentialAnimation on y {
                            loops: Animation.Infinite
                            running: drop.parent.visible && widgetWin.visible && settingsManager.animationsEnabled
                            NumberAnimation {
                                from: -6
                                to: card.height + 6
                                duration: 1600 + index * 180
                            }
                        }
                    }
                }
            }

            // 雪：轻柔飘落
            Item {
                anchors.fill: parent
                visible: widgetWin.weatherType === "snow"

                Repeater {
                    model: 6
                    Rectangle {
                        id: flake
                        width: 4 + (index % 2)
                        height: width
                        radius: width / 2
                        color: Theme.isDark ? "#aadddde8" : "#aaffffff"
                        opacity: 0.55
                        x: 16 + index * 26
                        SequentialAnimation on y {
                            loops: Animation.Infinite
                            running: flake.parent.visible && widgetWin.visible && settingsManager.animationsEnabled
                            NumberAnimation {
                                from: -4
                                to: card.height + 4
                                duration: 4200 + index * 400
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Math.round(10 * widgetWin.uiScale)
            anchors.rightMargin: Math.round(12 * widgetWin.uiScale)
            anchors.topMargin: Math.round(8 * widgetWin.uiScale)
            anchors.bottomMargin: Math.round(8 * widgetWin.uiScale)
            spacing: Math.round(8 * widgetWin.uiScale)
            z: 1

            Rectangle {
                Layout.preferredWidth: Math.round(32 * widgetWin.uiScale)
                Layout.preferredHeight: Math.round(32 * widgetWin.uiScale)
                Layout.alignment: Qt.AlignVCenter
                radius: Math.round(10 * widgetWin.uiScale)
                color: Theme.isDark ? "#6628302c" : "#88ffffff"
                border.color: Theme.isDark ? "#33ffffff" : "#66ffffff"
                border.width: 1

                WeatherIcon {
                    anchors.centerIn: parent
                    width: Math.round(22 * widgetWin.uiScale)
                    height: Math.round(22 * widgetWin.uiScale)
                    weatherType: widgetWin.weatherType || "sunny"
                    iconCode: weatherController.iconCode || ""
                    cloudStyle: "gray"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: Math.round(80 * widgetWin.uiScale)
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    text: weatherController.cityName || "\u5929\u6c14"
                    font.pixelSize: Math.round(11 * widgetWin.uiScale)
                    font.weight: Font.Medium
                    color: Theme.isDark ? "#deeee8" : "#1e3a34"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: weatherController.weatherText || "--"
                    font.pixelSize: Math.round(14 * widgetWin.uiScale)
                    font.weight: Font.DemiBold
                    color: Theme.isDark ? "#f7fcfa" : "#0c2822"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: Math.round(28 * widgetWin.uiScale)
                Layout.leftMargin: 2
                Layout.rightMargin: 2
                Layout.alignment: Qt.AlignVCenter
                radius: 1
                color: Theme.isDark ? "#33ffffff" : "#22000000"
            }

            Row {
                spacing: 0
                Layout.alignment: Qt.AlignVCenter
                Text {
                    text: weatherController.temperature || "--"
                    font.pixelSize: Math.round(30 * widgetWin.uiScale)
                    font.weight: Font.DemiBold
                    color: Theme.isDark ? "#fafefc" : "#0a221c"
                }
                Text {
                    text: "\u00b0"
                    font.pixelSize: Math.round(15 * widgetWin.uiScale)
                    font.weight: Font.Medium
                    color: Theme.isDark ? "#a8cbc2" : "#3d6058"
                    y: 2
                }
            }

            Rectangle {
                width: Math.round(18 * widgetWin.uiScale)
                height: Math.round(18 * widgetWin.uiScale)
                radius: width / 2
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 2
                color: closeMa.containsMouse
                       ? (Theme.isDark ? "#443a4c48" : "#55ffffff")
                       : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "\u00d7"
                    font.pixelSize: Math.round(12 * widgetWin.uiScale)
                    color: Theme.isDark ? "#c5ddd6" : "#5a756f"
                    opacity: widgetWin.hovered || closeMa.containsMouse ? 0.95 : 0.35
                }

                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: desktopManager.hideWidget()
                }
            }
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            anchors.rightMargin: 18
            anchors.bottomMargin: 18
            z: -1
            hoverEnabled: true
            property real sx: 0
            property real sy: 0
            onEntered: widgetWin.hovered = true
            onExited: widgetWin.hovered = false
            onPressed: function(mouse) { sx = mouse.x; sy = mouse.y }
            onPositionChanged: function(mouse) {
                if (pressed) {
                    widgetWin.x += mouse.x - sx
                    widgetWin.y += mouse.y - sy
                }
            }
            onDoubleClicked: desktopManager.showMainWindow()
        }

        // 右下角缩放手柄
        Item {
            id: resizeHandle
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: 18
            height: 18
            z: 5
            property bool dragging: false
            property real startW: 0
            property real startH: 0
            property real startGX: 0
            property real startGY: 0

            Canvas {
                id: gripCanvas
                anchors.fill: parent
                anchors.margins: 3
                opacity: widgetWin.hovered || resizeMa.containsMouse || resizeHandle.dragging ? 0.8 : 0.35
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.strokeStyle = Theme.isDark ? "#c5ddd6" : "#5a756f"
                    ctx.lineWidth = 1.5
                    ctx.lineCap = "round"
                    ctx.beginPath(); ctx.moveTo(width - 1, 2); ctx.lineTo(width - 1, height - 1); ctx.lineTo(2, height - 1); ctx.stroke()
                    ctx.beginPath(); ctx.moveTo(width - 1, 7); ctx.lineTo(width - 1, height - 1); ctx.lineTo(7, height - 1); ctx.stroke()
                }
                Component.onCompleted: requestPaint()
            }

            Connections {
                target: settingsManager
                function onDarkThemeChanged() { gripCanvas.requestPaint() }
            }

            MouseArea {
                id: resizeMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.SizeFDiagCursor
                preventStealing: true
                onPressed: function(mouse) {
                    resizeHandle.dragging = true
                    resizeHandle.startW = widgetWin.width
                    resizeHandle.startH = widgetWin.height
                    var p = mapToGlobal(mouse.x, mouse.y)
                    resizeHandle.startGX = p.x
                    resizeHandle.startGY = p.y
                }
                onPositionChanged: function(mouse) {
                    if (!pressed) return
                    var p = mapToGlobal(mouse.x, mouse.y)
                    var nw = resizeHandle.startW + (p.x - resizeHandle.startGX)
                    var nh = resizeHandle.startH + (p.y - resizeHandle.startGY)
                    widgetWin.width = Math.max(widgetWin.minimumWidth, Math.min(widgetWin.maximumWidth, nw))
                    widgetWin.height = Math.max(widgetWin.minimumHeight, Math.min(widgetWin.maximumHeight, nh))
                }
                onReleased: {
                    resizeHandle.dragging = false
                    settingsManager.setWidgetSize(Math.round(widgetWin.width), Math.round(widgetWin.height))
                }
            }
        }
    }
}
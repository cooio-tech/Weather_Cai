import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import WeatherApp

Window {
    id: widgetWin
    width: 178
    height: 78
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "transparent"
    visible: false

    property bool hovered: false
    property string weatherType: weatherController.animationType || "sunny"

    function baseColor() {
        // Slightly less transparent (~42%)
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

    function glyphColor() {
        if (weatherType === "rain") return Theme.isDark ? "#9ecfe6" : "#2f7ea0"
        if (weatherType === "snow") return Theme.isDark ? "#d5e4e8" : "#5f8690"
        if (weatherType === "cloudy") return Theme.isDark ? "#c2d4ce" : "#5f7f78"
        return Theme.isDark ? "#f0d47a" : "#c88910"
    }

    function weatherGlyph() {
        if (weatherType === "rain") return "\u2602"
        if (weatherType === "snow") return "\u2744"
        if (weatherType === "cloudy") return "\u2601"
        return "\u2600"
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

            // Sunny — slow rotation (kept inside rounded card)
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
                        running: sunnyLayer.visible && widgetWin.visible
                    }
                }
            }

            // Cloudy — simple soft cloud (post "好看一点" cleanup)
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
                        running: cloudyLayer.visible && widgetWin.visible
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

            // Rain — soft fall
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
                            running: drop.parent.visible && widgetWin.visible
                            NumberAnimation {
                                from: -6
                                to: card.height + 6
                                duration: 1600 + index * 180
                            }
                        }
                    }
                }
            }

            // Snow — soft float
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
                            running: flake.parent.visible && widgetWin.visible
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
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            spacing: 8
            z: 1

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignVCenter
                radius: 10
                color: Theme.isDark ? "#6628302c" : "#88ffffff"
                border.color: Theme.isDark ? "#33ffffff" : "#66ffffff"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: widgetWin.weatherGlyph()
                    font.pixelSize: 18
                    color: widgetWin.glyphColor()
                }
            }

            ColumnLayout {
                Layout.fillWidth: false
                Layout.maximumWidth: 60
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    text: weatherController.cityName || "\u5929\u6c14"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: Theme.isDark ? "#deeee8" : "#1e3a34"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: weatherController.weatherText || "--"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: Theme.isDark ? "#f7fcfa" : "#0c2822"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 28
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                Layout.alignment: Qt.AlignVCenter
                radius: 1
                color: Theme.isDark ? "#33ffffff" : "#22000000"
            }

            Row {
                spacing: 0
                Layout.alignment: Qt.AlignVCenter
                Text {
                    text: weatherController.temperature || "--"
                    font.pixelSize: 30
                    font.weight: Font.DemiBold
                    color: Theme.isDark ? "#fafefc" : "#0a221c"
                }
                Text {
                    text: "\u00b0"
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    color: Theme.isDark ? "#a8cbc2" : "#3d6058"
                    y: 2
                }
            }

            Rectangle {
                width: 18
                height: 18
                radius: 9
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 2
                color: closeMa.containsMouse
                       ? (Theme.isDark ? "#443a4c48" : "#55ffffff")
                       : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "\u00d7"
                    font.pixelSize: 12
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
    }
}
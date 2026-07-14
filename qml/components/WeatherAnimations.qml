import QtQuick
//import WeatherApp

Item {
    id: animRoot
    property string animationType: "sunny"

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Theme.cardBg
        clip: true
    }

    Loader {
        anchors.centerIn: parent
        active: animRoot.animationType === "sunny"
        sourceComponent: sunnyComp
    }

    Component {
        id: sunnyComp
        Item {
            width: 120
            height: 120

            Rectangle {
                id: sun
                width: 70
                height: 70
                radius: 35
                anchors.centerIn: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: "#FFD54F" }
                    GradientStop { position: 1; color: "#FF8F00" }
                }
                RotationAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 8000
                    loops: Animation.Infinite
                    running: true
                }
            }

            Repeater {
                model: 8
                Rectangle {
                    width: 4
                    height: 18
                    radius: 2
                    color: "#FFD54F"
                    anchors.horizontalCenter: sun.horizontalCenter
                    transformOrigin: Item.Top
                    y: sun.y - 22
                    rotation: index * 45
                    transform: Translate { y: -sun.height / 2 - 8 }
                }
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: animRoot.animationType === "rain"
        sourceComponent: rainComp
    }

    Component {
        id: rainComp
        Item {
            anchors.fill: parent

            Repeater {
                model: 30
                Rectangle {
                    width: 2
                    height: 12 + Math.random() * 8
                    radius: 1
                    color: "#64B5F6"
                    opacity: 0.6 + Math.random() * 0.4
                    x: Math.random() * animRoot.width
                    y: -20

                    SequentialAnimation on y {
                        loops: Animation.Infinite
                        running: true
                        NumberAnimation {
                            from: -20
                            to: animRoot.height + 20
                            duration: 800 + Math.random() * 600
                        }
                        PropertyAction { value: -20 }
                    }

                    SequentialAnimation on x {
                        loops: Animation.Infinite
                        running: true
                        NumberAnimation {
                            from: x
                            to: x + (Math.random() - 0.5) * 20
                            duration: 800 + Math.random() * 600
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: "\u2601"
                font.pixelSize: Theme.isDark ? 52 : 48
                color: Theme.isDark ? "#ECEFF1" : "#78909C"
                opacity: Theme.isDark ? 0.65 : 0.3
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: animRoot.animationType === "snow"
        sourceComponent: snowComp
    }

    Component {
        id: snowComp
        Item {
            anchors.fill: parent

            Repeater {
                model: 25
                Rectangle {
                    width: 4 + Math.random() * 6
                    height: width
                    radius: width / 2
                    color: "white"
                    opacity: 0.5 + Math.random() * 0.5
                    x: Math.random() * animRoot.width
                    y: -10

                    SequentialAnimation on y {
                        loops: Animation.Infinite
                        running: true
                        NumberAnimation {
                            from: -10
                            to: animRoot.height + 10
                            duration: 3000 + Math.random() * 4000
                        }
                        PropertyAction { value: -10 }
                    }

                    SequentialAnimation on x {
                        loops: Animation.Infinite
                        running: true
                        NumberAnimation {
                            from: x
                            to: x + (Math.random() - 0.5) * 60
                            duration: 3000 + Math.random() * 4000
                            easing.type: Easing.InOutSine
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: "\u2744"
                font.pixelSize: 48
                opacity: 0.3
            }
        }
    }

    Loader {
        anchors.centerIn: parent
        active: animRoot.animationType === "cloudy"
        sourceComponent: cloudyComp
    }

    Component {
        id: cloudyComp
        Item {
            width: 120
            height: 80

            Rectangle {
                width: 60
                height: 40
                radius: 20
                color: "#B0BEC5"
                x: 10
                y: 30
                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: true
                    NumberAnimation { from: 10; to: 20; duration: 3000; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 20; to: 10; duration: 3000; easing.type: Easing.InOutQuad }
                }
            }

            Rectangle {
                width: 50
                height: 35
                radius: 17
                color: "#CFD8DC"
                x: 40
                y: 20
                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: true
                    NumberAnimation { from: 40; to: 50; duration: 4000; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 50; to: 40; duration: 4000; easing.type: Easing.InOutQuad }
                }
            }

            Rectangle {
                width: 45
                height: 30
                radius: 15
                color: "#ECEFF1"
                x: 65
                y: 35
            }
        }
    }
}

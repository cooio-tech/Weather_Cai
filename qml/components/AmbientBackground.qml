import QtQuick
import WeatherApp

Item {
    id: ambience
    anchors.fill: parent
    z: -1
    clip: true

    readonly property string mood: Theme.weatherMood
    readonly property bool animOn: settingsManager.animationsEnabled

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.ambienceTop }
            GradientStop { position: 0.5; color: Theme.ambienceBase }
            GradientStop { position: 1.0; color: Theme.ambienceAccent }
        }
        Behavior on gradient { enabled: false }
    }

    // Soft glow blob — sunny / warm
    Rectangle {
        visible: mood === "sunny" || mood === ""
        width: parent.width * 0.55
        height: width
        radius: width / 2
        anchors.right: parent.right
        anchors.rightMargin: -width * 0.25
        anchors.top: parent.top
        anchors.topMargin: -height * 0.35
        color: Theme.isDark ? "#44ffb74d" : "#55ffe082"
        opacity: 0.55
        SequentialAnimation on opacity {
            running: ambience.animOn && parent.visible
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 3200; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.55; duration: 3200; easing.type: Easing.InOutSine }
        }
    }

    // Drifting cloud patches
    Repeater {
        model: (mood === "cloudy" || mood === "rain" || mood === "snow") ? 3 : 0
        Rectangle {
            required property int index
            width: 180 + index * 40
            height: 70 + index * 10
            radius: height / 2
            color: Theme.isDark ? "#33ffffff" : "#55ffffff"
            y: 40 + index * 70
            opacity: 0.35
            SequentialAnimation on x {
                running: ambience.animOn && ambience.visible
                loops: Animation.Infinite
                NumberAnimation {
                    from: -220
                    to: ambience.width + 40
                    duration: 16000 + index * 4000
                    easing.type: Easing.Linear
                }
            }
        }
    }

    // Rain streaks
    Repeater {
        model: mood === "rain" ? 18 : 0
        Rectangle {
            required property int index
            width: 1.5
            height: 18 + (index % 5) * 4
            radius: 1
            color: Theme.isDark ? "#8890caf9" : "#6690caf9"
            x: (index * 73) % Math.max(1, ambience.width)
            opacity: 0.45
            y: -30
            SequentialAnimation on y {
                running: ambience.animOn && ambience.visible
                loops: Animation.Infinite
                NumberAnimation {
                    from: -40 - (index % 7) * 20
                    to: ambience.height + 40
                    duration: 900 + (index % 6) * 180
                    easing.type: Easing.Linear
                }
            }
        }
    }

    // Snow flakes
    Repeater {
        model: mood === "snow" ? 14 : 0
        Rectangle {
            required property int index
            width: 4 + (index % 3)
            height: width
            radius: width / 2
            color: Theme.isDark ? "#ccffffff" : "#aaffffff"
            x: (index * 89) % Math.max(120, ambience.width)
            opacity: 0.55
            SequentialAnimation on y {
                running: ambience.animOn && ambience.visible
                loops: Animation.Infinite
                NumberAnimation {
                    from: -20
                    to: ambience.height + 20
                    duration: 3500 + index * 220
                    easing.type: Easing.InOutSine
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import WeatherApp

ApplicationWindow {
    id: root
    width: 1200
    height: 845
    visible: true
    title: "\u5929\u6c14\u67e5\u8be2\u7cfb\u7edf"
    color: Theme.background

    Behavior on color { ColorAnimation { duration: settingsManager.animationsEnabled ? 600 : 0 } }

    AmbientBackground { anchors.fill: parent }

    //定时刷新
    Timer {
        id: refreshTimer
        interval: Math.max(1, settingsManager.refreshIntervalMin) * 60 * 1000
        repeat: true
        running: settingsManager.refreshIntervalMin > 0
                 && weatherController.cityName.length > 0
        onTriggered: weatherController.refreshWeather()
    }

    Connections {
        target: settingsManager
        function onCacheCleared() { weatherController.clearAllCache() }
        function onRefreshIntervalChanged() {
            refreshTimer.interval = Math.max(1, settingsManager.refreshIntervalMin) * 60 * 1000
            refreshTimer.restart()
        }
    }

    Connections {
        target: weatherController
        function onWeatherChanged() {
            if (settingsManager.voiceEnabled)
                weatherController.speakWeather(true)
        }
        function onErrorChanged() {
            if (weatherController.errorMessage.length > 0) {
                errorDialog.msg = weatherController.errorMessage
                errorDialog.open()
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            SearchBar {
                Layout.fillWidth: true
                onSearchRequested: function(city) { weatherController.searchCity(city) }
            }

            WeatherDisplay {
                Layout.fillWidth: true
                Layout.preferredHeight: 258
                Layout.minimumHeight: 238
            }

            HourlyTimeline {
                Layout.fillWidth: true
                Layout.preferredHeight: expanded ? 168 : 36
                Layout.maximumHeight: expanded ? 168 : 36
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 180
                spacing: 0

                TabBar {
                    id: bottomTab
                    Layout.fillWidth: true
                    implicitHeight: 42
                    currentIndex: 0
                    spacing: 6
                    background: Rectangle { color: "transparent" }

                    TabButton {
                        id: tab7
                        text: "7\u65e5\u9884\u62a5"
                        width: implicitWidth + 36
                        background: Rectangle {
                            radius: 6
                            color: tab7.checked ? "#4a4a4a" : Theme.surface
                            border.color: Theme.border
                            border.width: 1
                        }
                        contentItem: Text {
                            text: tab7.text
                            font.pixelSize: 15
                            font.bold: tab7.checked
                            color: tab7.checked ? "#ffffff" : Theme.textPrimary
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                    TabButton {
                        id: tabGo
                        text: "\u8bf4\u8d70\u5c31\u8d70"
                        width: implicitWidth + 36
                        background: Rectangle {
                            radius: 6
                            color: tabGo.checked ? "#4a4a4a" : Theme.surface
                            border.color: Theme.border
                            border.width: 1
                        }
                        contentItem: Text {
                            text: tabGo.text
                            font.pixelSize: 15
                            font.bold: tabGo.checked
                            color: tabGo.checked ? "#ffffff" : Theme.textPrimary
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: bottomTab.currentIndex
                    ChartsView { Layout.fillWidth: true; Layout.fillHeight: true }
                    TripGoPanel { Layout.fillWidth: true; Layout.fillHeight: true }
                }
            }
        }

        SettingsPanel {
            Layout.preferredWidth: 280
            Layout.maximumWidth: 300
            Layout.fillHeight: true
        }
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: weatherController.loading
        visible: running
        z: 100
    }

    Dialog {
        id: errorDialog
        title: "\u63d0\u793a"
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Ok
        property string msg: ""
        Label { text: errorDialog.msg; wrapMode: Text.WordWrap; width: 300 }
    }
}

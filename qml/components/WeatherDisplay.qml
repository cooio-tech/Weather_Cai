import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import WeatherApp

Rectangle {
    id: display
    radius: 16
    color: Theme.surface
    border.color: Theme.border
    border.width: 1
    clip: true

    readonly property int dayIdx: weatherController.selectedDayIndex
    readonly property bool showingDay: dayIdx >= 0
                                         && weatherController.dailyForecast
                                         && dayIdx < weatherController.dailyForecast.length
    readonly property var dayInfo: showingDay ? weatherController.dailyForecast[dayIdx] : null

    // Soft left sheen tied to weather mood
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.0
                color: Theme.isDark ? "#22ffffff" : "#18ffffff"
            }
            GradientStop { position: 0.45; color: "transparent" }
        }
        opacity: 0.9
        z: 0
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 18
        z: 1

        WeatherAnimations {
            Layout.preferredWidth: 140
            Layout.maximumWidth: 140
            Layout.preferredHeight: 140
            Layout.maximumHeight: 140
            Layout.alignment: Qt.AlignVCenter
            animationType: weatherController.animationType
        }

        ColumnLayout {
            Layout.preferredWidth: 240
            Layout.maximumWidth: 280
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: weatherController.cityName || "\u8bf7\u641c\u7d22\u57ce\u5e02"
                    font.pixelSize: 28
                    font.bold: true
                    color: Theme.textPrimary
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
                ToolButton {
                    visible: weatherController.cityName.length > 0
                    text: settingsManager.favoriteCities.indexOf(weatherController.cityName) >= 0 ? "\u2605" : "\u2606"
                    font.pixelSize: 16
                    onClicked: settingsManager.toggleFavoriteCity(weatherController.cityName)
                }
            }

            Text {
                Layout.fillWidth: true
                text: display.showingDay
                      ? ((display.dayInfo.textDay || "") + "  \u00b7  "
                         + (display.dayInfo.date ? display.dayInfo.date.substring(5, 10) : ""))
                      : weatherController.weatherText
                font.pixelSize: 17
                color: display.showingDay ? Theme.selectedDay : Theme.textSecondary
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            RowLayout {
                spacing: 4
                visible: !display.showingDay
                Text {
                    text: weatherController.temperature || "--"
                    font.pixelSize: 56
                    font.bold: true
                    color: Theme.textPrimary
                }
                Text {
                    text: "\u00b0C"
                    font.pixelSize: 22
                    color: Theme.textSecondary
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 10
                }
            }

            RowLayout {
                spacing: 6
                visible: display.showingDay
                Text {
                    text: Math.round(display.dayInfo.tempMin) + "\u00b0"
                    font.pixelSize: 28
                    color: Theme.chartLine
                    font.bold: true
                }
                Text {
                    text: "~"
                    font.pixelSize: 22
                    color: Theme.textSecondary
                }
                Text {
                    text: Math.round(display.dayInfo.tempMax) + "\u00b0"
                    font.pixelSize: 36
                    color: Theme.chartTempMax
                    font.bold: true
                }
                Text {
                    text: "\u9009\u4e2d\u65e5"
                    font.pixelSize: 12
                    color: Theme.selectedDay
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: 6
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: "\u56de\u5b9e\u51b5"
                    flat: true
                    font.pixelSize: 11
                    onClicked: weatherController.setSelectedDayIndex(-1)
                }
            }

            RowLayout {
                spacing: 12
                Label {
                    text: display.showingDay
                          ? ("\u6e7f\u5ea6: " + (display.dayInfo.humidity || "--") + "%")
                          : ("\u98ce: " + (weatherController.windInfo || "--"))
                    color: Theme.textSecondary
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    Layout.maximumWidth: 140
                }
                Label {
                    visible: !display.showingDay
                    text: "\u6e7f\u5ea6: " + (weatherController.humidity || "--") + "%"
                    color: Theme.textSecondary
                    font.pixelSize: 13
                }
                Label {
                    text: weatherController.fromCache ? "\u7f13\u5b58\u6570\u636e" : "\u5b9e\u65f6\u6570\u636e"
                    color: Theme.accent
                    font.pixelSize: 11
                    visible: weatherController.cityName.length > 0 && !display.showingDay
                }
            }
        }

        AqiCard {
            Layout.preferredWidth: 200
            Layout.maximumWidth: 205
            Layout.preferredHeight: 205
            Layout.maximumHeight: 210
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: false
            Layout.fillHeight: false
        }

        MapView {
            Layout.preferredWidth: 210
            Layout.minimumWidth: 200
            Layout.maximumWidth: 220
            Layout.preferredHeight: 205
            Layout.maximumHeight: 210
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignVCenter
            latitude: weatherController.latitude
            longitude: weatherController.longitude
            cityName: weatherController.cityName
        }
    }
}
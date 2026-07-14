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

    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 18

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
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignVCenter
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: weatherController.cityName || "\u8bf7\u641c\u7d22\u57ce\u5e02"
                font.pixelSize: 28
                font.bold: true
                color: Theme.textPrimary
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                Layout.fillWidth: true
                text: weatherController.weatherText
                font.pixelSize: 17
                color: Theme.textSecondary
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            RowLayout {
                spacing: 4
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
                spacing: 12
                Label {
                    text: "\u98ce: " + (weatherController.windInfo || "--")
                    color: Theme.textSecondary
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    Layout.maximumWidth: 140
                }
                Label {
                    text: "\u6e7f\u5ea6: " + (weatherController.humidity || "--") + "%"
                    color: Theme.textSecondary
                    font.pixelSize: 13
                }
                Label {
                    text: weatherController.fromCache ? "\u7f13\u5b58\u6570\u636e" : "\u5b9e\u65f6\u6570\u636e"
                    color: Theme.accent
                    font.pixelSize: 11
                    visible: weatherController.cityName.length > 0
                }
            }
        }

        AqiCard {
            Layout.preferredWidth: 180
            Layout.maximumWidth: 180
            Layout.preferredHeight: 180
            Layout.maximumHeight: 180
            Layout.alignment: Qt.AlignVCenter
            aqi: weatherController.aqi
            category: weatherController.aqiCategory
            level: weatherController.aqiLevel
            aqiColor: weatherController.aqiColor || Theme.aqiColor(weatherController.aqi)
        }

        MapView {
            Layout.preferredWidth: 220
            Layout.maximumWidth: 220
            Layout.preferredHeight: 200
            Layout.maximumHeight: 200
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignVCenter
            latitude: weatherController.latitude
            longitude: weatherController.longitude
            cityName: weatherController.cityName
        }
    }
}
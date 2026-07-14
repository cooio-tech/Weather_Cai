import QtQuick
//import WeatherApp

Rectangle {
    id: aqiCard
    property string aqi: ""
    property string category: ""
    property string level: ""
    property string aqiColor: "#888888"
    radius: 16
    color: aqiCard.aqiColor
    border.color: Qt.darker(aqiCard.aqiColor, 1.2)
    border.width: 2
    Column {
        anchors.centerIn: parent
        spacing: 8
        Text { text: "\u7a7a\u6c14\u8d28\u91cf"; font.pixelSize: 14; color: Theme.aqiTextColor(aqiCard.aqi); anchors.horizontalCenter: parent.horizontalCenter; opacity: 0.8 }
        Text { text: aqiCard.aqi || "--"; font.pixelSize: 48; font.bold: true; color: Theme.aqiTextColor(aqiCard.aqi); anchors.horizontalCenter: parent.horizontalCenter }
        Text { text: "AQI"; font.pixelSize: 12; color: Theme.aqiTextColor(aqiCard.aqi); anchors.horizontalCenter: parent.horizontalCenter; opacity: 0.7 }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: catText.implicitWidth + 16; height: 28; radius: 14
            color: Qt.rgba(0,0,0,0.15)
            Text { id: catText; anchors.centerIn: parent; text: aqiCard.category || Theme.aqiLabel(aqiCard.aqi); font.pixelSize: 13; font.bold: true; color: Theme.aqiTextColor(aqiCard.aqi) }
        }
    }
    Behavior on color { ColorAnimation { duration: 500 } }
}
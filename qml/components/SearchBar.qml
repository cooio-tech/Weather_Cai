import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import WeatherApp

Rectangle {
    id: searchBar
    height: 56
    radius: 12
    color: Theme.searchBg
    border.color: Theme.border
    border.width: 1
    signal searchRequested(string city)

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 12

        TextField {
            id: cityInput
            Layout.fillWidth: true
            placeholderText: "\u8f93\u5165\u57ce\u5e02\u540d\u79f0\uff0c\u5982\uff1a\u5317\u4eac\u3001\u4e0a\u6d77"
            color: Theme.textPrimary
            placeholderTextColor: Theme.textSecondary
            background: Rectangle { color: "transparent" }
            font.pixelSize: 16
            onAccepted: searchBar.searchRequested(text.trim())
        }

        Button {
            text: "\u641c\u7d22"
            highlighted: true
            onClicked: searchBar.searchRequested(cityInput.text.trim())
        }
    }
}
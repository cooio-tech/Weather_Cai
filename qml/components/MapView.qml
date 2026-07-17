import QtQuick
import QtQuick.Controls
import WeatherApp

Rectangle {
    id: mapContainer
    property double latitude: 39.9
    property double longitude: 116.4
    property string cityName: ""

    radius: 12
    color: Theme.cardBg
    border.color: Theme.border
    border.width: 1
    clip: true

    Rectangle {
        id: mapArea
        anchors.fill: parent
        anchors.margins: 6
        anchors.bottomMargin: 26
        radius: 8
        color: Theme.isDark ? "#1b3a4b" : "#a8dadc"
        border.color: Theme.border
        clip: true

        Image {
            id: mapImage
            anchors.fill: parent
            source: weatherController.mapImageSource
            fillMode: Image.PreserveAspectCrop
            cache: false
            visible: weatherController.mapImageSource.length > 0 && status === Image.Ready
            onStatusChanged: {
                if (status === Image.Error)
                    console.warn("map image error:", weatherController.mapImageSource)
            }
        }

        BusyIndicator {
            anchors.centerIn: parent
            running: weatherController.mapLoading
            visible: running
        }

        Text {
            anchors.centerIn: parent
            width: parent.width - 16
            horizontalAlignment: Text.AlignHCenter
            text: "\u5730\u56fe\u52a0\u8f7d\u5931\u8d25"
            color: Theme.textSecondary
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            visible: !weatherController.mapLoading
                     && weatherController.mapImageSource.length === 0
                     && (Math.abs(latitude) > 0.001 || Math.abs(longitude) > 0.001)
        }

        Column {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6
            spacing: 4

            ToolButton {
                text: "+"
                font.pixelSize: 14
                font.bold: true
                implicitWidth: 28
                implicitHeight: 24
                enabled: weatherController.mapZoom < 17 && !weatherController.mapLoading
                background: Rectangle {
                    radius: 4
                    color: parent.enabled ? Qt.rgba(0, 0, 0, 0.55) : Qt.rgba(0, 0, 0, 0.25)
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font: parent.font
                }
                onClicked: weatherController.mapZoomIn()
            }

            ToolButton {
                text: "\u2212"
                font.pixelSize: 14
                font.bold: true
                implicitWidth: 28
                implicitHeight: 24
                enabled: weatherController.mapZoom > 8 && !weatherController.mapLoading
                background: Rectangle {
                    radius: 4
                    color: parent.enabled ? Qt.rgba(0, 0, 0, 0.55) : Qt.rgba(0, 0, 0, 0.25)
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font: parent.font
                }
                onClicked: weatherController.mapZoomOut()
            }
        }

        Text {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 16
            horizontalAlignment: Text.AlignHCenter
            text: mapContainer.cityName
            color: "white"
            font.pixelSize: 12
            font.bold: true
            elide: Text.ElideRight
            maximumLineCount: 1
            visible: mapImage.visible && mapContainer.cityName.length > 0
            style: Text.Outline
            styleColor: "#00000080"
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 26
        color: Qt.rgba(0, 0, 0, 0.55)

        Text {
            anchors.centerIn: parent
            width: parent.width - 10
            horizontalAlignment: Text.AlignHCenter
            text: latitude.toFixed(2) + ", " + longitude.toFixed(2)
            color: "white"
            font.pixelSize: 11
            elide: Text.ElideMiddle
        }
    }
}

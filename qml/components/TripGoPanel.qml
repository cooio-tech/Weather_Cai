import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import WeatherApp

Rectangle {
    id: tripRoot
    radius: 16
    color: Theme.surface
    border.color: Theme.border
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: "\u6309\u5929\u6c14\u4e0e\u8ddd\u79bb\u7efc\u5408\u63a8\u8350"
                font.pixelSize: 11
                color: Theme.textSecondary
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Text {
                text: "\u4e03\u65e5\u9884\u62a5"
                font.pixelSize: 12
                color: Theme.textSecondary
                Layout.alignment: Qt.AlignVCenter
            }
            Button {
                text: "\u83b7\u53d6\u5efa\u8bae"
                implicitHeight: 28
                enabled: weatherController.cityName.length > 0 && !weatherController.tripGoLoading
                onClicked: weatherController.fetchTripGo(7)
            }
        }

        Text {
            visible: weatherController.cityName.length === 0
            text: "\u8bf7\u5148\u641c\u7d22\u5f53\u524d\u57ce\u5e02\uff0c\u518d\u83b7\u53d6\u51fa\u884c\u5efa\u8bae"
            font.pixelSize: 12
            color: Theme.textSecondary
            Layout.fillWidth: true
        }

        BusyIndicator {
            visible: weatherController.tripGoLoading
            running: visible
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 24
            implicitHeight: 24
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: weatherController.tripGoResults

            delegate: Rectangle {
                width: ListView.view.width
                height: contentCol.implicitHeight + 16
                radius: 8
                color: Theme.cardBg
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    id: contentCol
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 3

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: (index + 1)
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.textSecondary
                            Layout.preferredWidth: 18
                        }
                        Text {
                            text: modelData.cityName
                            font.pixelSize: 13
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Rectangle {
                            visible: modelData.distanceBand && modelData.distanceBand.length > 0
                            radius: 4
                            color: Theme.isDark ? "#2a3a5c" : "#e8f0f5"
                            implicitHeight: 18
                            implicitWidth: bandLabel.implicitWidth + 10
                            Text {
                                id: bandLabel
                                anchors.centerIn: parent
                                text: modelData.distanceBand + (modelData.distanceKm >= 0 ? (" " + Math.round(modelData.distanceKm) + "km") : "")
                                font.pixelSize: 10
                                color: Theme.highlight
                            }
                        }
                        Item { Layout.fillWidth: true }
                        Button {
                            text: "\u67e5\u770b"
                            flat: true
                            implicitHeight: 24
                            onClicked: weatherController.searchCity(modelData.cityName)
                        }
                    }

                    Text {
                        text: modelData.summary
                        font.pixelSize: 10
                        color: Theme.textPrimary
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        Layout.leftMargin: 18
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }


                    Text {
                        text: modelData.reason
                        font.pixelSize: 10
                        color: Theme.textSecondary
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        Layout.leftMargin: 18
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }

                    Text {
                        text: modelData.activities
                        font.pixelSize: 10
                        color: Theme.textSecondary
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        Layout.leftMargin: 18
                        maximumLineCount: 1
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
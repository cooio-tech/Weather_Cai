import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import WeatherApp

Rectangle {
    id: settingsPanel
    radius: 16
    color: Theme.surface
    border.color: Theme.border
    border.width: 1

    ScrollView {
        id: scroll
        anchors.fill: parent
        anchors.margins: 16
        clip: true
        contentWidth: availableWidth

        ColumnLayout {
            width: scroll.availableWidth
            spacing: 14

            Text { text: "\u8bbe\u7f6e"; font.pixelSize: 22; font.bold: true; color: Theme.textPrimary }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                Text { text: "\u4e3b\u9898\u6a21\u5f0f"; font.pixelSize: 14; color: Theme.textSecondary }
                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: settingsManager.darkTheme ? "\u263e \u6df1\u8272" : "\u2600 \u6d45\u8272"
                        color: Theme.textPrimary
                        Layout.fillWidth: true
                    }
                    Switch {
                        checked: settingsManager.darkTheme
                        onToggled: settingsManager.darkTheme = checked
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                Text { text: "\u8bed\u97f3\u64ad\u62a5"; font.pixelSize: 14; color: Theme.textSecondary }
                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: settingsManager.voiceEnabled ? "\u5df2\u5f00\u542f" : "\u5df2\u5173\u95ed"
                        color: Theme.textPrimary
                        Layout.fillWidth: true
                    }
                    Switch {
                        checked: settingsManager.voiceEnabled
                        onToggled: settingsManager.voiceEnabled = checked
                    }
                }
                Button {
                    text: "\u7acb\u5373\u64ad\u62a5"
                    Layout.fillWidth: true
                    enabled: weatherController.cityName.length > 0
                    onClicked: weatherController.speakWeather(true)
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                Text { text: "\u684c\u9762\u5c0f\u7ec4\u4ef6"; font.pixelSize: 14; color: Theme.textSecondary }
                Label {
                    text: "\u53ef\u62d6\u62fd\u79fb\u52a8\uff1b\u62d6\u52a8\u53f3\u4e0b\u89d2\u53ef\u7f29\u653e\u5c3a\u5bf8"
                    font.pixelSize: 11
                    color: Theme.textSecondary
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                Button {
                    text: "\u663e\u793a/\u9690\u85cf\u684c\u9762\u5c0f\u7ec4\u4ef6"
                    Layout.fillWidth: true
                    onClicked: desktopManager.toggleWidget()
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                Text { text: "\u6536\u85cf\u57ce\u5e02"; font.pixelSize: 14; color: Theme.textSecondary }
                Text {
                    visible: settingsManager.favoriteCities.length === 0
                    text: "\u70b9\u51fb\u641c\u7d22\u680f\u661f\u6807\u53ef\u6536\u85cf\u5f53\u524d\u57ce\u5e02"
                    font.pixelSize: 11
                    color: Theme.textSecondary
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                Repeater {
                    model: settingsManager.favoriteCities
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Button {
                            Layout.fillWidth: true
                            flat: true
                            contentItem: Text {
                                text: modelData
                                color: Theme.textPrimary
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                radius: 6
                                color: parent.hovered || parent.down
                                       ? (Theme.isDark ? "#2a3a5c" : "#eeeeee")
                                       : "transparent"
                            }
                            onClicked: weatherController.searchCity(modelData)
                        }
                        ToolButton {
                            contentItem: Text {
                                text: "\u00d7"
                                color: Theme.textSecondary
                                font.pixelSize: 14
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: settingsManager.removeFavoriteCity(modelData)
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                Text { text: "\u6570\u636e\u7f13\u5b58"; font.pixelSize: 14; color: Theme.textSecondary }
                Label {
                    text: "\u672c\u5730 SQLite \u7f13\u5b58\uff0c30\u5206\u949f\u6709\u6548"
                    font.pixelSize: 12
                    color: Theme.textSecondary
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                Button {
                    text: "\u6e05\u7406\u7f13\u5b58"
                    Layout.fillWidth: true
                    onClicked: settingsManager.clearCache()
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                Text { text: "AQI \u7b49\u7ea7\u8bf4\u660e"; font.pixelSize: 14; color: Theme.textSecondary }
                Repeater {
                    model: [
                        { label: "\u4f18 (0-50)", color: "#81C784" },
                        { label: "\u826f (51-100)", color: "#FFD54F" },
                        { label: "\u8f7b\u5ea6\u6c61\u67d3 (101-150)", color: "#FFB74D" },
                        { label: "\u4e2d\u5ea6\u6c41\u67d3 (151-200)", color: "#E57373" },
                        { label: "\u91cd\u5ea6\u6c41\u67d3 (201-300)", color: "#BA68C8" },
                        { label: "\u4e25\u91cd\u6c41\u67d3 (>300)", color: "#9575A8" }
                    ]
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Rectangle { width: 16; height: 16; radius: 4; color: modelData.color }
                        Text { text: modelData.label; font.pixelSize: 11; color: Theme.textSecondary }
                    }
                }
            }
        }
    }
}

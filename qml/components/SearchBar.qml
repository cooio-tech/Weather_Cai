import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
//import WeatherApp

Item {
    id: searchBar
    height: 56
    z: 50
    signal searchRequested(string city)
    property bool suppressPopup: false   //联想框开关

    function doSearch(city) {
        var name = (city || "").trim()
        if (!name.length) return
        searchBar.suppressPopup = true
        suggestTimer.stop()
        weatherController.clearSuggestions()
        popup.close()
        cityInput.focus = false  //输入框失焦
        settingsManager.addRecentCity(name)
        searchBar.searchRequested(name)
    }

    Rectangle {
        id: barBg
        anchors.fill: parent
        radius: 12
        color: Theme.searchBg
        border.color: Theme.border
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            TextField {
                id: cityInput
                Layout.fillWidth: true
                placeholderText: "\u8f93\u5165\u57ce\u5e02 / \u62fc\u97f3\uff0c\u5982\uff1a\u5317\u4eac\u3001huizhou"
                color: Theme.textPrimary
                placeholderTextColor: Theme.textSecondary
                background: Rectangle { color: "transparent" }
                font.pixelSize: 16
                onAccepted: searchBar.doSearch(text)
                onTextChanged: {
                    searchBar.suppressPopup = false
                    if (text.trim().length >= 1)
                        suggestTimer.restart()
                    else {
                        suggestTimer.stop()
                        weatherController.clearSuggestions()
                    }
                }
                onActiveFocusChanged: {
                    if (activeFocus && !searchBar.suppressPopup)
                        popup.open()
                }
            }

            ToolButton {
                visible: weatherController.cityName.length > 0
                text: settingsManager.favoriteCities.indexOf(weatherController.cityName) >= 0 ? "\u2605" : "\u2606"
                font.pixelSize: 18
                ToolTip.visible: hovered
                ToolTip.text: settingsManager.favoriteCities.indexOf(weatherController.cityName) >= 0
                              ? "\u53d6\u6d88\u6536\u85cf" : "\u6536\u85cf\u5f53\u524d\u57ce\u5e02"
                onClicked: settingsManager.toggleFavoriteCity(weatherController.cityName)
            }

            Button {
                text: "\u641c\u7d22"
                highlighted: true
                onClicked: searchBar.doSearch(cityInput.text)
            }
        }
    }

    //防抖Timer
    Timer {
        id: suggestTimer
        interval: 280
        repeat: false
        onTriggered: weatherController.suggestCities(cityInput.text)
    }

    Popup {
        id: popup
        x: 0
        y: searchBar.height + 4
        width: searchBar.width
        padding: 0
        modal: false
        focus: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
        background: Rectangle {
            radius: 12
            color: Theme.popupBg
            border.color: Theme.border
            border.width: 1
        }

        contentItem: Column {
            id: popupCol
            width: popup.width
            spacing: 0
            padding: 8

            property bool hasSuggest: weatherController.citySuggestions
                                      && weatherController.citySuggestions.length > 0
            property bool hasFav: settingsManager.favoriteCities.length > 0
            property bool hasRecent: settingsManager.recentCities.length > 0
            property bool empty: !hasSuggest && !hasFav && !hasRecent

            Text {
                visible: popupCol.empty
                width: parent.width - 16
                leftPadding: 8
                text: "\u8f93\u5165\u57ce\u5e02\u540d\u53ef\u8054\u60f3\uff1b\u6216\u4ece\u6536\u85cf/\u6700\u8fd1\u9009\u62e9"
                color: Theme.textSecondary
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Text {
                visible: popupCol.hasSuggest
                text: "\u641c\u7d22\u5efa\u8bae"
                color: Theme.textSecondary
                font.pixelSize: 11
                leftPadding: 8
                topPadding: 4
                bottomPadding: 4
            }

            Repeater {
                model: weatherController.citySuggestions
                delegate: Item {
                    width: popup.width - 16
                    height: 36
                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: sugMa.containsMouse ? Theme.cardBg : "transparent"
                    }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8
                        Text {
                            text: modelData.name || ""
                            color: Theme.textPrimary
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Text {
                            Layout.fillWidth: true
                            text: [modelData.adm2, modelData.adm1, modelData.country]
                                      .filter(function(x) { return x && x.length })
                                      .join(" \u00b7 ")
                            color: Theme.textSecondary
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }
                    MouseArea {
                        id: sugMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            cityInput.text = modelData.name
                            searchBar.doSearch(modelData.name)
                        }
                    }
                }
            }

            Rectangle {
                visible: popupCol.hasSuggest && (popupCol.hasFav || popupCol.hasRecent)
                width: parent.width - 16
                height: 1
                color: Theme.border
            }

            Text {
                visible: popupCol.hasFav
                text: "\u6536\u85cf\u57ce\u5e02"
                color: Theme.textSecondary
                font.pixelSize: 11
                leftPadding: 8
                topPadding: 6
                bottomPadding: 4
            }

            Flow {
                visible: popupCol.hasFav
                width: parent.width - 16
                spacing: 6
                leftPadding: 8
                Repeater {
                    model: settingsManager.favoriteCities
                    delegate: Rectangle {
                        radius: 14
                        height: 28
                        width: favTxt.implicitWidth + 20
                        color: Theme.cardBg
                        border.color: Theme.border
                        border.width: 1
                        Text {
                            id: favTxt
                            anchors.centerIn: parent
                            text: modelData
                            color: Theme.textPrimary
                            font.pixelSize: 12
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                cityInput.text = modelData
                                searchBar.doSearch(modelData)
                            }
                        }
                    }
                }
            }

            Text {
                visible: popupCol.hasRecent
                text: "\u6700\u8fd1\u641c\u7d22"
                color: Theme.textSecondary
                font.pixelSize: 11
                leftPadding: 8
                topPadding: 6
                bottomPadding: 4
            }

            Repeater {
                model: settingsManager.recentCities
                delegate: Item {
                    width: popup.width - 16
                    height: 32
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        text: modelData
                        color: Theme.textPrimary
                        font.pixelSize: 13
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            cityInput.text = modelData
                            searchBar.doSearch(modelData)
                        }
                        onEntered: parent.opacity = 0.7
                        onExited: parent.opacity = 1
                    }
                }
            }
        }
    }

    Connections {
        target: weatherController
        function onSuggestionsChanged() {
            if (searchBar.suppressPopup) {
                popup.close()
                return
            }
            if (cityInput.activeFocus && weatherController.citySuggestions.length > 0)
                popup.open()
            else if (weatherController.citySuggestions.length === 0)
                popup.close()
        }
        function onWeatherChanged() {
            if (weatherController.cityName.length > 0)
                settingsManager.addRecentCity(weatherController.cityName)
            searchBar.suppressPopup = true
            popup.close()
        }
    }
}

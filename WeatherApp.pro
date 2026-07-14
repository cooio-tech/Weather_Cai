QT += core gui widgets quick quickcontrols2 network sql qml texttospeech charts

CONFIG += c++17 warn_on depend_includepath
CONFIG -= app_bundle

TEMPLATE = app
TARGET = WeatherApp

SOURCES += \
    src/main.cpp \
    src/WeatherController.cpp \
    src/WeatherApiClient.cpp \
    src/WeatherCache.cpp \
    src/SettingsManager.cpp \
    src/DesktopManager.cpp \

HEADERS += \
    src/WeatherController.h \
    src/WeatherApiClient.h \
    src/WeatherCache.h \
    src/SettingsManager.h \
    src/DesktopManager.h

RESOURCES += resources.qrc
INCLUDEPATH += src
DESTDIR = $$OUT_PWD/bin

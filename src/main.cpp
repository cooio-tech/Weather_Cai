#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include "WeatherController.h"
#include "SettingsManager.h"
#include "DesktopManager.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    app.setOrganizationName("WeatherApp");
    app.setApplicationName("WeatherApp");
    app.setQuitOnLastWindowClosed(false);

    QQuickStyle::setStyle("Basic");

    WeatherController controller;
    SettingsManager settings;

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral("qrc:/"));
    engine.rootContext()->setContextProperty("weatherController", &controller);
    engine.rootContext()->setContextProperty("settingsManager", &settings);

    DesktopManager desktop(&app, &engine, &controller);
    engine.rootContext()->setContextProperty("desktopManager", &desktop);

    QObject::connect(&controller, &WeatherController::weatherChanged,
                     &desktop, &DesktopManager::refreshWidget);

    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        }, Qt::QueuedConnection);

    engine.load(url);
    desktop.initializeWidget();

    return app.exec();
}
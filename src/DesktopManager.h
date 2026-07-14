#pragma once

#include <QObject>
#include <QSystemTrayIcon>
#include <QMenu>

class QApplication;
class QQmlApplicationEngine;
class WeatherController;
class QWindow;

class DesktopManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool widgetVisible READ widgetVisible NOTIFY widgetVisibleChanged)

public:
    DesktopManager(QApplication *app, QQmlApplicationEngine *engine,
                   WeatherController *controller, QObject *parent = nullptr);

    bool widgetVisible() const { return m_widgetVisible; }

    Q_INVOKABLE void initializeWidget();
    Q_INVOKABLE void showMainWindow();
    Q_INVOKABLE void toggleWidget();
    Q_INVOKABLE void hideWidget();
    Q_INVOKABLE void refreshWidget();

signals:
    void widgetVisibleChanged();
    void openMainWindow();

private:
    void setupTray();
    bool loadWidget();
    void positionWidget(QWindow *window);
    QWindow *widgetWindow() const;

    QApplication *m_app;
    QQmlApplicationEngine *m_engine;
    WeatherController *m_controller;
    QSystemTrayIcon *m_tray = nullptr;
    QMenu *m_trayMenu = nullptr;
    QObject *m_widgetRoot = nullptr;
    bool m_widgetVisible = false;
};
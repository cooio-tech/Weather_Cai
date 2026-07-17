#include "DesktopManager.h"
#include "WeatherController.h"

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQuickWindow>
#include <QIcon>
#include <QStyle>
#include <QAction>
#include <QScreen>
#include <QGuiApplication>
#include <QDebug>


DesktopManager::DesktopManager(QApplication *app, QQmlApplicationEngine *engine,
                               WeatherController *controller, QObject *parent)
    : QObject(parent)
    , m_app(app)
    , m_engine(engine)
    , m_controller(controller)
{
    setupTray();
}

void DesktopManager::initializeWidget()
{
    loadWidget();
}

void DesktopManager::setupTray()
{
    if (!QSystemTrayIcon::isSystemTrayAvailable()) {
        qWarning() << "System tray is not available";
        return;
    }

    m_trayMenu = new QMenu();
    auto *showMain = m_trayMenu->addAction(QString::fromUtf8("\xe6\x89\x93\xe5\xbc\x80\xe4\xb8\xbb\xe7\xaa\x97\xe5\x8f\xa3"));
    auto *toggleWidgetAction = m_trayMenu->addAction(QString::fromUtf8("\xe6\x98\xbe\xe7\xa4\xba/\xe9\x9a\x90\xe8\x97\x8f\xe5\xb0\x8f\xe7\xbb\x84\xe4\xbb\xb6"));
    m_trayMenu->addSeparator();
    auto *quit = m_trayMenu->addAction(QString::fromUtf8("\xe9\x80\x80\xe5\x87\xba"));

    connect(showMain, &QAction::triggered, this, &DesktopManager::showMainWindow);
    connect(toggleWidgetAction, &QAction::triggered, this, &DesktopManager::toggleWidget);
    connect(quit, &QAction::triggered, m_app, &QApplication::quit);

    m_tray = new QSystemTrayIcon(m_app);
    m_tray->setIcon(m_app->style()->standardIcon(QStyle::SP_ComputerIcon));
    m_tray->setToolTip(QString::fromUtf8("\xe5\xa4\xa9\xe6\xb0\x94\xe5\xb0\x8f\xe7\xbb\x84\xe4\xbb\xb6"));
    m_tray->setContextMenu(m_trayMenu);
    m_tray->show();

    connect(m_tray, &QSystemTrayIcon::activated, this, [this](QSystemTrayIcon::ActivationReason reason) {
        if (reason == QSystemTrayIcon::DoubleClick)
            this->toggleWidget();
    });
}

bool DesktopManager::loadWidget()
{
    if (m_widgetRoot)
        return widgetWindow() != nullptr;

    QQmlComponent component(m_engine, QUrl(QStringLiteral("qrc:/qml/WidgetWindow.qml")));
    if (component.isError()) {
        qWarning() << "Widget QML load error:" << component.errors();
        return false;
    }

    m_widgetRoot = component.create(m_engine->rootContext());
    if (!m_widgetRoot) {
        qWarning() << "Widget QML create failed:" << component.errors();
        return false;
    }

    if (auto *window = widgetWindow()) {
        window->setFlags(Qt::Tool | Qt::FramelessWindowHint | Qt::WindowStaysOnTopHint);
        window->setVisible(false);
        return true;
    }

    qWarning() << "Widget root is not a window:" << m_widgetRoot->metaObject()->className();
    return false;
}

QWindow *DesktopManager::widgetWindow() const
{
    if (!m_widgetRoot)
        return nullptr;
    if (auto *window = qobject_cast<QWindow *>(m_widgetRoot))
        return window;
    return qobject_cast<QWindow *>(m_widgetRoot->findChild<QWindow *>());
}

void DesktopManager::showMainWindow()
{
    const auto windows = m_engine->rootObjects();
    for (QObject *obj : windows) {
        if (auto *w = qobject_cast<QWindow *>(obj)) {
            if (w != widgetWindow()) {
                w->show();
                w->raise();
                w->requestActivate();
            }
        }
    }
    emit openMainWindow();
}

void DesktopManager::positionWidget(QWindow *window)
{
    if (!window)
        return;

    QScreen *screen = QGuiApplication::primaryScreen();
    if (!screen)
        return;

    const QRect geo = screen->availableGeometry();
    window->setX(geo.right() - window->width() - 24);
    window->setY(geo.bottom() - window->height() - 24);
}

void DesktopManager::toggleWidget()
{
    if (!m_widgetRoot && !loadWidget()) {
        qWarning() << "Cannot toggle widget: load failed";
        return;
    }

    auto *window = widgetWindow();
    if (!window) {
        qWarning() << "Cannot toggle widget: window is null";
        return;
    }

    m_widgetVisible = !m_widgetVisible;
    if (m_widgetVisible) {
        positionWidget(window);
        window->show();
        window->raise();
        refreshWidget();
    } else {
        window->hide();
    }
    emit widgetVisibleChanged();
}

void DesktopManager::hideWidget()
{
    if (auto *window = widgetWindow()) {
        m_widgetVisible = false;
        window->hide();
        emit widgetVisibleChanged();
    }
}

void DesktopManager::refreshWidget()
{
    if (m_tray && !m_controller->cityName().isEmpty()) {
        const QString degree = QString::fromUtf8("\xc2\xb0");
        m_tray->setToolTip(m_controller->cityName() + " " + m_controller->temperature()
                           + degree + "C " + m_controller->weatherText());
    }
}

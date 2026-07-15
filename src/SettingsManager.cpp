#include "SettingsManager.h"

SettingsManager::SettingsManager(QObject *parent)
    : QObject(parent)
    , m_settings("WeatherApp", "WeatherApp")
    , m_darkTheme(m_settings.value("darkTheme", false).toBool())
    , m_voiceEnabled(m_settings.value("voiceEnabled", false).toBool())
    , m_animationsEnabled(m_settings.value("animationsEnabled", true).toBool())
    , m_refreshIntervalMin(m_settings.value("refreshIntervalMin", 0).toInt())
    , m_widgetWidth(clampW(m_settings.value("widgetWidth", 178).toInt()))
    , m_widgetHeight(clampH(m_settings.value("widgetHeight", 78).toInt()))
{
    loadLists();
}

void SettingsManager::loadLists()
{
    m_favoriteCities = m_settings.value("favoriteCities").toStringList();
    m_recentCities = m_settings.value("recentCities").toStringList();
}

void SettingsManager::saveFavorites()
{
    m_settings.setValue("favoriteCities", m_favoriteCities);
}

void SettingsManager::saveRecent()
{
    m_settings.setValue("recentCities", m_recentCities);
}

int SettingsManager::clampW(int w)
{
    if (w < 140) return 140;
    if (w > 360) return 360;
    return w;
}

int SettingsManager::clampH(int h)
{
    if (h < 60) return 60;
    if (h > 160) return 160;
    return h;
}

void SettingsManager::setDarkTheme(bool enabled)
{
    if (m_darkTheme == enabled) return;
    m_darkTheme = enabled;
    m_settings.setValue("darkTheme", enabled);
    emit darkThemeChanged();
}

void SettingsManager::setVoiceEnabled(bool enabled)
{
    if (m_voiceEnabled == enabled) return;
    m_voiceEnabled = enabled;
    m_settings.setValue("voiceEnabled", enabled);
    emit voiceEnabledChanged();
}

void SettingsManager::setWidgetWidth(int w)
{
    w = clampW(w);
    if (m_widgetWidth == w) return;
    m_widgetWidth = w;
    m_settings.setValue("widgetWidth", w);
    emit widgetSizeChanged();
}

void SettingsManager::setWidgetHeight(int h)
{
    h = clampH(h);
    if (m_widgetHeight == h) return;
    m_widgetHeight = h;
    m_settings.setValue("widgetHeight", h);
    emit widgetSizeChanged();
}

void SettingsManager::setWidgetSize(int w, int h)
{
    w = clampW(w);
    h = clampH(h);
    const bool changed = (m_widgetWidth != w) || (m_widgetHeight != h);
    m_widgetWidth = w;
    m_widgetHeight = h;
    m_settings.setValue("widgetWidth", w);
    m_settings.setValue("widgetHeight", h);
    if (changed)
        emit widgetSizeChanged();
}

void SettingsManager::clearCache()
{
    emit cacheCleared();
}

void SettingsManager::addRecentCity(const QString &city)
{
    const QString name = city.trimmed();
    if (name.isEmpty()) return;
    m_recentCities.removeAll(name);
    m_recentCities.prepend(name);
    while (m_recentCities.size() > 8)
        m_recentCities.removeLast();
    saveRecent();
    emit recentChanged();
}

void SettingsManager::toggleFavoriteCity(const QString &city)
{
    const QString name = city.trimmed();
    if (name.isEmpty()) return;
    if (m_favoriteCities.contains(name))
        m_favoriteCities.removeAll(name);
    else {
        m_favoriteCities.removeAll(name);
        m_favoriteCities.prepend(name);
        while (m_favoriteCities.size() > 12)
            m_favoriteCities.removeLast();
    }
    saveFavorites();
    emit favoritesChanged();
}

bool SettingsManager::isFavoriteCity(const QString &city) const
{
    return m_favoriteCities.contains(city.trimmed());
}

void SettingsManager::removeFavoriteCity(const QString &city)
{
    const QString name = city.trimmed();
    if (!m_favoriteCities.contains(name)) return;
    m_favoriteCities.removeAll(name);
    saveFavorites();
    emit favoritesChanged();
}

void SettingsManager::clearRecentCities()
{
    if (m_recentCities.isEmpty()) return;
    m_recentCities.clear();
    saveRecent();
    emit recentChanged();
}

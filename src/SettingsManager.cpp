#include "SettingsManager.h"

SettingsManager::SettingsManager(QObject *parent)
    : QObject(parent)
    , m_settings("WeatherApp", "WeatherApp")
    , m_darkTheme(m_settings.value("darkTheme", false).toBool())
    , m_voiceEnabled(m_settings.value("voiceEnabled", false).toBool())
{
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

void SettingsManager::clearCache()
{
    emit cacheCleared();
}

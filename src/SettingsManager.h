#pragma once

#include <QObject>
#include <QSettings>

class SettingsManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool darkTheme READ darkTheme WRITE setDarkTheme NOTIFY darkThemeChanged)
    Q_PROPERTY(bool voiceEnabled READ voiceEnabled WRITE setVoiceEnabled NOTIFY voiceEnabledChanged)

public:
    explicit SettingsManager(QObject *parent = nullptr);

    bool darkTheme() const { return m_darkTheme; }
    bool voiceEnabled() const { return m_voiceEnabled; }

    void setDarkTheme(bool enabled);
    void setVoiceEnabled(bool enabled);

    Q_INVOKABLE void clearCache();

signals:
    void darkThemeChanged();
    void voiceEnabledChanged();
    void cacheCleared();

private:
    QSettings m_settings;
    bool m_darkTheme;
    bool m_voiceEnabled;
};

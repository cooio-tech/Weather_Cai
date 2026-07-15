#pragma once

#include <QObject>
#include <QSettings>
#include <QStringList>

class SettingsManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool darkTheme READ darkTheme WRITE setDarkTheme NOTIFY darkThemeChanged)
    Q_PROPERTY(bool voiceEnabled READ voiceEnabled WRITE setVoiceEnabled NOTIFY voiceEnabledChanged)
    Q_PROPERTY(QStringList favoriteCities READ favoriteCities NOTIFY favoritesChanged)
    Q_PROPERTY(QStringList recentCities READ recentCities NOTIFY recentChanged)
    Q_PROPERTY(bool animationsEnabled READ animationsEnabled NOTIFY animationsEnabledChanged)
    Q_PROPERTY(int refreshIntervalMin READ refreshIntervalMin NOTIFY refreshIntervalChanged)
    Q_PROPERTY(int widgetWidth READ widgetWidth WRITE setWidgetWidth NOTIFY widgetSizeChanged)
    Q_PROPERTY(int widgetHeight READ widgetHeight WRITE setWidgetHeight NOTIFY widgetSizeChanged)

public:
    explicit SettingsManager(QObject *parent = nullptr);

    bool darkTheme() const { return m_darkTheme; }
    bool voiceEnabled() const { return m_voiceEnabled; }
    QStringList favoriteCities() const { return m_favoriteCities; }
    QStringList recentCities() const { return m_recentCities; }
    bool animationsEnabled() const { return m_animationsEnabled; }
    int refreshIntervalMin() const { return m_refreshIntervalMin; }
    int widgetWidth() const { return m_widgetWidth; }
    int widgetHeight() const { return m_widgetHeight; }

    void setDarkTheme(bool enabled);
    void setVoiceEnabled(bool enabled);
    void setWidgetWidth(int w);
    void setWidgetHeight(int h);

    Q_INVOKABLE void setWidgetSize(int w, int h);
    Q_INVOKABLE void clearCache();
    Q_INVOKABLE void addRecentCity(const QString &city);
    Q_INVOKABLE void toggleFavoriteCity(const QString &city);
    Q_INVOKABLE bool isFavoriteCity(const QString &city) const;
    Q_INVOKABLE void removeFavoriteCity(const QString &city);
    Q_INVOKABLE void clearRecentCities();

signals:
    void darkThemeChanged();
    void voiceEnabledChanged();
    void cacheCleared();
    void favoritesChanged();
    void recentChanged();
    void animationsEnabledChanged();
    void refreshIntervalChanged();
    void widgetSizeChanged();

private:
    void loadLists();
    void saveFavorites();
    void saveRecent();
    static int clampW(int w);
    static int clampH(int h);

    QSettings m_settings;
    bool m_darkTheme;
    bool m_voiceEnabled;
    QStringList m_favoriteCities;
    QStringList m_recentCities;
    bool m_animationsEnabled = true;
    int m_refreshIntervalMin = 0;
    int m_widgetWidth = 178;
    int m_widgetHeight = 78;
};

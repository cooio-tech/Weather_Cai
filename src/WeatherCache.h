#pragma once

#include <QObject>
#include <QJsonObject>
#include <QSqlDatabase>

class WeatherCache : public QObject
{
    Q_OBJECT

public:
    explicit WeatherCache(QObject *parent = nullptr);
    ~WeatherCache() override;

    QJsonObject getWeather(const QString &city);
    void saveWeather(const QString &city, const QJsonObject &data);
    void clearAll();

private:
    bool initDatabase();

    QSqlDatabase m_db;
    static constexpr int CACHE_TTL_MINUTES = 30;
};

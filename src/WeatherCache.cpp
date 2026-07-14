#include "WeatherCache.h"

#include <QSqlQuery>
#include <QSqlError>
#include <QJsonDocument>
#include <QStandardPaths>
#include <QDir>
#include <QDateTime>
#include <QDebug>

WeatherCache::WeatherCache(QObject *parent)
    : QObject(parent)
{
    initDatabase();
}

WeatherCache::~WeatherCache()
{
    if (m_db.isOpen()) {
        m_db.close();
    }
}

bool WeatherCache::initDatabase()
{
    QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataPath);

    m_db = QSqlDatabase::addDatabase("QSQLITE", "weather_cache");
    m_db.setDatabaseName(dataPath + "/weather_cache.db");

    if (!m_db.open()) {
        qWarning() << "SQLite open failed:" << m_db.lastError().text();
        return false;
    }

    QSqlQuery query(m_db);
    query.exec(R"(
        CREATE TABLE IF NOT EXISTS weather_cache (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            city_name TEXT NOT NULL UNIQUE,
            json_data TEXT NOT NULL,
            created_at TEXT NOT NULL,
            expires_at TEXT NOT NULL
        )
    )");

    return true;
}

QJsonObject WeatherCache::getWeather(const QString &city)
{
    QSqlQuery query(m_db);
    query.prepare("SELECT json_data, expires_at FROM weather_cache WHERE city_name = ?");
    query.addBindValue(city);
    query.exec();

    if (!query.next()) return {};

    QString expiresAt = query.value(1).toString();
    if (QDateTime::fromString(expiresAt, Qt::ISODate) < QDateTime::currentDateTime()) {
        QSqlQuery del(m_db);
        del.prepare("DELETE FROM weather_cache WHERE city_name = ?");
        del.addBindValue(city);
        del.exec();
        return {};
    }

    QJsonDocument doc = QJsonDocument::fromJson(query.value(0).toString().toUtf8());
    return doc.object();
}

void WeatherCache::saveWeather(const QString &city, const QJsonObject &data)
{
    QSqlQuery query(m_db);
    query.prepare(R"(
        INSERT OR REPLACE INTO weather_cache (city_name, json_data, created_at, expires_at)
        VALUES (?, ?, ?, ?)
    )");
    query.addBindValue(city);
    query.addBindValue(QString::fromUtf8(QJsonDocument(data).toJson(QJsonDocument::Compact)));
    query.addBindValue(QDateTime::currentDateTime().toString(Qt::ISODate));
    query.addBindValue(QDateTime::currentDateTime().addSecs(CACHE_TTL_MINUTES * 60).toString(Qt::ISODate));
    query.exec();
}

void WeatherCache::clearAll()
{
    QSqlQuery query(m_db);
    query.exec("DELETE FROM weather_cache");
}

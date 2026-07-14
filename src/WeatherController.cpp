#include "WeatherController.h"
#include "WeatherApiClient.h"
#include "WeatherCache.h"
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QStandardPaths>
#include <QDateTime>
#include <QUrl>

WeatherController::WeatherController(QObject *parent)
    : QObject(parent)
    , m_apiClient(new WeatherApiClient(this))
    , m_cache(new WeatherCache(this))
{
    connect(m_apiClient, &WeatherApiClient::weatherReceived,
            this, &WeatherController::onWeatherReceived);
    connect(m_apiClient, &WeatherApiClient::tripGoReceived,
            this, &WeatherController::onTripGoReceived);
    connect(m_apiClient, &WeatherApiClient::briefReceived,
            this, &WeatherController::onBriefReceived);
    connect(m_apiClient, &WeatherApiClient::mapImageReceived,
            this, &WeatherController::onMapImageReceived);
    connect(m_apiClient, &WeatherApiClient::mapImageFailed,
            this, &WeatherController::onMapImageFailed);
    connect(m_apiClient, &WeatherApiClient::errorOccurred,
            this, &WeatherController::onError);
}

WeatherController::~WeatherController() = default;

void WeatherController::searchCity(const QString &city)
{
    if (city.trimmed().isEmpty()) {
        m_errorMessage = QString::fromUtf8("\xe8\xaf\xb7\xe8\xbe\x93\xe5\x85\xa5\xe5\x9f\x8e\xe5\xb8\x82\xe5\x90\x8d\xe7\xa7\xb0");
        emit errorChanged();
        return;
    }

    m_loading = true;
    emit loadingChanged();
    m_errorMessage.clear();
    emit errorChanged();

    QJsonObject cached = m_cache->getWeather(city);
    if (!cached.isEmpty() && !cached.value("hourly").toArray().isEmpty()) {
        parseWeatherData(cached);
        m_fromCache = true;
        m_loading = false;
        emit loadingChanged();
        emit weatherChanged();
        return;
    }

    m_apiClient->fetchWeather(city);
}

void WeatherController::clearLocalCache() { m_cache->clearAll(); }
void WeatherController::clearAllCache() { m_cache->clearAll(); m_apiClient->clearServerCache(); }

void WeatherController::speakWeather(bool enabled)
{
    if (!enabled || m_speechText.isEmpty()) return;
    qDebug() << "[speech]" << m_speechText;
}

void WeatherController::fetchTripGo(int days)
{
    m_tripGoLoading = true;
    emit tripGoChanged();
    m_apiClient->fetchTripGo(days, m_latitude, m_longitude, m_cityName);
}

void WeatherController::fetchBriefWeather(const QStringList &cities)
{
    m_apiClient->fetchBrief(cities);
}

void WeatherController::onWeatherReceived(const QJsonObject &data, bool fromCache)
{
    m_fromCache = fromCache;
    parseWeatherData(data);
    if (!fromCache) m_cache->saveWeather(m_cityName, data);
    m_loading = false;
    emit loadingChanged();
    emit weatherChanged();
}

void WeatherController::onTripGoReceived(const QVariantList &items)
{
    m_tripGoResults = items;
    m_tripGoLoading = false;
    emit tripGoChanged();
}

void WeatherController::onBriefReceived(const QVariantList &items)
{
    emit briefWeatherReceived(items);
}

void WeatherController::onMapImageReceived(const QByteArray &pngData)
{
    const QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    QDir().mkpath(cacheDir);
    const QString filePath = cacheDir + QStringLiteral("/weather_map.png");

    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly)) {
        qWarning() << "[map] cannot write cache file:" << filePath;
        onMapImageFailed();
        return;
    }
    file.write(pngData);
    file.close();

    m_mapImageSource = QUrl::fromLocalFile(filePath).toString()
            + QStringLiteral("?t=") + QString::number(QDateTime::currentMSecsSinceEpoch());
    m_mapLoading = false;
    qDebug() << "[map] saved to" << m_mapImageSource;
    emit mapImageSourceChanged();
    emit mapLoadingChanged();
}

void WeatherController::onMapImageFailed()
{
    qWarning() << "[map] load failed";
    m_mapImageSource.clear();
    m_mapLoading = false;
    emit mapImageSourceChanged();
    emit mapLoadingChanged();
}

void WeatherController::onError(const QString &message)
{
    m_errorMessage = message;
    m_loading = false;
    m_tripGoLoading = false;
    emit loadingChanged();
    emit tripGoChanged();
    emit errorChanged();
}

void WeatherController::parseWeatherData(const QJsonObject &data)
{
    QJsonObject city = data.value("city").toObject();
    m_cityName = city.value("name").toString();
    m_cityId = city.value("id").toString();
    m_latitude = city.value("lat").toDouble();
    m_longitude = city.value("lon").toDouble();
    m_mapZoom = 11;

    QJsonObject now = data.value("now").toObject();
    m_temperature = now.value("temp").toString();
    m_weatherText = now.value("text").toString();
    m_iconCode = now.value("icon").toString();
    m_windInfo = now.value("windDir").toString() + " " + now.value("windScale").toString()
                 + QString::fromUtf8("\xe7\xba\xa7");
    m_humidity = now.value("humidity").toString();

    m_animationType = data.value("animationType").toString();
    if (m_animationType.isEmpty()) m_animationType = mapIconToAnimation(m_iconCode);

    QJsonObject air = data.value("air").toObject();
    m_aqi = air.value("aqi").toString();
    m_aqiCategory = air.value("category").toString();
    m_aqiLevel = air.value("level").toString();
    m_aqiColor = getAqiColor(m_aqi);

    m_hourlyForecast.clear();
    for (const QJsonValue &val : data.value("hourly").toArray()) {
        QJsonObject hour = val.toObject();
        QVariantMap item;
        item["fxTime"] = hour.value("fxTime").toString();
        item["temp"] = hour.value("temp").toString().toDouble();
        item["text"] = hour.value("text").toString();
        item["icon"] = hour.value("icon").toString();
        item["windSpeed"] = hour.value("windSpeed").toString().toDouble();
        item["humidity"] = hour.value("humidity").toString().toDouble();
        item["pop"] = hour.value("pop").toString().toDouble();
        item["precip"] = hour.value("precip").toString().toDouble();
        m_hourlyForecast.append(item);
    }

    m_dailyForecast.clear();
    m_aqiDaily.clear();
    for (const QJsonValue &val : data.value("daily").toArray()) {
        QJsonObject day = val.toObject();
        QVariantMap item;
        item["date"] = day.value("fxDate").toString();
        item["tempMax"] = day.value("tempMax").toString().toDouble();
        item["tempMin"] = day.value("tempMin").toString().toDouble();
        item["textDay"] = day.value("textDay").toString();
        item["iconDay"] = day.value("iconDay").toString();
        item["humidity"] = day.value("humidity").toString();
        m_dailyForecast.append(item);
        QVariantMap aqiItem;
        aqiItem["date"] = day.value("fxDate").toString();
        aqiItem["humidity"] = day.value("humidity").toString().toDouble();
        m_aqiDaily.append(aqiItem);
    }
    updateSpeechText();
    requestMapImage();
}

void WeatherController::requestMapImage()
{
    if (qFuzzyIsNull(m_latitude) && qFuzzyIsNull(m_longitude)) {
        m_mapImageSource.clear();
        m_mapLoading = false;
        emit mapImageSourceChanged();
        emit mapLoadingChanged();
        return;
    }

    m_mapLoading = true;
    emit mapLoadingChanged();
    m_apiClient->fetchMapImage(m_longitude, m_latitude, m_mapZoom);
}

void WeatherController::updateSpeechText()
{
    if (m_cityName.isEmpty()) { m_speechText.clear(); return; }
    m_speechText = m_cityName + ", " + m_weatherText + ", " + m_temperature
                   + QString::fromUtf8("\xe5\xba\xa6, \xe6\xb9\xbf\xe5\xba\xa6") + m_humidity + "%";
    if (!m_aqi.isEmpty())
        m_speechText += ", AQI " + m_aqi;
}

void WeatherController::mapZoomIn()
{
    if (m_mapZoom >= 17)
        return;
    ++m_mapZoom;
    emit mapZoomChanged();
    requestMapImage();
}

void WeatherController::mapZoomOut()
{
    if (m_mapZoom <= 8)
        return;
    --m_mapZoom;
    emit mapZoomChanged();
    requestMapImage();
}

QString WeatherController::mapIconToAnimation(const QString &icon)
{
    bool ok; int code = icon.toInt(&ok);
    if (!ok) return "sunny";
    if (code >= 400 && code <= 499) return "snow";
    if (code >= 300 && code <= 399) return "rain";
    if (code >= 100 && code <= 103) return "sunny";
    return "cloudy";
}

QString WeatherController::getAqiColor(const QString &aqiStr)
{
    int aqi = aqiStr.toInt();
    if (aqi <= 50) return "#81C784";
    if (aqi <= 100) return "#FFD54F";
    if (aqi <= 150) return "#FFB74D";
    if (aqi <= 200) return "#E57373";
    if (aqi <= 300) return "#BA68C8";
    return "#9575A8";
}
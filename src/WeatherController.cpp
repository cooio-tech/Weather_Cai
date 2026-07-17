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
#include <QTextToSpeech>
#include <QLocale>

WeatherController::WeatherController(QObject *parent)
    : QObject(parent)
    , m_apiClient(new WeatherApiClient(this))
    , m_cache(new WeatherCache(this))
    , m_tts(new QTextToSpeech(this))
{
    m_tts->setLocale(QLocale(QLocale::Chinese, QLocale::China));

    connect(m_apiClient, &WeatherApiClient::weatherReceived,
            this, &WeatherController::onWeatherReceived);
    connect(m_apiClient, &WeatherApiClient::tripGoReceived,
            this, &WeatherController::onTripGoReceived);
    connect(m_apiClient, &WeatherApiClient::briefReceived,
            this, &WeatherController::onBriefReceived);
    connect(m_apiClient, &WeatherApiClient::citySearchReceived,
            this, &WeatherController::onCitySearchReceived);
    connect(m_apiClient, &WeatherApiClient::mapImageReceived,
            this, &WeatherController::onMapImageReceived);
    connect(m_apiClient, &WeatherApiClient::mapImageFailed,
            this, &WeatherController::OnMapImageFailed);
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
    m_citySuggestions.clear();
    emit suggestionsChanged();
    m_selectedDayIndex = -1;
    m_selectedHourIndex = -1;
    m_hoverDayIndex = -1;
    emit selectionChanged();

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

void WeatherController::suggestCities(const QString &keyword)
{
    const QString key = keyword.trimmed();
    if (key.isEmpty()) {
        m_citySuggestions.clear();
        emit suggestionsChanged();
        return;
    }
    m_apiClient->fetchCitySearch(key);
}

void WeatherController::clearSuggestions()
{
    if (m_citySuggestions.isEmpty()) {
        return;
    }
    m_citySuggestions.clear();
    emit suggestionsChanged();
}

void WeatherController::setSelectedDayIndex(int index)
{
    if (m_selectedDayIndex == index) {
        return;
    }
    m_selectedDayIndex = index;
    emit selectionChanged();
}

void WeatherController::setSelectedHourIndex(int index)
{
    if (m_selectedHourIndex == index) {
        return;
    }
    m_selectedHourIndex = index;
    emit selectionChanged();
}

void WeatherController::setHoverDayIndex(int index)
{
    if (m_hoverDayIndex == index) {
        return;
    }
    m_hoverDayIndex = index;
    emit selectionChanged();
}

void WeatherController::onCitySearchReceived(const QVariantList &items)
{
    m_citySuggestions = items;
    emit suggestionsChanged();
}

void WeatherController::refreshWeather()
{
    if (m_cityName.trimmed().isEmpty())
        return;
    m_loading = true;
    emit loadingChanged();
    m_errorMessage.clear();
    emit errorChanged();
    m_apiClient->fetchWeather(m_cityName);
}

void WeatherController::speakWeather(bool enabled)
{
    if (!m_tts) {
        return;
    }
    if (!enabled) {
        m_tts->stop();
        return;
    }
    UpdateSpeechText();
    if (m_speechText.isEmpty()) {
        return;
    }
    m_tts->stop();
    m_tts->say(m_speechText);
    qDebug() << "[speech]" << m_speechText;
}

void WeatherController::stopSpeaking()
{
    if (m_tts) {
        m_tts->stop();
    }
}

void WeatherController::clearLocalCache() { m_cache->clearAll(); }
void WeatherController::clearAllCache() { m_cache->clearAll(); m_apiClient->clearServerCache(); }

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
    if (!fromCache) {
        m_cache->saveWeather(m_cityName, data);
    }
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
        OnMapImageFailed();
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

void WeatherController::OnMapImageFailed()
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

    m_aqiHourly.clear();
    for (const QJsonValue &val : data.value("airHourly").toArray()) {
        QJsonObject hour = val.toObject();
        QVariantMap item;
        item["fxTime"] = hour.value("fxTime").toString();
        item["aqi"] = hour.value("aqi").toString();
        item["level"] = hour.value("level").toString();
        item["category"] = hour.value("category").toString();
        item["color"] = hour.value("color").toString();
        m_aqiHourly.append(item);
    }

    QJsonObject uv = data.value("uv").toObject();
    m_uvLevel = uv.value("level").toString();
    m_uvCategory = uv.value("category").toString();
    m_uvName = uv.value("name").toString();
    m_uvText = uv.value("text").toString();

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
    m_uvDaily.clear();
    for (const QJsonValue &val : data.value("daily").toArray()) {
        QJsonObject day = val.toObject();
        QVariantMap item;
        item["date"] = day.value("fxDate").toString();
        item["tempMax"] = day.value("tempMax").toString().toDouble();
        item["tempMin"] = day.value("tempMin").toString().toDouble();
        item["textDay"] = day.value("textDay").toString();
        item["iconDay"] = day.value("iconDay").toString();
        item["humidity"] = day.value("humidity").toString();
        item["uvIndex"] = day.value("uvIndex").toString();
        m_dailyForecast.append(item);
        QVariantMap aqiItem;
        aqiItem["date"] = day.value("fxDate").toString();
        aqiItem["humidity"] = day.value("humidity").toString().toDouble();
        m_aqiDaily.append(aqiItem);
        QVariantMap uvItem;
        uvItem["date"] = day.value("fxDate").toString();
        uvItem["uvIndex"] = day.value("uvIndex").toString();
        m_uvDaily.append(uvItem);
    }
    UpdateSpeechText();
    RequestMapImage();
}

void WeatherController::RequestMapImage()
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

void WeatherController::UpdateSpeechText()
{
    if (m_cityName.isEmpty()) {
        m_speechText.clear();
        return;
    }

    QString highLow;
    int tMax = 0;
    int tMin = 0;
    if (!m_dailyForecast.isEmpty()) {
        const QVariantMap day = m_dailyForecast.first().toMap();
        tMax = qRound(day.value(QStringLiteral("tempMax")).toDouble());
        tMin = qRound(day.value(QStringLiteral("tempMin")).toDouble());
        highLow = QString::fromUtf8("\xe4\xbb\x8a\xe6\x97\xa5\xe6\xb0\x94\xe6\xb8\xa9")
                + QString::number(tMin)
                + QString::fromUtf8("\xe5\x88\xb0")
                + QString::number(tMax)
                + QString::fromUtf8("\xe5\xba\xa6\xe3\x80\x82");
    }

    m_speechText = m_cityName
            + QString::fromUtf8("\xe3\x80\x82\xe5\xbd\x93\xe5\x89\x8d")
            + m_weatherText
            + QString::fromUtf8("\xef\xbc\x8c\xe6\xb0\x94\xe6\xb8\xa9")
            + m_temperature
            + QString::fromUtf8("\xe5\xba\xa6\xe3\x80\x82")
            + highLow
            + travelAdvice();
}

QString WeatherController::travelAdvice() const
{
    int tMax = 0;
    int tMin = 0;
    if (!m_dailyForecast.isEmpty()) {
        const QVariantMap day = m_dailyForecast.first().toMap();
        tMax = qRound(day.value(QStringLiteral("tempMax")).toDouble());
        tMin = qRound(day.value(QStringLiteral("tempMin")).toDouble());
    }

    if (m_animationType == QLatin1String("rain")) {
        return QString::fromUtf8("\xe5\xa4\x96\xe5\x87\xba\xe8\xae\xb0\xe5\xbe\x97\xe5\xb8\xa6\xe4\xbc\x9e\xe3\x80\x82");
    }
    if (m_animationType == QLatin1String("snow")) {
        return QString::fromUtf8("\xe8\xb7\xaf\xe9\x9d\xa2\xe5\x8f\xaf\xe8\x83\xbd\xe6\xbb\x91\xef\xbc\x8c\xe5\x87\xba\xe8\xa1\x8c\xe8\xaf\xb7\xe6\xb3\xa8\xe6\x84\x8f\xe5\xae\x89\xe5\x85\xa8\xe3\x80\x82");
    }
    if (tMax >= 33) {
        return QString::fromUtf8("\xe5\xa4\xa9\xe6\xb0\x94\xe8\xbe\x83\xe7\x83\xad\xef\xbc\x8c\xe6\xb3\xa8\xe6\x84\x8f\xe9\x98\xb2\xe6\x9a\x91\xe8\xa1\xa5\xe6\xb0\xb4\xe3\x80\x82");
    }
    if (tMin > 0 && tMin <= 8) {
        return QString::fromUtf8("\xe6\xb8\xa9\xe5\xb7\xae\xe8\xbe\x83\xe5\xa4\xa7\xef\xbc\x8c\xe5\x87\xba\xe8\xa1\x8c\xe8\xae\xb0\xe5\xbe\x97\xe6\xb7\xbb\xe8\xa1\xa3\xe3\x80\x82");
    }
    if (m_animationType == QLatin1String("sunny")) {
        return QString::fromUtf8("\xe9\x80\x82\xe5\x90\x88\xe7\x9f\xad\xe9\x80\x94\xe5\x87\xba\xe8\xa1\x8c\xef\xbc\x8c\xe8\xae\xb0\xe5\xbe\x97\xe9\x98\xb2\xe6\x99\x92\xe3\x80\x82");
    }
    return QString::fromUtf8("\xe5\x87\xba\xe8\xa1\x8c\xe8\xaf\xb7\xe5\x85\xb3\xe6\xb3\xa8\xe5\xa4\xa9\xe6\xb0\x94\xe5\x8f\x98\xe5\x8c\x96\xe3\x80\x82");
}

void WeatherController::mapZoomIn()
{
    if (m_mapZoom >= 17) {
        return;
    }
    ++m_mapZoom;
    emit mapZoomChanged();
    RequestMapImage();
}

void WeatherController::mapZoomOut()
{
    if (m_mapZoom <= 8) {
        return;
    }
    --m_mapZoom;
    emit mapZoomChanged();
    RequestMapImage();
}

QString WeatherController::mapIconToAnimation(const QString &icon)
{
    bool ok;
    int code = icon.toInt(&ok);
    if (!ok) {
        return "sunny";
    }
    // 和风图标：100/150 晴；101–104/151–154 多云或阴
    if (code >= 400 && code <= 499) {
        return "snow";
    }
    if (code >= 300 && code <= 399) {
        return "rain";
    }
    if (code == 100 || code == 150) {
        return "sunny";
    }
    if ((code >= 101 && code <= 104) || (code >= 151 && code <= 154)) {
        return "cloudy";
    }
    return "cloudy";
}

QString WeatherController::getAqiColor(const QString &aqiStr)
{
    bool ok = false;
    double aqi = aqiStr.toDouble(&ok);
    if (!ok) {
        aqi = 0;
    }
    if (aqi <= 50) {
        return "#81C784";
    }
    if (aqi <= 100) {
        return "#FFD54F";
    }
    if (aqi <= 150) {
        return "#FFB74D";
    }
    if (aqi <= 200) {
        return "#E57373";
    }
    if (aqi <= 300) {
        return "#BA68C8";
    }
    return "#9575A8";
}

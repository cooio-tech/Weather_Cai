#include "WeatherApiClient.h"

#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrlQuery>
#include <QUrl>
#include <QVariantMap>
#include <QDebug>

WeatherApiClient::WeatherApiClient(QObject *parent)
    : QObject(parent)
    , m_manager(new QNetworkAccessManager(this))
    , m_baseUrl("http://127.0.0.1:8080")
{
}

void WeatherApiClient::fetchWeather(const QString &city)
{
    QUrl url(m_baseUrl + "/api/weather/now");
    QUrlQuery query;
    query.addQueryItem("city", city);
    url.setQuery(query);

    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QNetworkReply *reply = m_manager->get(request);
    reply->setProperty("requestType", "weather");
    connect(reply, &QNetworkReply::finished, this, &WeatherApiClient::onReplyFinished);
}

void WeatherApiClient::fetchBrief(const QStringList &cities)
{
    if (cities.isEmpty()) {
        emit briefReceived({});
        return;
    }

    QUrl url(m_baseUrl + "/api/weather/brief");
    QUrlQuery query;
    query.addQueryItem("cities", cities.join(","));
    url.setQuery(query);

    QNetworkRequest request(url);
    QNetworkReply *reply = m_manager->get(request);
    reply->setProperty("requestType", "brief");
    connect(reply, &QNetworkReply::finished, this, &WeatherApiClient::onReplyFinished);
}

void WeatherApiClient::fetchTripGo(int days, double lat, double lon, const QString &fromCity)
{
    QUrl url(m_baseUrl + "/api/tripgo/recommend");
    QUrlQuery query;
    query.addQueryItem("days", QString::number(days));
    if (!qFuzzyIsNull(lat) || !qFuzzyIsNull(lon)) {
        query.addQueryItem("lat", QString::number(lat, 'f', 6));
        query.addQueryItem("lon", QString::number(lon, 'f', 6));
    }
    if (!fromCity.trimmed().isEmpty())
        query.addQueryItem("fromCity", fromCity.trimmed());
    url.setQuery(query);

    QNetworkRequest request(url);
    QNetworkReply *reply = m_manager->get(request);
    reply->setProperty("requestType", "tripgo");
    connect(reply, &QNetworkReply::finished, this, &WeatherApiClient::onReplyFinished);
}

void WeatherApiClient::fetchMapImage(double lon, double lat, int zoom)
{
    QUrl url(m_baseUrl + "/api/map/static");
    QUrlQuery query;
    query.addQueryItem("lon", QString::number(lon, 'f', 6));
    query.addQueryItem("lat", QString::number(lat, 'f', 6));
    query.addQueryItem("zoom", QString::number(zoom));
    query.addQueryItem("width", QStringLiteral("220"));
    query.addQueryItem("height", QStringLiteral("180"));
    url.setQuery(query);

    qDebug() << "[map] fetch" << url.toString();

    QNetworkRequest request(url);
    QNetworkReply *reply = m_manager->get(request);
    reply->setProperty("requestType", "map");
    connect(reply, &QNetworkReply::finished, this, &WeatherApiClient::onReplyFinished);
}

void WeatherApiClient::onReplyFinished()
{
    auto *reply = qobject_cast<QNetworkReply *>(sender());
    if (!reply) return;

    const QString type = reply->property("requestType").toString();

    if (reply->error() != QNetworkReply::NoError) {
        if (type == "map") {
            qWarning() << "[map] network error:" << reply->errorString();
            emit mapImageFailed();
        } else {
            emit errorOccurred(QString::fromUtf8("\xe7\xbd\x91\xe7\xbb\x9c\xe8\xaf\xb7\xe6\xb1\x82\xe5\xa4\xb1\xe8\xb4\xa5: %1").arg(reply->errorString()));
        }
        reply->deleteLater();
        return;
    }

    if (type == "brief") {
        handleBriefReply(reply);
    } else if (type == "tripgo") {
        handleTripGoReply(reply);
    } else if (type == "map") {
        handleMapReply(reply);
    } else {
        handleWeatherReply(reply);
    }
    reply->deleteLater();
}

void WeatherApiClient::handleWeatherReply(QNetworkReply *reply)
{
    QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
    QJsonObject root = doc.object();

    if (root.value("code").toInt() != 200) {
        emit errorOccurred(root.value("message").toString(
            QString::fromUtf8("\xe8\x8e\xb7\xe5\x8f\x96\xe5\xa4\xa9\xe6\xb0\x94\xe6\x95\xb0\xe6\x8d\xae\xe5\xa4\xb1\xe8\xb4\xa5")));
        return;
    }

    QJsonObject data = root.value("data").toObject();
    bool fromCache = data.value("fromCache").toBool(false);
    emit weatherReceived(data, fromCache);
}

void WeatherApiClient::handleBriefReply(QNetworkReply *reply)
{
    QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
    QJsonObject root = doc.object();
    QVariantList items;
    if (root.value("code").toInt() == 200) {
        for (const QJsonValue &val : root.value("data").toArray()) {
            QJsonObject o = val.toObject();
            QVariantMap m;
            m["cityId"] = o.value("cityId").toString();
            m["cityName"] = o.value("cityName").toString();
            m["temp"] = o.value("temp").toString();
            m["weatherText"] = o.value("weatherText").toString();
            m["aqi"] = o.value("aqi").toString();
            m["aqiCategory"] = o.value("aqiCategory").toString();
            items.append(m);
        }
    }
    emit briefReceived(items);
}

void WeatherApiClient::handleTripGoReply(QNetworkReply *reply)
{
    QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
    QJsonObject root = doc.object();
    QVariantList items;
    if (root.value("code").toInt() == 200) {
        for (const QJsonValue &val : root.value("data").toArray()) {
            QJsonObject o = val.toObject();
            QVariantMap m;
            m["cityId"] = o.value("cityId").toString();
            m["cityName"] = o.value("cityName").toString();
            m["score"] = o.value("score").toInt();
            m["recommended"] = o.value("recommended").toBool();
            m["summary"] = o.value("summary").toString();
            m["reason"] = o.value("reason").toString();
            m["distanceKm"] = o.value("distanceKm").toDouble(-1);
            m["distanceBand"] = o.value("distanceBand").toString();
            m["bestDays"] = o.value("bestDays").toString();
            QStringList acts;
            for (const QJsonValue &a : o.value("activities").toArray())
                acts.append(a.toString());
            m["activities"] = acts.join(QString::fromUtf8("\u3001"));
            items.append(m);
        }
    }
    emit tripGoReceived(items);
}

void WeatherApiClient::handleMapReply(QNetworkReply *reply)
{
    const QByteArray body = reply->readAll();
    const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    qDebug() << "[map] response status=" << status << "bytes=" << body.size();

    if (body.size() < 8 || static_cast<unsigned char>(body.at(0)) != 0x89) {
        qWarning() << "[map] not a PNG, head=" << body.left(120);
        emit mapImageFailed();
        return;
    }
    emit mapImageReceived(body);
}

void WeatherApiClient::clearServerCache()
{
    QUrl url(m_baseUrl + "/api/weather/cache");
    QNetworkRequest request(url);
    m_manager->deleteResource(request);
}
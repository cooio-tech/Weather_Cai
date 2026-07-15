#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QJsonObject>
#include <QVariantList>

class WeatherApiClient : public QObject
{
    Q_OBJECT

public:
    explicit WeatherApiClient(QObject *parent = nullptr);

    void clearServerCache();
    void fetchWeather(const QString &city);
    void fetchCitySearch(const QString &city);
    void fetchBrief(const QStringList &cities);
    void fetchTripGo(int days, double lat, double lon, const QString &fromCity);
    void fetchMapImage(double lon, double lat, int zoom);
    void setBaseUrl(const QString &url) { m_baseUrl = url; }
    QString baseUrl() const { return m_baseUrl; }

signals:
    void weatherReceived(const QJsonObject &data, bool fromCache);
    void citySearchReceived(const QVariantList &items);
    void briefReceived(const QVariantList &items);
    void tripGoReceived(const QVariantList &items);
    void mapImageReceived(const QByteArray &pngData);
    void mapImageFailed();
    void errorOccurred(const QString &message);

private slots:
    void onReplyFinished();

private:
    void handleWeatherReply(class QNetworkReply *reply);
    void handleCitySearchReply(class QNetworkReply *reply);
    void handleBriefReply(class QNetworkReply *reply);
    void handleTripGoReply(class QNetworkReply *reply);
    void handleMapReply(class QNetworkReply *reply);

    QNetworkAccessManager *m_manager;
    QString m_baseUrl;
};
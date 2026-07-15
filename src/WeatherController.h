#pragma once

#include <QObject>
#include <QJsonObject>
#include <QJsonArray>
#include <QVariantList>

class WeatherApiClient;
class WeatherCache;
class QTextToSpeech;

class WeatherController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString cityName READ cityName NOTIFY weatherChanged)
    Q_PROPERTY(QString cityId READ cityId NOTIFY weatherChanged)
    Q_PROPERTY(QString temperature READ temperature NOTIFY weatherChanged)
    Q_PROPERTY(QString weatherText READ weatherText NOTIFY weatherChanged)
    Q_PROPERTY(QString windInfo READ windInfo NOTIFY weatherChanged)
    Q_PROPERTY(QString humidity READ humidity NOTIFY weatherChanged)
    Q_PROPERTY(QString animationType READ animationType NOTIFY weatherChanged)
    Q_PROPERTY(QString iconCode READ iconCode NOTIFY weatherChanged)
    Q_PROPERTY(QString aqi READ aqi NOTIFY weatherChanged)
    Q_PROPERTY(QString aqiCategory READ aqiCategory NOTIFY weatherChanged)
    Q_PROPERTY(QString aqiColor READ aqiColor NOTIFY weatherChanged)
    Q_PROPERTY(QString aqiLevel READ aqiLevel NOTIFY weatherChanged)
    Q_PROPERTY(QVariantList aqiHourly READ aqiHourly NOTIFY weatherChanged)
    Q_PROPERTY(QString uvLevel READ uvLevel NOTIFY weatherChanged)
    Q_PROPERTY(QString uvCategory READ uvCategory NOTIFY weatherChanged)
    Q_PROPERTY(QString uvName READ uvName NOTIFY weatherChanged)
    Q_PROPERTY(QString uvText READ uvText NOTIFY weatherChanged)
    Q_PROPERTY(QVariantList uvDaily READ uvDaily NOTIFY weatherChanged)
    Q_PROPERTY(double latitude READ latitude NOTIFY weatherChanged)
    Q_PROPERTY(double longitude READ longitude NOTIFY weatherChanged)
    Q_PROPERTY(int mapZoom READ mapZoom NOTIFY mapZoomChanged)
    Q_PROPERTY(QString mapImageSource READ mapImageSource NOTIFY mapImageSourceChanged)
    Q_PROPERTY(bool mapLoading READ mapLoading NOTIFY mapLoadingChanged)
    Q_PROPERTY(QVariantList dailyForecast READ dailyForecast NOTIFY weatherChanged)
    Q_PROPERTY(QVariantList hourlyForecast READ hourlyForecast NOTIFY weatherChanged)
    Q_PROPERTY(QVariantList aqiDaily READ aqiDaily NOTIFY weatherChanged)
    Q_PROPERTY(QVariantList tripGoResults READ tripGoResults NOTIFY tripGoChanged)
    Q_PROPERTY(bool tripGoLoading READ tripGoLoading NOTIFY tripGoChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY weatherChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorChanged)
    Q_PROPERTY(bool fromCache READ fromCache NOTIFY weatherChanged)
    Q_PROPERTY(QString speechText READ speechText NOTIFY weatherChanged)
    Q_PROPERTY(QVariantList citySuggestions READ citySuggestions NOTIFY suggestionsChanged)
    Q_PROPERTY(int selectedDayIndex READ selectedDayIndex WRITE setSelectedDayIndex NOTIFY selectionChanged)
    Q_PROPERTY(int selectedHourIndex READ selectedHourIndex WRITE setSelectedHourIndex NOTIFY selectionChanged)
    Q_PROPERTY(int hoverDayIndex READ hoverDayIndex WRITE setHoverDayIndex NOTIFY selectionChanged)

public:
    explicit WeatherController(QObject *parent = nullptr);
    ~WeatherController() override;

    QString cityName() const { return m_cityName; }
    QString cityId() const { return m_cityId; }
    QString temperature() const { return m_temperature; }
    QString weatherText() const { return m_weatherText; }
    QString windInfo() const { return m_windInfo; }
    QString humidity() const { return m_humidity; }
    QString animationType() const { return m_animationType; }
    QString iconCode() const { return m_iconCode; }
    QString aqi() const { return m_aqi; }
    QString aqiCategory() const { return m_aqiCategory; }
    QString aqiColor() const { return m_aqiColor; }
    QString aqiLevel() const { return m_aqiLevel; }
    QVariantList aqiHourly() const { return m_aqiHourly; }
    QString uvLevel() const { return m_uvLevel; }
    QString uvCategory() const { return m_uvCategory; }
    QString uvName() const { return m_uvName; }
    QString uvText() const { return m_uvText; }
    QVariantList uvDaily() const { return m_uvDaily; }
    double latitude() const { return m_latitude; }
    double longitude() const { return m_longitude; }
    int mapZoom() const { return m_mapZoom; }
    QString mapImageSource() const { return m_mapImageSource; }
    bool mapLoading() const { return m_mapLoading; }
    QVariantList dailyForecast() const { return m_dailyForecast; }
    QVariantList hourlyForecast() const { return m_hourlyForecast; }
    QVariantList aqiDaily() const { return m_aqiDaily; }
    QVariantList tripGoResults() const { return m_tripGoResults; }
    bool tripGoLoading() const { return m_tripGoLoading; }
    bool loading() const { return m_loading; }
    QString errorMessage() const { return m_errorMessage; }
    bool fromCache() const { return m_fromCache; }
    QString speechText() const { return m_speechText; }
    QVariantList citySuggestions() const { return m_citySuggestions; }
    int selectedDayIndex() const { return m_selectedDayIndex; }
    int selectedHourIndex() const { return m_selectedHourIndex; }
    int hoverDayIndex() const { return m_hoverDayIndex; }

    WeatherApiClient *apiClient() const { return m_apiClient; }

    Q_INVOKABLE void searchCity(const QString &city);
    Q_INVOKABLE void refreshWeather();
    Q_INVOKABLE void suggestCities(const QString &keyword);
    Q_INVOKABLE void clearSuggestions();
    Q_INVOKABLE void setSelectedDayIndex(int index);
    Q_INVOKABLE void setSelectedHourIndex(int index);
    Q_INVOKABLE void setHoverDayIndex(int index);
    Q_INVOKABLE void clearLocalCache();
    Q_INVOKABLE void clearAllCache();
    Q_INVOKABLE void speakWeather(bool enabled);
    Q_INVOKABLE void stopSpeaking();
    Q_INVOKABLE void fetchTripGo(int days);
    Q_INVOKABLE void fetchBriefWeather(const QStringList &cities);
    Q_INVOKABLE void mapZoomIn();
    Q_INVOKABLE void mapZoomOut();

signals:
    void weatherChanged();
    void mapZoomChanged();
    void mapImageSourceChanged();
    void mapLoadingChanged();
    void tripGoChanged();
    void briefWeatherReceived(const QVariantList &items);
    void loadingChanged();
    void errorChanged();
    void suggestionsChanged();
    void selectionChanged();

private slots:
    void onWeatherReceived(const QJsonObject &data, bool fromCache);
    void onTripGoReceived(const QVariantList &items);
    void onBriefReceived(const QVariantList &items);
    void onCitySearchReceived(const QVariantList &items);
    void onMapImageReceived(const QByteArray &pngData);
    void onMapImageFailed();
    void onError(const QString &message);

private:
    void parseWeatherData(const QJsonObject &data);
    void requestMapImage();
    void updateSpeechText();
    QString travelAdvice() const;
    static QString mapIconToAnimation(const QString &icon);
    static QString getAqiColor(const QString &aqi);

    WeatherApiClient *m_apiClient;
    WeatherCache *m_cache;
    QTextToSpeech *m_tts = nullptr;

    QString m_cityName;
    QString m_cityId;
    QString m_temperature;
    QString m_weatherText;
    QString m_windInfo;
    QString m_humidity;
    QString m_animationType;
    QString m_iconCode;
    QString m_aqi;
    QString m_aqiCategory;
    QString m_aqiColor;
    QString m_aqiLevel;
    QVariantList m_aqiHourly;
    QString m_uvLevel;
    QString m_uvCategory;
    QString m_uvName;
    QString m_uvText;
    QVariantList m_uvDaily;
    QString m_speechText;
    QString m_mapImageSource;
    double m_latitude = 0;
    double m_longitude = 0;
    int m_mapZoom = 11;
    bool m_mapLoading = false;
    QVariantList m_dailyForecast;
    QVariantList m_hourlyForecast;
    QVariantList m_aqiDaily;
    QVariantList m_tripGoResults;
    QVariantList m_citySuggestions;
    bool m_tripGoLoading = false;
    bool m_loading = false;
    QString m_errorMessage;
    bool m_fromCache = false;
    int m_selectedDayIndex = -1;
    int m_selectedHourIndex = -1;
    int m_hoverDayIndex = -1;
};
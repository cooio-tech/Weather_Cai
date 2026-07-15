package com.weather.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.weather.config.AppConfig.QWeatherProperties;
import com.weather.dto.CitySearchResult;
import com.weather.dto.WeatherResponse;
import com.weather.entity.CityEntity;
import com.weather.entity.SearchHistoryEntity;
import com.weather.entity.WeatherCacheEntity;
import com.weather.repository.CityRepository;
import com.weather.repository.SearchHistoryRepository;
import com.weather.repository.WeatherCacheRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class WeatherService {

    private final QWeatherClient qWeatherClient;
    private final CityRepository cityRepository;
    private final WeatherCacheRepository cacheRepository;
    private final SearchHistoryRepository historyRepository;
    private final QWeatherProperties props;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public List<CitySearchResult> searchCity(String keyword) {
        return qWeatherClient.searchCity(keyword);
    }

    public WeatherResponse getWeatherByCityName(String cityName) {
        List<CitySearchResult> cities = qWeatherClient.searchCity(cityName);
        CitySearchResult city = pickBestCity(cityName, cities);
        if (city == null && QWeatherClient.containsChinese(cityName)) {
            String mapped = ChineseCityAliases.mappedEnglish(cityName);
            String compact = ChinesePinyin.toCompact(ChineseCityAliases.normalize(cityName));
            if (mapped != null) {
                cities = qWeatherClient.searchCity(mapped);
                city = pickBestCity(mapped, cities);
            }
            if (city == null && compact != null) {
                cities = qWeatherClient.searchCity(compact);
                city = pickBestCity(compact, cities);
            }
        }
        if (city == null) {
            return null;
        }
        saveCity(city);
        saveSearchHistory(city);
        WeatherResponse response = getWeatherByCityId(city.getId());
        if (response != null && response.getCity() != null && QWeatherClient.containsChinese(cityName)) {
            String displayName = cityName.trim().replace("\u5e02", "");
            response.getCity().setName(displayName);
        }
        return response;
    }

    private CitySearchResult pickBestCity(String keyword, List<CitySearchResult> cities) {
        if (cities == null || cities.isEmpty()) {
            return null;
        }
        String key = normalizePlace(keyword);
        if (key.isEmpty()) {
            return cities.get(0);
        }
        boolean chineseKeyword = QWeatherClient.containsChinese(keyword);

        CitySearchResult best = null;
        int bestScore = Integer.MIN_VALUE;
        for (CitySearchResult city : cities) {
            int score = scoreCity(city, key, chineseKeyword);
            if (score > bestScore) {
                bestScore = score;
                best = city;
            }
        }
        if (best == null || bestScore <= 0) {
            return null;
        }
        // Chinese queries that only hit English Geo names used to score too low and get rejected.
        if (chineseKeyword && bestScore < 40) {
            if (isChina(best) && bestScore >= 20) {
                return best;
            }
            for (CitySearchResult city : cities) {
                if (isChina(city) && scoreCity(city, key, true) >= 20) {
                    return city;
                }
            }
            return null;
        }
        return best;
    }

    private int scoreCity(CitySearchResult city, String key, boolean chineseKeyword) {
        String name = normalizePlace(city.getName());
        String adm1 = normalizePlace(city.getAdm1());
        String adm2 = normalizePlace(city.getAdm2());
        int score = 0;

        if (name.equalsIgnoreCase(key) || adm1.equalsIgnoreCase(key) || adm2.equalsIgnoreCase(key)) {
            score = 100;
        } else if (containsIgnoreCase(name, key) || containsIgnoreCase(adm1, key) || containsIgnoreCase(adm2, key)) {
            score = 60;
        } else if ((!name.isEmpty() && containsIgnoreCase(key, name))
                || (!adm2.isEmpty() && containsIgnoreCase(key, adm2))) {
            score = 40;
        }

        if (chineseKeyword && isChina(city)) {
            score += 10;
        }

        // Match English / pinyin forms of the Chinese keyword against Geo English names
        String mapped = ChineseCityAliases.mappedEnglish(key);
        String compact = ChinesePinyin.toCompact(key);
        score = Math.max(score, scoreLatinForm(name, adm1, adm2, mapped));
        score = Math.max(score, scoreLatinForm(name, adm1, adm2, compact));
        if (mapped != null) {
            score = Math.max(score, scoreLatinForm(name, adm1, adm2, mapped.replace("'", "").replace(" ", "")));
        }
        return score;
    }

    private int scoreLatinForm(String name, String adm1, String adm2, String latin) {
        if (latin == null || latin.isBlank()) {
            return 0;
        }
        String form = latin.trim();
        String compact = form.replace("'", "").replace(" ", "");
        if (name.equalsIgnoreCase(form) || name.equalsIgnoreCase(compact)
                || adm1.equalsIgnoreCase(form) || adm1.equalsIgnoreCase(compact)
                || adm2.equalsIgnoreCase(form) || adm2.equalsIgnoreCase(compact)) {
            return 100;
        }
        if (containsIgnoreCase(name, compact) || containsIgnoreCase(adm2, compact)
                || containsIgnoreCase(name, form) || containsIgnoreCase(adm2, form)) {
            return 60;
        }
        return 0;
    }

    private String normalizePlace(String value) {
        if (value == null) {
            return "";
        }
        return value.trim()
                .replace("\u5e02", "")
                .replace("\u7701", "")
                .replace("\u81ea\u6cbb\u533a", "")
                .replace("\u7279\u522b\u884c\u653f\u533a", "");
    }

    private boolean isChina(CitySearchResult city) {
        String country = city.getCountry();
        return "\u4e2d\u56fd".equals(country) || "China".equalsIgnoreCase(country);
    }

    private boolean containsIgnoreCase(String value, String key) {
        return value != null && !key.isEmpty()
                && value.toLowerCase(Locale.ROOT).contains(key.toLowerCase(Locale.ROOT));
    }

    public WeatherResponse getWeatherByCityId(String cityId) {
        Optional<WeatherCacheEntity> cachedNow = getValidCache(cityId, "full");
        if (cachedNow.isPresent()) {
            try {
                WeatherResponse response = objectMapper.readValue(cachedNow.get().getJsonData(), WeatherResponse.class);
                response.setFromCache(true);
                return response;
            } catch (Exception e) {
                log.warn("Cache deserialize failed", e);
            }
        }

        CityEntity cityEntity = cityRepository.findByCityId(cityId).orElse(null);
        CitySearchResult cityInfo = null;
        if (cityEntity != null) {
            cityInfo = CitySearchResult.builder()
                    .id(cityEntity.getCityId())
                    .name(cityEntity.getName())
                    .adm1(cityEntity.getAdm1())
                    .adm2(cityEntity.getAdm2())
                    .country(cityEntity.getCountry())
                    .lat(cityEntity.getLat() != null ? cityEntity.getLat() : 0)
                    .lon(cityEntity.getLon() != null ? cityEntity.getLon() : 0)
                    .build();
        } else {
            List<CitySearchResult> results = qWeatherClient.searchCity(cityId);
            if (!results.isEmpty()) {
                cityInfo = results.get(0);
                saveCity(cityInfo);
            }
        }

        if (cityInfo == null) {
            return null;
        }

        String lang = QWeatherClient.resolveLang(cityInfo.getCountry());
        JsonNode nowNode = qWeatherClient.getNowWeather(cityId, lang);
        JsonNode hourlyNode = qWeatherClient.getHourlyForecast(cityId, lang);
        JsonNode dailyNode = qWeatherClient.getDailyForecast(cityId, lang);
        JsonNode airNode = qWeatherClient.getAirQuality(cityInfo.getLat(), cityInfo.getLon());
        JsonNode airHourlyNode = qWeatherClient.getAirHourly(cityInfo.getLat(), cityInfo.getLon());
        JsonNode indicesNode = qWeatherClient.getIndices(cityId, "1d", "5", lang);

        WeatherResponse response = buildResponse(
                cityInfo, nowNode, hourlyNode, dailyNode, airNode, airHourlyNode, indicesNode);
        response.setFromCache(false);
        saveCache(cityId, "full", response);
        return response;
    }



    /** TripGo: reuse full cache when present; otherwise only fetch 7-day daily. */
    public WeatherResponse getDailyForTrip(String cityId, String displayName, double lat, double lon) {
        if (cityId == null || cityId.isBlank()) {
            return null;
        }
        Optional<WeatherCacheEntity> full = getValidCache(cityId, "full");
        if (full.isPresent()) {
            try {
                WeatherResponse response = objectMapper.readValue(full.get().getJsonData(), WeatherResponse.class);
                response.setFromCache(true);
                if (response.getCity() != null && displayName != null && !displayName.isBlank()) {
                    response.getCity().setName(displayName);
                }
                return response;
            } catch (Exception e) {
                log.warn("Full cache deserialize failed for trip", e);
            }
        }

        Optional<WeatherCacheEntity> tripCache = getValidCache(cityId, "trip-daily");
        if (tripCache.isPresent()) {
            try {
                WeatherResponse response = objectMapper.readValue(tripCache.get().getJsonData(), WeatherResponse.class);
                response.setFromCache(true);
                return response;
            } catch (Exception e) {
                log.warn("Trip-daily cache deserialize failed", e);
            }
        }

        CitySearchResult cityInfo = CitySearchResult.builder()
                .id(cityId)
                .name(displayName != null ? displayName : cityId)
                .adm1("")
                .adm2("")
                .country("中国")
                .lat(lat)
                .lon(lon)
                .build();

        CityEntity existing = cityRepository.findByCityId(cityId).orElse(null);
        if (existing != null) {
            cityInfo = CitySearchResult.builder()
                    .id(existing.getCityId())
                    .name(displayName != null && !displayName.isBlank() ? displayName : existing.getName())
                    .adm1(existing.getAdm1())
                    .adm2(existing.getAdm2())
                    .country(existing.getCountry())
                    .lat(existing.getLat() != null ? existing.getLat() : lat)
                    .lon(existing.getLon() != null ? existing.getLon() : lon)
                    .build();
        }

        String lang = QWeatherClient.resolveLang(cityInfo.getCountry());
        JsonNode dailyNode = qWeatherClient.getDailyForecast(cityId, lang);
        if (dailyNode == null) {
            return null;
        }
        WeatherResponse response = buildResponse(cityInfo, null, null, dailyNode, null, null, null);
        response.setFromCache(false);
        saveCache(cityId, "trip-daily", response);
        return response;
    }
    public List<com.weather.dto.CityBriefWeather> getBriefWeatherList(List<String> cityNames) {
        List<com.weather.dto.CityBriefWeather> list = new ArrayList<>();
        if (cityNames == null) {
            return list;
        }
        for (String name : cityNames) {
            if (name == null || name.isBlank()) {
                continue;
            }
            WeatherResponse w = getWeatherByCityName(name.trim());
            if (w == null || w.getCity() == null) {
                continue;
            }
            String temp = w.getNow() != null ? w.getNow().getTemp() : "--";
            String text = w.getNow() != null ? w.getNow().getText() : "";
            String aqi = w.getAir() != null ? w.getAir().getAqi() : "";
            String cat = w.getAir() != null ? w.getAir().getCategory() : "";
            list.add(com.weather.dto.CityBriefWeather.builder()
                    .cityId(w.getCity().getId())
                    .cityName(w.getCity().getName())
                    .temp(temp)
                    .weatherText(text)
                    .aqi(aqi)
                    .aqiCategory(cat)
                    .build());
        }
        return list;
    }    public void clearServerCache() {
        cacheRepository.deleteAll();
    }

    private Optional<WeatherCacheEntity> getValidCache(String cityId, String type) {
        return cacheRepository.findByCityIdAndCacheType(cityId, type)
                .filter(c -> c.getExpiresAt().isAfter(LocalDateTime.now()));
    }

    private void saveCache(String cityId, String type, WeatherResponse data) {
        try {
            String json = objectMapper.writeValueAsString(data);
            WeatherCacheEntity entity = cacheRepository.findByCityIdAndCacheType(cityId, type)
                    .orElse(new WeatherCacheEntity());
            entity.setCityId(cityId);
            entity.setCacheType(type);
            entity.setJsonData(json);
            entity.setExpiresAt(LocalDateTime.now().plusMinutes(props.cacheTtlMinutes()));
            cacheRepository.save(entity);
        } catch (Exception e) {
            log.error("Save cache failed", e);
        }
    }

    private void saveCity(CitySearchResult city) {
        CityEntity entity = cityRepository.findByCityId(city.getId()).orElse(new CityEntity());
        entity.setCityId(city.getId());
        entity.setName(city.getName());
        entity.setAdm1(city.getAdm1());
        entity.setAdm2(city.getAdm2());
        entity.setCountry(city.getCountry());
        entity.setLat(city.getLat());
        entity.setLon(city.getLon());
        cityRepository.save(entity);
    }

    private void saveSearchHistory(CitySearchResult city) {
        SearchHistoryEntity history = new SearchHistoryEntity();
        history.setCityName(city.getName());
        history.setCityId(city.getId());
        historyRepository.save(history);
    }

    private WeatherResponse buildResponse(CitySearchResult city, JsonNode nowNode, JsonNode hourlyNode,
                                          JsonNode dailyNode, JsonNode airNode,
                                          JsonNode airHourlyNode, JsonNode indicesNode) {
        WeatherResponse.WeatherResponseBuilder builder = WeatherResponse.builder()
                .city(WeatherResponse.CityInfo.builder()
                        .id(city.getId())
                        .name(city.getName())
                        .adm1(city.getAdm1())
                        .adm2(city.getAdm2())
                        .country(city.getCountry())
                        .lat(city.getLat())
                        .lon(city.getLon())
                        .build());

        String iconCode = "100";
        if (nowNode != null) {
            JsonNode now = nowNode.path("now");
            iconCode = now.path("icon").asText("100");
            builder.now(WeatherResponse.NowWeather.builder()
                    .obsTime(now.path("obsTime").asText())
                    .temp(now.path("temp").asText())
                    .feelsLike(now.path("feelsLike").asText())
                    .text(now.path("text").asText())
                    .icon(iconCode)
                    .windDir(now.path("windDir").asText())
                    .windScale(now.path("windScale").asText())
                    .windSpeed(now.path("windSpeed").asText())
                    .humidity(now.path("humidity").asText())
                    .precip(now.path("precip").asText())
                    .pressure(now.path("pressure").asText())
                    .vis(now.path("vis").asText())
                    .build());
        }

        if (hourlyNode != null) {
            List<WeatherResponse.HourlyWeather> hourlyList = new ArrayList<>();
            for (JsonNode hour : hourlyNode.path("hourly")) {
                hourlyList.add(WeatherResponse.HourlyWeather.builder()
                        .fxTime(hour.path("fxTime").asText())
                        .temp(hour.path("temp").asText())
                        .icon(hour.path("icon").asText())
                        .text(hour.path("text").asText())
                        .windDir(hour.path("windDir").asText())
                        .windScale(hour.path("windScale").asText())
                        .windSpeed(hour.path("windSpeed").asText())
                        .humidity(hour.path("humidity").asText())
                        .pop(hour.path("pop").asText())
                        .precip(hour.path("precip").asText())
                        .build());
            }
            builder.hourly(hourlyList);
        }
        if (dailyNode != null) {
            List<WeatherResponse.DailyWeather> dailyList = new ArrayList<>();
            for (JsonNode day : dailyNode.path("daily")) {
                dailyList.add(WeatherResponse.DailyWeather.builder()
                        .fxDate(day.path("fxDate").asText())
                        .tempMax(day.path("tempMax").asText())
                        .tempMin(day.path("tempMin").asText())
                        .textDay(day.path("textDay").asText())
                        .textNight(day.path("textNight").asText())
                        .iconDay(day.path("iconDay").asText())
                        .iconNight(day.path("iconNight").asText())
                        .windDirDay(day.path("windDirDay").asText())
                        .windScaleDay(day.path("windScaleDay").asText())
                        .humidity(day.path("humidity").asText())
                        .uvIndex(day.path("uvIndex").asText(""))
                        .build());
            }
            builder.daily(dailyList);
        }

        WeatherResponse.AirQuality airQuality = parseAirQuality(airNode);
        if (airQuality != null) {
            builder.air(airQuality);
        }

        List<WeatherResponse.AirHourly> airHourly = parseAirHourly(airHourlyNode);
        if (!airHourly.isEmpty()) {
            builder.airHourly(airHourly);
        }

        WeatherResponse.UvIndex uv = parseUvIndex(indicesNode);
        if (uv == null && dailyNode != null && dailyNode.path("daily").isArray()
                && dailyNode.path("daily").size() > 0) {
            String uvIndex = dailyNode.path("daily").get(0).path("uvIndex").asText("");
            if (!uvIndex.isBlank()) {
                uv = WeatherResponse.UvIndex.builder()
                        .date(dailyNode.path("daily").get(0).path("fxDate").asText(""))
                        .level(uvIndex)
                        .category(uvCategoryFromNumber(uvIndex))
                        .name("\u7d2b\u5916\u7ebf\u6307\u6570")
                        .text("")
                        .build();
            }
        }
        if (uv != null) {
            builder.uv(uv);
        }

        builder.animationType(mapIconToAnimation(iconCode));
        return builder.build();
    }

    private List<WeatherResponse.AirHourly> parseAirHourly(JsonNode airHourlyNode) {
        List<WeatherResponse.AirHourly> list = new ArrayList<>();
        if (airHourlyNode == null || !airHourlyNode.has("hours")) {
            return list;
        }
        int count = 0;
        for (JsonNode hour : airHourlyNode.path("hours")) {
            if (count >= 24) break;
            JsonNode index = pickAirIndex(hour.path("indexes"));
            if (index == null) continue;
            String aqi = index.path("aqiDisplay").asText(index.path("aqi").asText("0"));
            String category = index.path("category").asText("");
            if (category.isBlank()) {
                category = index.path("name").asText("");
            }
            list.add(WeatherResponse.AirHourly.builder()
                    .fxTime(hour.path("forecastTime").asText(""))
                    .aqi(aqi)
                    .level(index.path("level").asText(""))
                    .category(category)
                    .color(getAqiColor(aqi))
                    .build());
            count++;
        }
        return list;
    }

    private WeatherResponse.UvIndex parseUvIndex(JsonNode indicesNode) {
        if (indicesNode == null || !indicesNode.has("daily") || indicesNode.path("daily").isEmpty()) {
            return null;
        }
        for (JsonNode day : indicesNode.path("daily")) {
            String type = day.path("type").asText("");
            String name = day.path("name").asText("");
            if ("5".equals(type) || name.contains("\u7d2b\u5916\u7ebf")) {
                return WeatherResponse.UvIndex.builder()
                        .date(day.path("date").asText(""))
                        .level(day.path("level").asText(""))
                        .category(day.path("category").asText(""))
                        .name(name.isBlank() ? "\u7d2b\u5916\u7ebf\u6307\u6570" : name)
                        .text(day.path("text").asText(""))
                        .build();
            }
        }
        JsonNode day = indicesNode.path("daily").get(0);
        return WeatherResponse.UvIndex.builder()
                .date(day.path("date").asText(""))
                .level(day.path("level").asText(""))
                .category(day.path("category").asText(""))
                .name(day.path("name").asText("\u7d2b\u5916\u7ebf\u6307\u6570"))
                .text(day.path("text").asText(""))
                .build();
    }

    private String uvCategoryFromNumber(String uvIndex) {
        try {
            int v = Integer.parseInt(uvIndex.replace("+", "").trim());
            if (v <= 2) return "\u6700\u5f31";
            if (v <= 4) return "\u5f31";
            if (v <= 6) return "\u4e2d\u7b49";
            if (v <= 9) return "\u5f3a";
            return "\u5f88\u5f3a";
        } catch (Exception e) {
            return uvIndex;
        }
    }

    private WeatherResponse.AirQuality parseAirQuality(JsonNode airNode) {
        if (airNode == null || airNode.isNull()) {
            return null;
        }
        if (airNode.has("now")) {
            JsonNode air = airNode.path("now");
            String aqi = air.path("aqi").asText("0");
            String category = air.path("category").asText("\u672a\u77e5");
            return WeatherResponse.AirQuality.builder()
                    .aqi(aqi)
                    .level(air.path("level").asText())
                    .category(category)
                    .primary(air.path("primary").asText())
                    .pm2p5(air.path("pm2p5").asText())
                    .pm10(air.path("pm10").asText())
                    .no2(air.path("no2").asText())
                    .so2(air.path("so2").asText())
                    .co(air.path("co").asText())
                    .o3(air.path("o3").asText())
                    .color(getAqiColor(aqi))
                    .build();
        }

        JsonNode index = pickAirIndex(airNode.path("indexes"));
        if (index == null) {
            return null;
        }

        String aqi = index.path("aqiDisplay").asText(index.path("aqi").asText("0"));
        String category = index.path("category").asText("");
        if (category.isBlank()) {
            category = index.path("name").asText("\u672a\u77e5");
        }
        String primary = index.path("primaryPollutant").path("name").asText("");
        if (primary.isBlank()) {
            primary = index.path("primaryPollutant").path("code").asText("NA");
        }

        return WeatherResponse.AirQuality.builder()
                .aqi(aqi)
                .level(index.path("level").asText(""))
                .category(category)
                .primary(primary)
                .pm2p5(findPollutant(airNode, "pm2p5"))
                .pm10(findPollutant(airNode, "pm10"))
                .no2(findPollutant(airNode, "no2"))
                .so2(findPollutant(airNode, "so2"))
                .co(findPollutant(airNode, "co"))
                .o3(findPollutant(airNode, "o3"))
                .color(getAqiColor(aqi))
                .build();
    }

    private JsonNode pickAirIndex(JsonNode indexes) {
        if (indexes == null || !indexes.isArray() || indexes.isEmpty()) {
            return null;
        }
        JsonNode fallback = null;
        for (JsonNode index : indexes) {
            String code = index.path("code").asText("").toLowerCase(Locale.ROOT);
            if (code.contains("cn") || code.contains("mee") || code.contains("qaqi")) {
                return index;
            }
            if (fallback == null) {
                fallback = index;
            }
        }
        return fallback;
    }

    private String findPollutant(JsonNode airNode, String code) {
        for (JsonNode pollutant : airNode.path("pollutants")) {
            if (code.equalsIgnoreCase(pollutant.path("code").asText())) {
                JsonNode concentration = pollutant.path("concentration");
                String value = concentration.path("value").asText("");
                String unit = concentration.path("unit").asText("");
                if (!value.isBlank() && !unit.isBlank()) {
                    return value + unit;
                }
                return value;
            }
        }
        return "";
    }

    public static String mapIconToAnimation(String icon) {
        if (icon == null || icon.isEmpty()) return "sunny";
        int code;
        try {
            code = Integer.parseInt(icon);
        } catch (NumberFormatException e) {
            return "sunny";
        }
        if (code >= 400 && code <= 499) return "snow";
        if (code >= 300 && code <= 399) return "rain";
        if (code >= 100 && code <= 103) return "sunny";
        if (code == 104) return "cloudy";
        if (code >= 150 && code <= 153) return "sunny";
        if (code >= 350 && code <= 399) return "rain";
        if (code >= 450 && code <= 499) return "snow";
        return "cloudy";
    }

    public static String getAqiColor(String aqiStr) {
        try {
            double aqi = Double.parseDouble(aqiStr.trim());
            if (aqi > 0 && aqi <= 15) {
                aqi = aqi * 20;
            }
            if (aqi <= 50) return "#81C784";
            if (aqi <= 100) return "#FFD54F";
            if (aqi <= 150) return "#FFB74D";
            if (aqi <= 200) return "#E57373";
            if (aqi <= 300) return "#BA68C8";
            return "#9575A8";
        } catch (NumberFormatException e) {
            return "#888888";
        }
    }
}
package com.weather.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.weather.config.AppConfig.QWeatherProperties;
import com.weather.dto.CitySearchResult;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.zip.GZIPInputStream;

@Slf4j
@Service
@RequiredArgsConstructor
public class QWeatherClient {

    private final RestTemplate restTemplate;
    private final QWeatherProperties props;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public List<CitySearchResult> searchCity(String keyword) {
        if (keyword == null || keyword.isBlank()) {
            return List.of();
        }
        String trimmed = keyword.trim();
        List<CitySearchResult> results = List.of();
        if (containsChinese(trimmed)) {
            String alias = ChineseCityAliases.toEnglish(trimmed);
            if (alias != null) {
                results = lookupCities(alias, "cn", "en");
                if (results.isEmpty()) {
                    results = lookupCities(alias, null, "en");
                }
            }
            if (results == null || results.isEmpty()) {
                results = lookupCities(trimmed, "cn", "zh");
            }
            if (results.isEmpty() && !trimmed.endsWith("\u5e02")) {
                results = lookupCities(trimmed + "\u5e02", "cn", "zh");
            }
            if (results.isEmpty()) {
                results = lookupCities(trimmed, null, "zh");
            }
        } else {
            results = lookupCities(trimmed, null, "en");
        }
        return results;
    }

    private List<CitySearchResult> lookupCities(String keyword, String range, String lang) {
        UriComponentsBuilder builder = UriComponentsBuilder
                .fromHttpUrl(props.apiHost() + "/geo/v2/city/lookup")
                .queryParam("location", keyword)
                .queryParam("number", 20)
                .queryParam("lang", lang);
        if (range != null && !range.isBlank()) {
            builder.queryParam("range", range);
        }
        String url = builder.encode(StandardCharsets.UTF_8).build().toUriString();

        try {
            JsonNode root = objectMapper.readTree(get(url));
            if (!"200".equals(root.path("code").asText())) {
                log.warn("City lookup failed, keyword={}, range={}, code={}",
                        keyword, range, root.path("code").asText());
                return List.of();
            }

            List<CitySearchResult> results = new ArrayList<>();
            for (JsonNode loc : root.path("location")) {
                results.add(CitySearchResult.builder()
                        .id(loc.path("id").asText())
                        .name(loc.path("name").asText())
                        .adm1(loc.path("adm1").asText())
                        .adm2(loc.path("adm2").asText())
                        .country(loc.path("country").asText())
                        .lat(loc.path("lat").asDouble())
                        .lon(loc.path("lon").asDouble())
                        .build());
            }
            return results;
        } catch (Exception e) {
            log.error("City lookup error, keyword={}, range={}", keyword, range, e);
            return List.of();
        }
    }

    public JsonNode getNowWeather(String cityId, String lang) {
        return fetch("/v7/weather/now", cityId, lang);
    }


    public JsonNode getHourlyForecast(String cityId, String lang) {
        return fetch("/v7/weather/24h", cityId, lang);
    }    public JsonNode getDailyForecast(String cityId, String lang) {
        return fetch("/v7/weather/7d", cityId, lang);
    }

    public JsonNode getAirQuality(double lat, double lon) {
        String path = String.format(Locale.US, "/airquality/v1/current/%.2f/%.2f", lat, lon);
        String url = UriComponentsBuilder.fromHttpUrl(props.apiHost() + path)
                .encode(StandardCharsets.UTF_8)
                .build()
                .toUriString();
        try {
            JsonNode root = objectMapper.readTree(get(url));
            if (root.has("indexes") && root.path("indexes").isArray() && root.path("indexes").size() > 0) {
                return root;
            }
            log.warn("Air quality v1 empty for lat={}, lon={}", lat, lon);
            return null;
        } catch (Exception e) {
            log.error("Air quality fetch error for lat={}, lon={}", lat, lon, e);
            return null;
        }
    }

    private JsonNode fetch(String path, String cityId, String lang) {
        UriComponentsBuilder builder = UriComponentsBuilder.fromHttpUrl(props.apiHost() + path)
                .queryParam("location", cityId);
        if (lang != null && !lang.isBlank()) {
            builder.queryParam("lang", lang);
        }
        String url = builder.encode(StandardCharsets.UTF_8).build().toUriString();

        try {
            JsonNode root = objectMapper.readTree(get(url));
            if (!"200".equals(root.path("code").asText())) {
                log.warn("QWeather API error at {}: {}", path, root.path("code").asText());
                return null;
            }
            return root;
        } catch (Exception e) {
            log.error("QWeather fetch error: {}", path, e);
            return null;
        }
    }

    private String get(String url) throws IOException {
        HttpHeaders headers = new HttpHeaders();
        headers.set("X-QW-Api-Key", props.apiKey());
        headers.setAccept(List.of(MediaType.APPLICATION_JSON));
        headers.set(HttpHeaders.ACCEPT_ENCODING, "gzip");
        ResponseEntity<byte[]> response = restTemplate.exchange(
                url, HttpMethod.GET, new HttpEntity<>(headers), byte[].class);
        byte[] body = response.getBody();
        if (body == null || body.length == 0) {
            return "";
        }
        return decodeResponseBody(body);
    }

    public static boolean containsChinese(String text) {
        if (text == null || text.isEmpty()) {
            return false;
        }
        return text.codePoints().anyMatch(codePoint ->
                Character.UnicodeScript.of(codePoint) == Character.UnicodeScript.HAN);
    }

    public static String resolveLang(String country) {
        if (country == null || country.isBlank()) {
            return "zh";
        }
        String normalized = country.trim();
        if ("\u4e2d\u56fd".equals(normalized) || "china".equalsIgnoreCase(normalized)) {
            return "zh";
        }
        if ("\u65e5\u672c".equals(normalized) || "japan".equalsIgnoreCase(normalized)) {
            return "ja";
        }
        if ("\u97e9\u56fd".equals(normalized) || "south korea".equalsIgnoreCase(normalized)
                || "korea".equalsIgnoreCase(normalized)) {
            return "ko";
        }
        return "en";
    }

    private String decodeResponseBody(byte[] body) throws IOException {
        if (body.length >= 2 && (body[0] & 0xFF) == 0x1F && (body[1] & 0xFF) == 0x8B) {
            try (GZIPInputStream gzip = new GZIPInputStream(new ByteArrayInputStream(body))) {
                return new String(gzip.readAllBytes(), StandardCharsets.UTF_8);
            }
        }
        return new String(body, StandardCharsets.UTF_8);
    }
}
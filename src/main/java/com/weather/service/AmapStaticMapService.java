package com.weather.service;

import com.weather.config.AppConfig.AmapProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;
import java.util.Locale;

@Slf4j
@Service
@RequiredArgsConstructor
public class AmapStaticMapService {

    private static final String STATIC_MAP_URL = "https://restapi.amap.com/v3/staticmap";

    private final RestTemplate restTemplate;
    private final AmapProperties amapProperties;

    public byte[] fetchStaticMap(double lon, double lat, int zoom, int width, int height) {
        String apiKey = amapProperties.apiKey();
        if (apiKey == null || apiKey.isBlank() || "YOUR_AMAP_KEY_HERE".equals(apiKey)) {
            log.warn("Amap api-key is not configured");
            return null;
        }

        int safeZoom = Math.max(3, Math.min(zoom, 17));
        int safeWidth = Math.max(100, Math.min(width, 1024));
        int safeHeight = Math.max(100, Math.min(height, 1024));

        String location = String.format(Locale.US, "%.6f,%.6f", lon, lat);
        String markers = "mid,,A:" + location;

        URI uri = UriComponentsBuilder.fromHttpUrl(STATIC_MAP_URL)
                .queryParam("location", location)
                .queryParam("zoom", safeZoom)
                .queryParam("size", safeWidth + "*" + safeHeight)
                .queryParam("scale", 2)
                .queryParam("markers", markers)
                .queryParam("key", apiKey)
                .build(true)
                .toUri();

        try {
            ResponseEntity<byte[]> response = restTemplate.exchange(uri, HttpMethod.GET, null, byte[].class);
            byte[] body = response.getBody();
            if (body == null || body.length == 0) {
                log.warn("Amap static map returned empty body for {}", location);
                return null;
            }
            if (body.length < 8 || body[0] != (byte) 0x89) {
                String text = new String(body, 0, Math.min(body.length, 300), java.nio.charset.StandardCharsets.UTF_8);
                log.warn("Amap static map returned non-image payload for {}: {}", location, text);
                return null;
            }
            return body;
        } catch (Exception ex) {
            log.error("Failed to fetch Amap static map for {}", location, ex);
            return null;
        }
    }
}
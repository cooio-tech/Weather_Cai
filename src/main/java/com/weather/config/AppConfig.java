package com.weather.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

@Configuration
public class AppConfig {

    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }

    @Bean
    public QWeatherProperties qWeatherProperties(
            @Value("${qweather.api-key}") String apiKey,
            @Value("${qweather.api-host}") String apiHost,
            @Value("${weather.cache-ttl-minutes}") int cacheTtlMinutes) {
        return new QWeatherProperties(apiKey, normalizeApiHost(apiHost), cacheTtlMinutes);
    }

    @Bean
    public AmapProperties amapProperties(@Value("${amap.api-key:}") String apiKey) {
        return new AmapProperties(apiKey == null ? "" : apiKey.trim());
    }

    static String normalizeApiHost(String apiHost) {
        String host = apiHost == null ? "" : apiHost.trim();
        if (host.endsWith("/")) {
            host = host.substring(0, host.length() - 1);
        }
        if (!host.startsWith("http://") && !host.startsWith("https://")) {
            host = "https://" + host;
        }
        return host;
    }

    public record QWeatherProperties(String apiKey, String apiHost, int cacheTtlMinutes) {}

    public record AmapProperties(String apiKey) {}
}
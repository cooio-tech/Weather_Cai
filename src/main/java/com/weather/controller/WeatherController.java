package com.weather.controller;

import com.weather.dto.ApiResult;
import com.weather.dto.CitySearchResult;
import com.weather.dto.WeatherResponse;
import com.weather.service.QWeatherClient;
import com.weather.service.WeatherService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.util.List;

@RestController
@RequestMapping("/api/weather")
@RequiredArgsConstructor
public class WeatherController {

    private final WeatherService weatherService;

    @GetMapping("/search")
    public ApiResult<List<CitySearchResult>> search(@RequestParam String city) {
        List<CitySearchResult> results = weatherService.searchCity(decodeCityParam(city));
        return ApiResult.ok(results);
    }

    @GetMapping("/now")
    public ApiResult<WeatherResponse> getWeather(@RequestParam String city) {
        WeatherResponse data = weatherService.getWeatherByCityName(decodeCityParam(city));
        if (data == null) {
            return ApiResult.fail("\u672a\u627e\u5230\u8be5\u57ce\u5e02\u6216\u5929\u6c14\u6570\u636e\u83b7\u53d6\u5931\u8d25");
        }
        return ApiResult.ok(data);
    }

    @GetMapping("/city/{cityId}")
    public ApiResult<WeatherResponse> getWeatherById(@PathVariable String cityId) {
        WeatherResponse data = weatherService.getWeatherByCityId(cityId);
        if (data == null) {
            return ApiResult.fail("\u5929\u6c14\u6570\u636e\u83b7\u53d6\u5931\u8d25");
        }
        return ApiResult.ok(data);
    }


    @GetMapping("/brief")
    public ApiResult<List<com.weather.dto.CityBriefWeather>> getBrief(@RequestParam String cities) {
        List<String> names = java.util.Arrays.stream(cities.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toList();
        return ApiResult.ok(weatherService.getBriefWeatherList(names));
    }    @DeleteMapping("/cache")
    public ApiResult<Void> clearCache() {
        weatherService.clearServerCache();
        return ApiResult.ok(null);
    }

    static String decodeCityParam(String city) {
        if (city == null || city.isBlank()) {
            return "";
        }
        String trimmed = city.trim();
        if (QWeatherClient.containsChinese(trimmed)) {
            return trimmed;
        }
        try {
            String fixed = new String(trimmed.getBytes(StandardCharsets.ISO_8859_1), StandardCharsets.UTF_8);
            if (QWeatherClient.containsChinese(fixed)) {
                return fixed.trim();
            }
        } catch (Exception ignored) {
            // keep original value
        }
        return trimmed;
    }
}
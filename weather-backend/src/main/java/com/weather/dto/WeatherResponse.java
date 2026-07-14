package com.weather.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class WeatherResponse {
    private CityInfo city;
    private NowWeather now;
    private List<HourlyWeather> hourly;
    private List<DailyWeather> daily;
    private AirQuality air;
    private String animationType;
    private boolean fromCache;

    @Data
    @Builder
    public static class CityInfo {
        private String id;
        private String name;
        private String adm1;
        private String adm2;
        private String country;
        private double lat;
        private double lon;
    }

    @Data
    @Builder
    public static class NowWeather {
        private String obsTime;
        private String temp;
        private String feelsLike;
        private String text;
        private String icon;
        private String windDir;
        private String windScale;
        private String windSpeed;
        private String humidity;
        private String precip;
        private String pressure;
        private String vis;
    }

    @Data
    @Builder
    public static class HourlyWeather {
        private String fxTime;
        private String temp;
        private String icon;
        private String text;
        private String windDir;
        private String windScale;
        private String windSpeed;
        private String humidity;
        private String pop;
        private String precip;
    }

    @Data
    @Builder
    public static class DailyWeather {
        private String fxDate;
        private String tempMax;
        private String tempMin;
        private String textDay;
        private String textNight;
        private String iconDay;
        private String iconNight;
        private String windDirDay;
        private String windScaleDay;
        private String humidity;
    }

    @Data
    @Builder
    public static class AirQuality {
        private String aqi;
        private String level;
        private String category;
        private String primary;
        private String pm2p5;
        private String pm10;
        private String no2;
        private String so2;
        private String co;
        private String o3;
        private String color;
    }
}
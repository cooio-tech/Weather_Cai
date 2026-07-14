package com.weather.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class CityBriefWeather {
    private String cityId;
    private String cityName;
    private String temp;
    private String weatherText;
    private String aqi;
    private String aqiCategory;
}
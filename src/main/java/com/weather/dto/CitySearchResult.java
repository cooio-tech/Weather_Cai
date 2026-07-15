package com.weather.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class CitySearchResult {
    private String id;
    private String name;
    private String adm1;
    private String adm2;
    private String country;
    private double lat;
    private double lon;
}

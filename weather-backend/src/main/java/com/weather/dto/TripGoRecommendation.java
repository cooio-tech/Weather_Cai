package com.weather.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class TripGoRecommendation {
    private String cityId;
    private String cityName;
    private int score;
    private boolean recommended;
    private String summary;
    private List<String> activities;
    private String reason;
    private Double distanceKm;
    private String distanceBand;
    private String bestDays;
}
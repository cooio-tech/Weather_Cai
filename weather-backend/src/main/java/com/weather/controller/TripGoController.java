package com.weather.controller;

import com.weather.dto.ApiResult;
import com.weather.dto.TripGoRecommendation;
import com.weather.service.TripGoService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/tripgo")
@RequiredArgsConstructor
public class TripGoController {

    private final TripGoService tripGoService;

    @GetMapping("/recommend")
    public ApiResult<List<TripGoRecommendation>> recommend(
            @RequestParam(required = false) Double lat,
            @RequestParam(required = false) Double lon,
            @RequestParam(required = false) String fromCity) {
        // Always score by 7-day forecast.
        return ApiResult.ok(tripGoService.recommend(lat, lon, fromCity));
    }
}
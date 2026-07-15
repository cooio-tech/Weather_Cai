package com.weather.controller;

import com.weather.service.AmapStaticMapService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/map")
@RequiredArgsConstructor
public class MapController {

    private final AmapStaticMapService amapStaticMapService;

    @GetMapping("/static")
    public ResponseEntity<byte[]> staticMap(
            @RequestParam double lon,
            @RequestParam double lat,
            @RequestParam(defaultValue = "11") int zoom,
            @RequestParam(defaultValue = "440") int width,
            @RequestParam(defaultValue = "360") int height) {
        byte[] image = amapStaticMapService.fetchStaticMap(lon, lat, zoom, width, height);
        if (image == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok()
                .header(HttpHeaders.CACHE_CONTROL, "public, max-age=1800")
                .contentType(MediaType.IMAGE_PNG)
                .body(image);
    }
}
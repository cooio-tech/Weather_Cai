package com.weather.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "weather_cache", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"city_id", "cache_type"})
})
public class WeatherCacheEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "city_id", nullable = false, length = 32)
    private String cityId;

    @Column(name = "cache_type", nullable = false, length = 32)
    private String cacheType;

    @Column(name = "json_data", nullable = false, columnDefinition = "TEXT")
    private String jsonData;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;
}

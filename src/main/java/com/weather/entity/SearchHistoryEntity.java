package com.weather.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "search_history")
public class SearchHistoryEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "city_name", nullable = false, length = 64)
    private String cityName;

    @Column(name = "city_id", nullable = false, length = 32)
    private String cityId;

    @Column(name = "searched_at")
    private LocalDateTime searchedAt = LocalDateTime.now();
}

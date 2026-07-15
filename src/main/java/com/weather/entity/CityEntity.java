package com.weather.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "city")
public class CityEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "city_id", nullable = false, unique = true, length = 32)
    private String cityId;

    @Column(nullable = false, length = 64)
    private String name;

    @Column(length = 64)
    private String adm1;

    @Column(length = 64)
    private String adm2;

    @Column(length = 32)
    private String country;

    private Double lat;
    private Double lon;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();
}

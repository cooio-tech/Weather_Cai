package com.weather.repository;

import com.weather.entity.WeatherCacheEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface WeatherCacheRepository extends JpaRepository<WeatherCacheEntity, Long> {
    Optional<WeatherCacheEntity> findByCityIdAndCacheType(String cityId, String cacheType);
    void deleteByCityId(String cityId);
}

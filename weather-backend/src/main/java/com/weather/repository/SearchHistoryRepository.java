package com.weather.repository;

import com.weather.entity.SearchHistoryEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SearchHistoryRepository extends JpaRepository<SearchHistoryEntity, Long> {
    List<SearchHistoryEntity> findTop10ByOrderBySearchedAtDesc();
}

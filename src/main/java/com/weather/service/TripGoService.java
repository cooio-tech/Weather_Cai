package com.weather.service;

import com.weather.dto.TripGoRecommendation;
import com.weather.dto.WeatherResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
public class TripGoService {

    private static final int WINDOW_DAYS = 7;

    /** Known QWeather LocationIDs — skip city lookup for speed. */
    private static final List<Candidate> CANDIDATES = List.of(
            new Candidate("上海", "101020100", 31.2304, 121.4737),
            new Candidate("杭州", "101210101", 30.2741, 120.1551),
            new Candidate("厦门", "101230201", 24.4798, 118.0894),
            new Candidate("青岛", "101120201", 36.0671, 120.3826),
            new Candidate("成都", "101270101", 30.5728, 104.0668),
            new Candidate("北京", "101010100", 39.9042, 116.4074),
            new Candidate("广州", "101280101", 23.1291, 113.2644),
            new Candidate("深圳", "101280601", 22.5431, 114.0579),
            new Candidate("南京", "101190101", 32.0603, 118.7969),
            new Candidate("苏州", "101190401", 31.2989, 120.5853),
            new Candidate("昆明", "101290101", 25.0389, 102.7183),
            new Candidate("西安", "101110101", 34.3416, 108.9398),
            new Candidate("重庆", "101040100", 29.5630, 106.5516),
            new Candidate("海口", "101310101", 20.0440, 110.1999),
            new Candidate("大连", "101070201", 38.9140, 121.6147),
            new Candidate("宁波", "101210401", 29.8683, 121.5440),
            new Candidate("无锡", "101190201", 31.4912, 120.3119),
            new Candidate("济南", "101120101", 36.6512, 117.1201),
            new Candidate("长沙", "101250101", 28.2282, 112.9388),
            new Candidate("合肥", "101220101", 31.8206, 117.2272),
            new Candidate("福州", "101230101", 26.0745, 119.2965),
            new Candidate("武汉", "101200101", 30.5928, 114.3055),
            new Candidate("郑州", "101180101", 34.7466, 113.6254),
            new Candidate("天津", "101030100", 39.3434, 117.3616),
            new Candidate("佛山", "101280800", 23.0215, 113.1214),
            new Candidate("东莞", "101281601", 23.0205, 113.7518),
            new Candidate("南昌", "101240101", 28.6820, 115.8579),
            new Candidate("沈阳", "101070101", 41.8057, 123.4315),
            new Candidate("长春", "101060101", 43.8171, 125.3235),
            new Candidate("南宁", "101300101", 22.8170, 108.3669)
    );

    private final WeatherService weatherService;
    private final ExecutorService tripExecutor = Executors.newFixedThreadPool(8);

    public List<TripGoRecommendation> recommend(Double fromLat, Double fromLon, String fromCity) {
        int window = WINDOW_DAYS;
        String origin = normalizeCity(fromCity);

        List<CompletableFuture<TripGoRecommendation>> futures = new ArrayList<>();
        for (Candidate c : CANDIDATES) {
            if (!origin.isEmpty() && normalizeCity(c.name()).equals(origin)) {
                continue;
            }
            futures.add(CompletableFuture.supplyAsync(() -> {
                try {
                    WeatherResponse weather = weatherService.getDailyForTrip(c.id(), c.name(), c.lat(), c.lon());
                    if (weather == null || weather.getCity() == null
                            || weather.getDaily() == null || weather.getDaily().isEmpty()) {
                        return null;
                    }
                    if (!origin.isEmpty() && normalizeCity(weather.getCity().getName()).equals(origin)) {
                        return null;
                    }
                    return scoreCity(weather, window, fromLat, fromLon);
                } catch (Exception e) {
                    return null;
                }
            }, tripExecutor));
        }

        List<TripGoRecommendation> results = futures.stream()
                .map(f -> {
                    try {
                        return f.get(25, TimeUnit.SECONDS);
                    } catch (Exception e) {
                        return null;
                    }
                })
                .filter(Objects::nonNull)
                .collect(java.util.stream.Collectors.toCollection(ArrayList::new));

        results.sort(Comparator
                .comparing((TripGoRecommendation r) -> bandRank(r.getDistanceBand()))
                .thenComparing(TripGoRecommendation::isRecommended, Comparator.reverseOrder())
                .thenComparing(TripGoRecommendation::getScore, Comparator.reverseOrder())
                .thenComparing(r -> r.getDistanceKm() == null ? Double.MAX_VALUE : r.getDistanceKm()));

        return results.stream().limit(6).toList();
    }

    private TripGoRecommendation scoreCity(WeatherResponse weather, int days,
                                           Double fromLat, Double fromLon) {
        String cityName = weather.getCity().getName();
        int score = 70;
        int rainDays = 0;
        int goodDays = 0;
        double tempSum = 0;
        int tempCount = 0;
        List<String> risks = new ArrayList<>();

        int limit = Math.min(days, weather.getDaily().size());
        for (int i = 0; i < limit; i++) {
            WeatherResponse.DailyWeather day = weather.getDaily().get(i);
            String text = day.getTextDay() != null ? day.getTextDay() : "";
            boolean rainy = text.contains("雨") || isRainIcon(day.getIconDay());
            double avg = 20;
            try {
                double max = Double.parseDouble(day.getTempMax());
                double min = Double.parseDouble(day.getTempMin());
                avg = (max + min) / 2.0;
                tempSum += avg;
                tempCount++;
            } catch (NumberFormatException ignored) {
            }

            if (rainy) {
                rainDays++;
                score -= 12;
            } else {
                goodDays++;
                if (avg >= 15 && avg <= 30) {
                    score += 6;
                } else {
                    score += 2;
                }
            }

            if (avg < 5) {
                score -= 8;
            } else if (avg > 33) {
                score -= 8;
            }
        }

        int aqiVal = -1;
        if (weather.getAir() != null && weather.getAir().getAqi() != null) {
            aqiVal = parseInt(weather.getAir().getAqi());
            if (aqiVal > 100) {
                score -= 15;
                risks.add("AQI " + aqiVal);
            } else if (aqiVal <= 50) {
                score += 5;
            }
        }

        Double distanceKm = null;
        String distanceBand = "远程";
        if (fromLat != null && fromLon != null
                && weather.getCity().getLat() != 0 && weather.getCity().getLon() != 0) {
            distanceKm = haversineKm(fromLat, fromLon, weather.getCity().getLat(), weather.getCity().getLon());
            distanceBand = bandOf(distanceKm);
            if ("近程".equals(distanceBand)) {
                score += 28;
            } else if ("中程".equals(distanceBand)) {
                score += 12;
            } else {
                score -= 5;
            }
        }

        score = Math.max(0, Math.min(100, score));
        boolean recommended = score >= 58 && rainDays < Math.ceil(days * 0.6);

        double avgTemp = tempCount > 0 ? tempSum / tempCount : 0;
        int aqiForUi = Math.max(aqiVal, 0);
        List<String> activities = buildCityActivities(cityName, goodDays, rainDays, aqiForUi, avgTemp);
        String summary = buildSummary(cityName, days, goodDays, rainDays, avgTemp, aqiVal, distanceKm, distanceBand);
        String reason = buildReason(distanceBand, distanceKm, rainDays, avgTemp, aqiVal, risks, recommended);

        return TripGoRecommendation.builder()
                .cityId(weather.getCity().getId())
                .cityName(cityName)
                .score(score)
                .recommended(recommended)
                .summary(summary)
                .activities(activities)
                .reason(reason)
                .distanceKm(distanceKm == null ? null : Math.round(distanceKm * 10.0) / 10.0)
                .distanceBand(distanceBand)
                .bestDays("")
                .build();
    }

    private String buildSummary(String city, int days, int goodDays, int rainDays,
                                double avgTemp, int aqi, Double distanceKm, String band) {
        String tempHint = avgTemp >= 28 ? "偏热" : (avgTemp <= 12 ? "偏冷" : "温度适宜");
        if (rainDays >= 3) {
            return "未来" + days + "天多雨，" + tempHint;
        }
        String base = goodDays + "天晴好" +
                (rainDays > 0 ? ("/" + rainDays + "天有雨") : "") +
                "，" + tempHint;
        if (aqi >= 0) {
            return base + "，AQI " + aqi;
        }
        return base;
    }

    private String buildReason(String band, Double distanceKm, int rainDays,
                               double avgTemp, int aqi, List<String> risks, boolean ok) {
        List<String> parts = new ArrayList<>();
        if (distanceKm != null) {
            parts.add(band + "出行");
        }
        if (rainDays >= 3) {
            parts.add("多雨，偏室内活动");
        } else if (rainDays == 0 && aqi >= 0 && aqi <= 50) {
            parts.add("晴好且空气优");
        } else if (rainDays == 0) {
            parts.add("七日晴好为主");
        } else if (avgTemp >= 30) {
            parts.add("气温偏高，建议早晚出行");
        } else if (avgTemp <= 12) {
            parts.add("气温偏冷，注意保暖");
        }
        if (!risks.isEmpty()) {
            parts.add(String.join("、", risks));
        }
        if (!ok && parts.isEmpty()) {
            return "天气波动较大，建议换日再看";
        }
        if (parts.isEmpty()) {
            return "综合天气与距离，较适合短途出行";
        }
        return String.join(" · ", parts);
    }

    private List<String> buildCityActivities(String city, int goodDays, int rainDays,
                                             int aqiVal, double avgTemp) {
        String key = normalizeCity(city);
        List<String> signature = citySignature(key);
        List<String> rainyIndoor = cityRainyIndoor(key);
        List<String> acts = new ArrayList<>();

        if (rainDays >= 2) {
            acts.addAll(rainyIndoor);
        }
        if (goodDays >= 1 && aqiVal <= 120) {
            for (String a : signature) {
                if (!acts.contains(a)) {
                    acts.add(a);
                }
            }
        }
        if (avgTemp >= 31 && !acts.contains("避暑晚风")) {
            acts.add("避暑晚风");
        }
        if (aqiVal > 150) {
            acts.add(0, "少户外久留");
        }
        if (acts.isEmpty()) {
            acts.addAll(signature.subList(0, Math.min(2, signature.size())));
        }
        return acts.stream().limit(3).toList();
    }

    private List<String> citySignature(String key) {
        if (key.contains("\u53a6\u95e8")) return List.of("\u9f13\u6d6a\u5c7f\u770b\u6d77", "\u5357\u666e\u9640\u5c3e\u697c", "\u6c99\u8336\u54c9\u8336");
        if (key.contains("\u9752\u5c9b")) return List.of("\u68a7\u6850\u770b\u6d77", "\u5564\u9152\u535a\u7269\u9986", "\u6d77\u9c9c\u5c0f\u5403");
        if (key.contains("\u5927\u8fde")) return List.of("\u661f\u6d77\u5e7f\u573a\u6563\u6b65", "\u6d77\u6ee8\u665a\u98ce", "\u6d77\u9c9c\u70e7\u8003");
        if (key.contains("\u6d77\u53e3")) return List.of("\u4e07\u7eff\u56ed\u6563\u6b65", "\u9a91\u697c\u665a\u98ce", "\u6e05\u8865\u51c9");
        if (key.contains("\u4e0a\u6d77")) return List.of("\u5916\u6ee9\u591c\u666f", "\u7530\u5b50\u574a\u95f2\u901b", "\u672c\u5e2e\u7f8e\u98df");
        if (key.contains("\u5b81\u6ce2")) return List.of("\u8001\u5916\u6ee9\u6563\u6b65", "\u4e1c\u94b1\u6e56", "\u6d77\u9c9c\u65e9\u5e02");
        if (key.contains("\u676d\u5dde")) return List.of("\u897f\u6e56\u821f\u5f71", "\u6cb3\u574a\u8857\u6e38", "\u9f99\u4e95\u8336");
        if (key.contains("\u82cf\u5dde")) return List.of("\u5e73\u6c5f\u8def\u6162\u901b", "\u56ed\u6797\u542c\u96e8", "\u82cf\u5f0f\u7cd6\u6c34");
        if (key.contains("\u65e0\u9521")) return List.of("\u96ea\u6d6a\u8857\u591c\u666f", "\u6c5f\u5357\u53e4\u9547", "\u6ef4\u6e05\u83dc");
        if (key.contains("\u5357\u4eac")) return List.of("\u79e6\u6dee\u6cb3\u821f", "\u8001\u95e8\u4e1c\u5c0f\u5403", "\u7d2b\u91d1\u5c71");
        if (key.contains("\u6210\u90fd")) return List.of("\u5927\u718a\u732b\u57fa\u5730", "\u5bbd\u5df7\u5df7", "\u706b\u9505\u4e32\u4e32");
        if (key.contains("\u91cd\u5e86")) return List.of("\u6d2a\u5d16\u6d1e\u591c\u666f", "\u706b\u9505", "\u8f7b\u8f68\u770b\u57ce");
        if (key.contains("\u5317\u4eac")) return List.of("\u80e1\u540c\u6563\u6b65", "\u6545\u5bab\u65c1\u8def", "\u70e4\u9e2d");
        if (key.contains("\u897f\u5b89")) return List.of("\u57ce\u5899\u9a91\u884c", "\u56de\u6c11\u8857\u591c\u5e02", "\u5175\u9a6c\u4fd1");
        if (key.contains("\u6606\u660e")) return List.of("\u7fe0\u6e56", "\u8001\u8857", "\u82b1\u5e02\u7eff\u9053");
        if (key.contains("\u5e7f\u5dde")) return List.of("\u6c99\u9762", "\u73e0\u6c5f\u591c\u6e38", "\u65e9\u8336");
        if (key.contains("\u6df1\u5733")) return List.of("\u6280\u5de7\u57ce\u591c\u666f", "\u6f6e\u6c55\u7f8e\u98df", "\u6d77\u8fb9");
        if (key.contains("\u4f5b\u5c71")) return List.of("\u7956\u5e99", "\u7ca5\u6c34\u65e9\u8336", "\u9676\u827a\u6751");
        if (key.contains("\u4e1c\u839e")) return List.of("\u677e\u5c71\u6e56", "\u5357\u57ce", "\u6e29\u6cc9");
        if (key.contains("\u6b66\u6c49")) return List.of("\u9ec4\u9e64\u697c", "\u6c5f\u6ee9\u6563\u6b65", "\u70ed\u5e72\u9762");
        if (key.contains("\u957f\u6c99")) return List.of("\u5cb3\u9e93\u5c71", "\u6851\u690d\u8857", "\u8336\u989c\u60a6\u8272");
        if (key.contains("\u5408\u80a5")) return List.of("\u5305\u516c\u56ed", "\u8700\u5c71", "\u80e1\u8fa3\u6c64");
        if (key.contains("\u6d4e\u5357")) return List.of("\u5927\u660e\u6e56", "\u6cc9\u57ce\u5e7f\u573a", "\u6cb9\u70b8\u997c");
        if (key.contains("\u5929\u6d25")) return List.of("\u4e94\u5927\u8857", "\u6d77\u6cb3", "\u72d7\u4e0d\u7406");
        if (key.contains("\u90d1\u5dde")) return List.of("\u5c11\u6797\u5bfa", "\u4e8c\u4e03\u5e7f\u573a", "\u80e1\u8fa3\u6c64");
        if (key.contains("\u798f\u5dde")) return List.of("\u4e09\u574a\u4e03\u5df7", "\u70b9\u5fc3", "\u95fd\u83dc");
        if (key.contains("\u5357\u660c")) return List.of("\u817e\u738b\u9601", "\u79cb\u6c34\u5e7f\u573a", "\u7c89\u84b8\u8089");
        if (key.contains("\u6c88\u9633")) return List.of("\u4e2d\u8857", "\u6545\u5bab", "\u8001\u8fb9\u7599\u7629");
        if (key.contains("\u957f\u6625")) return List.of("\u5357\u6e56\u516c\u56ed", "\u4f2f\u6708\u6cc9", "\u70e4\u51b7\u9762");
        if (key.contains("\u5357\u5b81")) return List.of("\u9752\u79c0\u5c71", "\u5357\u6e56\u591c\u666f", "\u87ba\u866b\u7c89");
        return List.of("\u5730\u6807\u6253\u5361", "\u672c\u5730\u7f8e\u98df");
    }

    private List<String> cityRainyIndoor(String key) {
        if (key.contains("\u53a6\u95e8")) return List.of("\u53a6\u95e8\u535a\u7269\u9986", "\u6c99\u8336\u95f2\u5750");
        if (key.contains("\u9752\u5c9b")) return List.of("\u5564\u9152\u535a\u7269\u9986", "\u6d77\u9c9c\u70e7\u8003");
        if (key.contains("\u6210\u90fd") || key.contains("\u91cd\u5e86")) return List.of("\u706b\u9505\u5c40", "\u5ba4\u5185\u5c55\u89c8");
        if (key.contains("\u5317\u4eac")) return List.of("\u9996\u535a", "\u4e66\u5e97\u5496\u5561");
        if (key.contains("\u4e0a\u6d77")) return List.of("\u4e2d\u534e\u827a\u672f\u5bab", "\u5546\u573a\u901b\u901b");
        if (key.contains("\u676d\u5dde") || key.contains("\u82cf\u5dde")) return List.of("\u8336\u9986\u542c\u96e8", "\u535a\u7269\u9986");
        if (key.contains("\u5e7f\u5dde") || key.contains("\u6df1\u5733")) return List.of("\u8336\u697c\u65e9\u8336", "\u5546\u573a\u4f53\u9a8c");
        return List.of("\u535a\u7269\u9986", "\u5ba4\u5185\u7f8e\u98df");
    }
    private static double haversineKm(double lat1, double lon1, double lat2, double lon2) {
        final double r = 6371.0;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return 2 * r * Math.asin(Math.sqrt(a));
    }

    private static String bandOf(double km) {
        if (km < 300) {
            return "近程";
        }
        if (km < 800) {
            return "中程";
        }
        return "远程";
    }

    private static int bandRank(String band) {
        if ("近程".equals(band)) return 0;
        if ("中程".equals(band)) return 1;
        return 2;
    }

    private String normalizeCity(String city) {
        if (city == null) return "";
        return city.replace("市", "").trim();
    }

    private boolean isRainIcon(String icon) {
        if (icon == null || icon.isBlank()) return false;
        try {
            int code = Integer.parseInt(icon);
            return code >= 300 && code <= 399;
        } catch (NumberFormatException e) {
            return false;
        }
    }

    private int parseInt(String value) {
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    private record Candidate(String name, String id, double lat, double lon) {
    }
}
package com.weather.service;

import java.util.HashMap;
import java.util.Map;

public final class ChineseCityAliases {

    private static final Map<String, String> ALIASES = new HashMap<>();

    static {
        ALIASES.put("\u5317\u4eac", "Beijing");
        ALIASES.put("\u4e0a\u6d77", "Shanghai");
        ALIASES.put("\u5929\u6d25", "Tianjin");
        ALIASES.put("\u91cd\u5e86", "Chongqing");
        ALIASES.put("\u5357\u4eac", "Nanjing");
        ALIASES.put("\u5e7f\u5dde", "Guangzhou");
        ALIASES.put("\u6df1\u5733", "Shenzhen");
        ALIASES.put("\u676d\u5dde", "Hangzhou");
        ALIASES.put("\u6210\u90fd", "Chengdu");
        ALIASES.put("\u6b66\u6c49", "Wuhan");
        ALIASES.put("\u897f\u5b89", "Xi'an");
        ALIASES.put("\u82cf\u5dde", "Suzhou");
        ALIASES.put("\u90d1\u5dde", "Zhengzhou");
        ALIASES.put("\u9752\u5c9b", "Qingdao");
        ALIASES.put("\u5927\u8fde", "Dalian");
        ALIASES.put("\u53a6\u95e8", "Xiamen");
        ALIASES.put("\u798f\u5dde", "Fuzhou");
        ALIASES.put("\u6d4e\u5357", "Jinan");
        ALIASES.put("\u54c8\u5c14\u6ee8", "Harbin");
        ALIASES.put("\u6c88\u9633", "Shenyang");
        ALIASES.put("\u957f\u6c99", "Changsha");
        ALIASES.put("\u5408\u80a5", "Hefei");
        ALIASES.put("\u5357\u660c", "Nanchang");
        ALIASES.put("\u6606\u660e", "Kunming");
        ALIASES.put("\u8d35\u9633", "Guiyang");
        ALIASES.put("\u5357\u5b81", "Nanning");
        ALIASES.put("\u6d77\u53e3", "Haikou");
        ALIASES.put("\u592a\u539f", "Taiyuan");
        ALIASES.put("\u77f3\u5bb6\u5e84", "Shijiazhuang");
        ALIASES.put("\u957f\u6625", "Changchun");
        ALIASES.put("\u5170\u5dde", "Lanzhou");
        ALIASES.put("\u4e4c\u9c81\u6728\u9f50", "Urumqi");
        ALIASES.put("\u547c\u548c\u6d69\u7279", "Hohhot");
        ALIASES.put("\u94f6\u5ddd", "Yinchuan");
        ALIASES.put("\u897f\u5b81", "Xining");
        ALIASES.put("\u62c9\u8428", "Lhasa");
        ALIASES.put("\u9999\u6e2f", "Hong Kong");
        ALIASES.put("\u6fb3\u95e8", "Macau");
        ALIASES.put("\u53f0\u5317", "Taipei");
        ALIASES.put("\u6167\u5dde", "Huizhou");
        ALIASES.put("\u5b81\u6ce2", "Ningbo");
        ALIASES.put("\u65e0\u9521", "Wuxi");
        ALIASES.put("\u4e1c\u839e", "Dongguan");
        ALIASES.put("\u4f5b\u5c71", "Foshan");
    }

    private ChineseCityAliases() {
    }

    public static String toEnglish(String keyword) {
        if (keyword == null || keyword.isBlank()) {
            return null;
        }
        String key = keyword.trim()
                .replace("\u5e02", "")
                .replace("\u7701", "");
        return ALIASES.get(key);
    }
}
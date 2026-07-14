pragma Singleton
import QtQuick

QtObject {
    id: theme

    readonly property bool isDark: settingsManager.darkTheme

    readonly property color background: isDark ? "#1a1a2e" : "#e8f4f8"
    readonly property color surface: isDark ? "#16213e" : "#ffffff"
    readonly property color primary: isDark ? "#0f3460" : "#2196F3"
    readonly property color accent: isDark ? "#89b4d4" : "#FF5722"
    readonly property color highlight: isDark ? "#5a7fa8" : "#FF5722"
    readonly property color mapMarker: "#e94560"
    readonly property color textPrimary: isDark ? "#eaeaea" : "#212121"
    readonly property color textSecondary: isDark ? "#a0a0a0" : "#757575"
    readonly property color cardBg: isDark ? "#1f2b47" : "#f5f5f5"
    readonly property color searchBg: isDark ? "#0f3460" : "#ffffff"
    readonly property color chartLine: isDark ? "#64B5F6" : "#1976D2"
    readonly property color chartBar: isDark ? "#81C784" : "#4CAF50"
    readonly property color chartTempMax: isDark ? "#e86868" : "#FF5722"
    readonly property color chartWind: isDark ? "#6dbfa8" : "#26A69A"
    readonly property color chartPrecip: isDark ? "#5a8ab0" : "#2196F3"
    readonly property color border: isDark ? "#2a3a5c" : "#e0e0e0"
    readonly property color shadow: isDark ? "#00000040" : "#00000020"

    function aqiColor(aqi) {
        var val = parseInt(aqi) || 0
        if (val <= 50) return "#81C784"
        if (val <= 100) return "#FFD54F"
        if (val <= 150) return "#FFB74D"
        if (val <= 200) return "#E57373"
        if (val <= 300) return "#BA68C8"
        return "#9575A8"
    }

    function aqiTextColor(aqi) {
        var val = parseInt(aqi) || 0
        if (val <= 150) return "#212121"
        return "#ffffff"
    }

    function aqiLabel(aqi) {
        var val = parseInt(aqi) || 0
        if (val <= 50) return "\u4f18"
        if (val <= 100) return "\u826f"
        if (val <= 150) return "\u8f7b\u5ea6\u6c61\u67d3"
        if (val <= 200) return "\u4e2d\u5ea6\u6c41\u67d3"
        if (val <= 300) return "\u91cd\u5ea6\u6c41\u67d3"
        return "\u4e25\u91cd\u6c41\u67d3"
    }
}
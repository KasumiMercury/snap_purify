pragma Singleton
import QtQuick

QtObject {
    property bool isDark: true

    // Backgrounds
    readonly property color windowBg:       isDark ? "#1e1e1e" : "#f0f0f0"
    readonly property color panelBg:        isDark ? "#2a2a2a" : "#e0e0e0"
    readonly property color titleBarBg:     isDark ? "#333333" : "#d0d0d0"
    readonly property color controlBg:      isDark ? "#3a3a3a" : "#cccccc"
    readonly property color controlHoverBg: isDark ? "#4a4a4a" : "#bbbbbb"
    readonly property color borderColor:    isDark ? "#555555" : "#aaaaaa"

    // Text
    readonly property color textPrimary:   isDark ? "#cccccc" : "#222222"
    readonly property color textSecondary: isDark ? "#888888" : "#666666"

    // Accent
    readonly property color accent:           "#00aaff"
    readonly property color markerUnselected: "#ffaa00"
    readonly property color destructive:      "#aa3333"

    // Selection
    readonly property color selectionBg: isDark ? "#003d66" : "#cce5ff"

    // Slider
    readonly property color sliderTrack:          isDark ? "#4a4a4a" : "#bbbbbb"
    readonly property color sliderHandle:         isDark ? "#cccccc" : "#555555"
    readonly property color sliderHandlePressed:  isDark ? "#ffffff" : "#333333"

    // Scrollbar
    readonly property color scrollbarDefault: isDark ? "#555555" : "#aaaaaa"
    readonly property color scrollbarHover:   isDark ? "#777777" : "#888888"
    readonly property color scrollbarPressed: isDark ? "#888888" : "#666666"
}

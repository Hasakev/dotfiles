pragma Singleton
import QtQuick
import Quickshell

// Chongqing at night, photographed rather than rendered: blue-black slate,
// cool off-white, one electric-blue accent, neon pink only when something's wrong.
Singleton {
    // Surfaces (cool slate)
    readonly property color base: "#0b0e15"
    readonly property color mantle: "#0f131b"
    readonly property color surface0: "#161b25"
    readonly property color surface1: "#202734"
    readonly property color surface2: "#2a3242"

    // Ink
    readonly property color text: "#e3e9f3"
    readonly property color subtext1: "#c3ccdb"
    readonly property color subtext0: "#9aa5b8"
    readonly property color overlay2: "#7d889c"
    readonly property color overlay1: "#5f6a7e"
    readonly property color overlay0: "#434c5e"

    // Accents
    readonly property color accent: Accent.color  // from the wallpaper (Accent.qml), default electric blue
    readonly property color alert: "#ff5c8a"      // neon sign
    readonly property color good: "#8fd3b6"       // used sparingly (awake, connected)

    // Legacy names used across panels -> collapse onto the roles above,
    // so nothing paints in five competing colours any more.
    readonly property color cyan: accent
    readonly property color blue: accent
    readonly property color blueDim: Qt.darker(accent, 1.35)
    readonly property color teal: subtext1
    readonly property color amber: "#f0b35e"       // "warm" warnings (temps, heavy load)
    readonly property color magenta: alert
    readonly property color red: alert
    readonly property color green: good

    readonly property string font: "Inter"
    readonly property string iconFont: "Symbols Nerd Font"
    readonly property int barHeight: 36
    readonly property int gap: 6
    readonly property int radius: 14

    // Island glass
    readonly property color island: a(base, 0.78)
    readonly property color hairline: a(text, 0.07)

    // Snappy-with-overshoot curve used by every popout/morph.
    readonly property var spring: [0.34, 1.36, 0.64, 1, 1, 1]

    function a(c, alpha) { return Qt.rgba(c.r, c.g, c.b, alpha) }
}

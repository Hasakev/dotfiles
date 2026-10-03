pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Accent colour taken from the main monitor's wallpaper-engine wallpaper:
// its preview image's most prominent saturated hue, at a fixed saturation and
// lightness so it reads on the slate. Fallback: electric blue.
Singleton {
    id: root

    readonly property color fallback: "#6fa8ff"
    readonly property string output: "HDMI-A-1"
    property color color: fallback
    Behavior on color { ColorAnimation { duration: 800; easing.type: Easing.InOutQuad } }

    // waypaper/wallpaper-engine.sh rewrite this file on every change.
    FileView {
        id: map
        path: Quickshell.env("HOME") + "/.config/hypr/wallpaper-engine.map"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const line = text().split("\n").find(l => l.startsWith(root.output + "\t"))
            const dir = line ? line.split("\t")[1] : ""
            if (!dir) { root.color = root.fallback; return }
            extract.command = ["sh", "-c",
                'p=$(jq -r .preview "$1/project.json") && magick "$1/$p[0]" -resize 64x64 -colors 8 -format "%c" histogram:info:',
                "_", dir]
            extract.running = true
        }
    }

    // Most prominent saturated colour in a magick `-format %c histogram:info:`
    // dump, normalised to a legible accent; null for greyscale images.
    // Shared with Player (album-art colour).
    function vivid(histogram, lightness) {
        let best = null, bestScore = 0
        for (const l of histogram.split("\n")) {
            const m = l.match(/^\s*(\d+):.*#([0-9A-Fa-f]{6})/)
            if (!m) continue
            const c = Qt.color("#" + m[2])
            // Prominence x saturation, ignoring near-black/near-white.
            const score = c.hslLightness > 0.18 && c.hslLightness < 0.85 ? parseInt(m[1]) * c.hslSaturation : 0
            if (score > bestScore) { bestScore = score; best = c }
        }
        return best && best.hslSaturation > 0.15 ? Qt.hsla(best.hslHue, 0.85, lightness ?? 0.72, 1) : null
    }

    Process {
        id: extract
        stdout: StdioCollector {
            onStreamFinished: root.color = root.vivid(text) ?? root.fallback
        }
        onExited: code => { if (code !== 0) root.color = root.fallback }
    }
}

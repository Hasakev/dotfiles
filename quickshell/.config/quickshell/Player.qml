pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

// The MPRIS player the bar follows: whatever is playing, else the last one.
Singleton {
    id: root

    readonly property var players: Mpris.players.values.filter(p => !p.dbusName.includes("firefox"))
    property MprisPlayer active: null

    function pick() {
        const playing = players.find(p => p.isPlaying)
        if (playing) active = playing
        else if (!players.includes(active)) active = players[0] ?? null
    }
    onPlayersChanged: pick()
    Instantiator {
        model: Mpris.players
        delegate: Connections {
            required property MprisPlayer modelData
            target: modelData
            function onIsPlayingChanged() { root.pick() }
        }
    }

    // MPRIS doesn't push position updates; poke the property while playing.
    Timer {
        running: root.active?.isPlaying ?? false
        interval: 1000
        repeat: true
        onTriggered: root.active.positionChanged()
    }

    // Cover-art colour (most prominent saturated hue), for tinting the media UI.
    readonly property string artUrl: active?.trackArtUrl ?? ""
    property color artColor: Theme.accent
    Behavior on artColor { ColorAnimation { duration: 600 } }
    onArtUrlChanged: {
        if (!artUrl) { artColor = Theme.accent; return }
        artProc.command = ["sh", "-c",
            'case "$1" in http*) curl -fsSL --max-time 5 "$1" | magick - -resize 48x48 -colors 8 -format "%c" histogram:info: ;;'
            + ' *) magick "${1#file://}" -resize 48x48 -colors 8 -format "%c" histogram:info: ;; esac', "_", artUrl]
        artProc.running = true
    }
    Process {
        id: artProc
        stdout: StdioCollector { onStreamFinished: root.artColor = Accent.vivid(text, 0.68) ?? Theme.accent }
    }

    function fmt(s) {
        s = Math.max(0, Math.floor(s))
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`
    }
}

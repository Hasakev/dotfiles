pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Time-synced lyrics from lrclib.net (free, no key) for the active player.
// Only fetched while the media panel is open (`wanted`); cached per song.
Singleton {
    id: root

    property bool wanted: false
    readonly property var p: Player.active
    readonly property string key: p?.trackTitle ? `${p.trackArtist}|${p.trackTitle}` : ""
    property var lines: []          // [{ t: seconds, text }]
    property bool loading: false
    property var cache: ({})

    onKeyChanged: fetch()
    onWantedChanged: fetch()

    // Index of the line being sung at `pos` seconds (-1 before the first).
    function index(pos) {
        let i = -1
        while (i + 1 < lines.length && lines[i + 1].t <= pos) i++
        return i
    }

    function fetch() {
        if (!wanted || !key) { lines = []; return }
        if (cache[key] !== undefined) { lines = cache[key]; return }
        if (proc.running) return            // onExited re-checks the key
        lines = []
        loading = true
        proc.reqKey = key
        proc.command = ["sh", "-c", `
            r=$(curl -fsSG --max-time 8 https://lrclib.net/api/get \
                --data-urlencode "artist_name=$1" --data-urlencode "track_name=$2" \
                --data-urlencode "album_name=$3" --data-urlencode "duration=$4" | jq -r '.syncedLyrics // empty')
            [ -z "$r" ] && r=$(curl -fsSG --max-time 8 https://lrclib.net/api/search \
                --data-urlencode "artist_name=$1" --data-urlencode "track_name=$2" \
                | jq -r '[.[] | select(.syncedLyrics)][0].syncedLyrics // empty')
            printf '%s' "$r"`,
            "_", p.trackArtist ?? "", p.trackTitle ?? "", p.trackAlbum ?? "", String(Math.round(p.length ?? 0))]
        proc.running = true
    }

    Process {
        id: proc
        property string reqKey
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const l of text.split("\n")) {
                    const m = l.match(/^\[(\d+):(\d+(?:\.\d+)?)\]\s*(.*)$/)
                    if (m) out.push({ t: parseInt(m[1]) * 60 + parseFloat(m[2]), text: m[3] || "♪" })
                }
                root.cache[proc.reqKey] = out
                root.fetch()   // exit and stream-end can arrive in either order
            }
        }
        onExited: {
            root.loading = false
            if (root.cache[reqKey] === undefined) root.cache[reqKey] = []
            // Track may have changed mid-request: fetch() serves the current one.
            root.fetch()
        }
    }
}

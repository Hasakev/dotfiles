pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// wttr.in, one request per refresh instead of waybar's five.
Singleton {
    id: root

    readonly property string location: "Buddina"
    property bool ok: false
    property string icon: ""
    property string temp: "--"
    property string desc: ""
    property string feels: ""
    property string humidity: ""
    property string wind: ""
    property string rain: ""
    property string uv: ""

    function refresh() { proc.running = true }

    Process {
        id: proc
        command: ["curl", "-fsS", "--max-time", "8",
                  `wttr.in/${root.location}?format=%c|%t|%C|%f|%h|%w|%p|%u`]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split("|")
                root.ok = p.length === 8
                if (!root.ok) return
                ;[root.icon, root.temp, root.desc, root.feels, root.humidity, root.wind, root.rain, root.uv] =
                    p.map(s => s.trim().replace(/^\+/, ""))
            }
        }
    }

    Timer { interval: 15 * 60 * 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}

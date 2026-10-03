pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU / RAM / CPU temperature (+ history), the "awake" idle inhibitor, and
// GPU + top processes which are only polled while the system panel is open.
Singleton {
    id: root

    property real cpu: 0          // 0..1
    property var cores: []        // 0..1 per core
    property real memUsed: 0      // GiB
    property real memTotal: 0     // GiB
    property real swapUsed: 0     // GiB
    property int temp: 0          // °C
    property bool awake: false

    readonly property int histLen: 60
    property var cpuHist: []
    property var memHist: []
    property var tempHist: []

    // Set by the system panel while it's open: 1s samples + GPU + processes.
    property bool detailed: false
    property var gpu: null        // { util, memUsed, memTotal, temp, power } — GiB/°C/W
    property var procs: []        // [{ pid, cpu, mem, name }]

    function kill(pid) { Quickshell.execDetached(["kill", String(pid)]); procPoll.restart() }

    // Inhibitor lives exactly as long as this process; dies with the shell.
    Process {
        running: root.awake
        command: ["systemd-inhibit", "--what=idle:sleep", "--who=quickshell",
                  "--why=Awake mode", "sleep", "infinity"]
    }

    // k10temp, located by name: hwmon numbering shifts between boots.
    property string tempPath: ""
    Process {
        running: true
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do [ \"$(cat $h/name)\" = k10temp ] && echo $h/temp1_input; done"]
        stdout: StdioCollector { onStreamFinished: root.tempPath = text.trim() }
    }

    // blockLoading: reload() then text() must return the fresh read, not ""
    // (an empty read made cpu/temp flicker to NaN/0).
    FileView { id: stat; path: "/proc/stat"; blockLoading: true }
    FileView { id: meminfo; path: "/proc/meminfo"; blockLoading: true }
    FileView { id: tempFile; path: root.tempPath; blockLoading: true }

    property var _prev: ({})
    function push(arr, v) { const a = arr.concat([v]); return a.length > histLen ? a.slice(a.length - histLen) : a }

    Timer {
        interval: root.detailed ? 1000 : 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload(); meminfo.reload(); if (root.tempPath) tempFile.reload()

            // "cpu" (total) then "cpu0".."cpuN": usage = 1 - Δidle/Δtotal
            const usage = {}
            for (const line of stat.text().split("\n")) {
                if (!line.startsWith("cpu")) break
                const p = line.split(/\s+/), f = p.slice(1).map(Number)
                if (f.length < 8 || f.some(isNaN)) continue
                const idle = f[3] + f[4], total = f.reduce((a, b) => a + b, 0), prev = root._prev[p[0]]
                if (prev && total > prev.total) usage[p[0]] = 1 - (idle - prev.idle) / (total - prev.total)
                root._prev[p[0]] = { idle, total }
            }
            if (usage.cpu !== undefined) {
                root.cpu = usage.cpu
                root.cores = Object.keys(usage).filter(k => k !== "cpu").sort((a, b) => a.slice(3) - b.slice(3)).map(k => usage[k])
                root.cpuHist = root.push(root.cpuHist, usage.cpu)
            }

            const m = {}
            for (const l of meminfo.text().split("\n")) {
                const p = l.split(/:\s+/)
                if (p.length > 1) m[p[0]] = parseInt(p[1])
            }
            if (m.MemTotal) {
                root.memTotal = m.MemTotal / 1048576
                root.memUsed = (m.MemTotal - m.MemAvailable) / 1048576
                root.swapUsed = (m.SwapTotal - m.SwapFree) / 1048576
                root.memHist = root.push(root.memHist, root.memUsed / root.memTotal)
            }

            const t = parseInt(tempFile.text())
            if (root.tempPath && !isNaN(t)) {
                root.temp = Math.round(t / 1000)
                root.tempHist = root.push(root.tempHist, root.temp)
            }
        }
    }

    // ── Detailed-only ───────────────────────────────────────────────────────
    Process {
        id: gpuProc
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw",
                  "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",").map(s => parseFloat(s))
                root.gpu = f.length === 5 && !f.some(isNaN)
                    ? { util: f[0] / 100, memUsed: f[1] / 1024, memTotal: f[2] / 1024, temp: f[3], power: f[4] } : null
            }
        }
    }
    // Second top iteration: the first one reports since-boot averages.
    Process {
        id: procProc
        command: ["sh", "-c", "top -b -n 2 -d 0.8 -o %CPU -w 200 | awk '/^top -/{n++} n==2 && $1 ~ /^[0-9]+$/ {print $1, $9, $10, $12}' | head -6"]
        stdout: StdioCollector {
            onStreamFinished: root.procs = text.trim().split("\n").filter(l => l).map(l => {
                const [pid, cpu, mem, name] = l.split(" ")
                return { pid: parseInt(pid), cpu: parseFloat(cpu), mem: parseFloat(mem), name }
            })
        }
    }
    Timer {
        id: procPoll
        interval: 2000
        running: root.detailed
        repeat: true
        triggeredOnStart: true
        onTriggered: { gpuProc.running = true; procProc.running = true }
    }
}

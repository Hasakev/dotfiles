pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// Wi-Fi via NetworkManager's D-Bus API: event-driven, no nmcli polling.
Singleton {
    id: root

    // Two wifi cards here see the same networks; follow the connected one.
    readonly property var devices: Networking.devices.values.filter(d => d.type === DeviceType.Wifi)
    readonly property var device: devices.find(d => d.connected) ?? devices[0] ?? null
    readonly property var active: device?.networks.values.find(n => n.connected) ?? null

    readonly property bool radio: Networking.wifiEnabled
    readonly property string ssid: active?.name ?? ""
    readonly property int signal: Math.round((active?.signalStrength ?? 0) * 100)
    readonly property bool scanning: device?.scannerEnabled ?? false

    // Strongest first, connected on top, de-duplicated by name.
    readonly property var networks: {
        const seen = {}
        return (device?.networks.values ?? [])
            .filter(n => n.name)
            .sort((a, b) => b.connected - a.connected || b.signalStrength - a.signalStrength)
            .filter(n => !seen[n.name] && (seen[n.name] = true))
    }

    readonly property string icon: !radio ? "󰖪" : !ssid ? "󰤭" : bars(signal)
    function bars(pct) { return ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"][Math.min(4, Math.floor(pct / 20))] }
    function secure(n) { return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe }

    function setRadio(on) { Networking.wifiEnabled = on }

    // The scanner only runs while someone is looking (the net panel). Kept as
    // wanted-state so it applies even if the device shows up later.
    property bool wantScan: false
    function setScanning(on) { wantScan = on }
    Binding {
        target: root.device
        property: "scannerEnabled"
        value: root.wantScan
        when: root.device !== null
    }

    function band(freq) { return freq < 3000 ? "2.4G" : freq < 5925 ? "5G" : "6G" }
    // "2.4G ch11" for a single-band SSID, "2.4/5G" when it broadcasts on several bands.
    function bandInfo(name) {
        const list = aps[name] ?? []
        const bands = [...new Set(list.map(a => band(a.freq)))]
        return bands.length === 1 ? `${bands[0]} ch${list[0].chan}` : bands.map(b => b.slice(0, -1)).join("/") + "G"
    }
    function rate(bps) {
        return bps >= 1048576 ? (bps / 1048576).toFixed(1) + " MB/s"
             : bps >= 1024 ? Math.round(bps / 1024) + " KB/s" : Math.round(bps) + " B/s"
    }

    // ── Detailed-only: everything below runs while the net panel is open ─────
    // Quickshell.Networking has no band/rate/IP, so: iw + nmcli, /sys counters, ping.
    property bool detailed: false
    readonly property string iface: device?.name ?? ""
    property var link: ({})          // { freq, chan, dbm, rx, tx (Mbit/s), ip, gw, dns, shared }
    property var aps: ({})           // ssid -> [{ chan, freq, signal }]
    readonly property int histLen: 60
    property var downHist: []        // bytes/s
    property var upHist: []
    property var pingHist: []        // ms, answered pings only
    property var pingLost: []        // bool per probe, for loss %
    readonly property real ping: avg(pingHist.slice(-10))
    // Mean change between consecutive pings (RFC 3550-style jitter).
    readonly property real jitter: { const p = pingHist.slice(-11); return avg(p.slice(1).map((v, i) => Math.abs(v - p[i]))) }
    readonly property int loss: pingLost.length ? Math.round(100 * pingLost.filter(x => x).length / pingLost.length) : 0

    function avg(a) { return a.length ? a.reduce((x, y) => x + y, 0) / a.length : 0 }
    function push(arr, v) { const a = arr.concat([v]); return a.length > histLen ? a.slice(a.length - histLen) : a }

    onDetailedChanged: { _prevBytes = null; pingHist = []; pingLost = []; downHist = []; upHist = [] }

    Process {
        id: info
        command: ["sh", "-c", "iw dev \"$1\" link; echo @@; nmcli -t -g IP4.ADDRESS,IP4.GATEWAY,IP4.DNS dev show \"$1\"; echo @@;"
                  + " nmcli -t -f IN-USE,CHAN,FREQ,SIGNAL,SSID dev wifi list ifname \"$1\" --rescan no", "sh", root.iface]
        stdout: StdioCollector {
            onStreamFinished: {
                const [iw, ip, list] = text.split("@@\n")
                const num = re => parseFloat((iw.match(re) ?? [])[1])
                const [addr, gw, dns] = (ip ?? "").split("\n")

                // nmcli -t escapes ':' and '\' in values; SSID is last so it may hold colons.
                const aps = {}, all = []
                let cur = null
                for (const l of (list ?? "").split("\n")) {
                    const f = l.split(":")
                    if (f.length < 5) continue
                    const ssid = f.slice(4).join(":").replace(/\\(.)/g, "$1")
                    const ap = { chan: parseInt(f[1]), freq: parseInt(f[2]), signal: parseInt(f[3]) }
                    all.push(ap)
                    if (f[0] === "*") cur = ap
                    if (ssid) (aps[ssid] = aps[ssid] ?? []).push(ap)
                }
                root.aps = aps
                root.link = {
                    freq: num(/freq: ([\d.]+)/), chan: cur?.chan ?? 0, dbm: num(/signal: (-?\d+)/),
                    rx: num(/rx bitrate: ([\d.]+)/), tx: num(/tx bitrate: ([\d.]+)/),
                    ip: addr?.split(" | ")[0] ?? "", gw: gw ?? "", dns: (dns ?? "").replace(/ \| /g, ", "),
                    shared: cur ? all.filter(a => a !== cur && a.chan === cur.chan).length : 0
                }
            }
        }
    }
    Timer {
        interval: 3000
        running: root.detailed && root.iface !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: info.running = true
    }

    // Throughput: byte counters, 1s deltas.
    FileView { id: rxFile; path: root.iface ? `/sys/class/net/${root.iface}/statistics/rx_bytes` : ""; blockLoading: true }
    FileView { id: txFile; path: root.iface ? `/sys/class/net/${root.iface}/statistics/tx_bytes` : ""; blockLoading: true }
    property var _prevBytes: null
    Timer {
        interval: 1000
        running: root.detailed && root.iface !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            rxFile.reload(); txFile.reload()
            const now = { t: Date.now(), rx: parseInt(rxFile.text()), tx: parseInt(txFile.text()) }
            if (isNaN(now.rx) || isNaN(now.tx)) return
            const p = root._prevBytes
            if (p && now.t > p.t && now.rx >= p.rx && now.tx >= p.tx) {
                const dt = (now.t - p.t) / 1000
                root.downHist = root.push(root.downHist, (now.rx - p.rx) / dt)
                root.upHist = root.push(root.upHist, (now.tx - p.tx) / dt)
            }
            root._prevBytes = now
        }
    }

    // Latency: one long-lived ping to the gateway. -O reports unanswered probes as lost.
    // ponytail: gw change while the panel is open keeps pinging the old one until reopened.
    Process {
        running: root.detailed && !!root.link.gw
        command: ["ping", "-n", "-O", "-i", "1", "-W", "1", root.link.gw ?? ""]
        stdout: SplitParser {
            onRead: line => {
                const m = line.match(/time=([\d.]+)/)
                if (m) root.pingHist = root.push(root.pingHist, parseFloat(m[1]))
                if (m || line.includes("no answer")) root.pingLost = root.push(root.pingLost, !m)
            }
        }
    }
}

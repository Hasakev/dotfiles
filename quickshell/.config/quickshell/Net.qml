pragma Singleton
import QtQuick
import Quickshell
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
}

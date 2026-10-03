pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Bluetooth

// Glyph pickers shared by the bar, panels and OSD.
Singleton {
    function weather(desc) {
        const d = (desc || "").toLowerCase()
        if (!d) return "󰖐"
        if (d.includes("thunder")) return "󰖓"
        if (d.includes("snow") || d.includes("sleet")) return "󰖘"
        if (d.includes("rain") || d.includes("drizzle") || d.includes("shower")) return "󰖗"
        if (d.includes("fog") || d.includes("mist") || d.includes("haze")) return "󰖑"
        if (d.includes("partly")) return "󰖕"
        if (d.includes("cloud") || d.includes("overcast")) return "󰖐"
        return "󰖙"
    }

    function volume(node, vol, muted) {
        const bt = (node?.name ?? "").startsWith("bluez")
        if (muted) return bt ? "󰂲" : "󰖁"
        if (bt) return "󰂰"
        return vol < 0.34 ? "󰕿" : vol < 0.67 ? "󰖀" : "󰕾"
    }

    // Focused window on this monitor, else the newest one on its workspace.
    function focused(mon) {
        const t = Hyprland.activeToplevel
        if (t && t.workspace?.monitor === mon) return t
        const tops = mon?.activeWorkspace?.toplevels?.values ?? []
        return tops[tops.length - 1] ?? null
    }
    function title(mon) { return focused(mon)?.title || "Desktop" }

    // Theme icon for a window, via its desktop entry ("" if none found).
    function appIcon(t) {
        const id = t?.wayland?.appId || t?.lastIpcObject?.class || ""
        const e = id ? DesktopEntries.heuristicLookup(id) : null
        return e?.icon ? (e.icon.startsWith("/") ? "file://" + e.icon : Quickshell.iconPath(e.icon, true)) : ""
    }

    function focusWindow(t) {
        const a = String(t.address)
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${a.startsWith("0x") ? a : "0x" + a}" })`)
    }

    function btOn() { return Bluetooth.defaultAdapter?.enabled ?? false }
    function btConnected() { return Bluetooth.devices.values.find(d => d.connected) ?? null }
}

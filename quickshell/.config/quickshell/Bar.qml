import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Widgets

// One bar per screen. The window is taller than the bar so popouts can grow
// out of it; the input mask keeps the empty part click-through.
PanelWindow {
    id: bar

    required property ShellScreen modelData
    screen: modelData
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property bool compact: width < 1400   // portrait DP-1

    anchors { top: true; left: true; right: true }
    // Only as tall as the bar unless a popout is open (or still closing):
    // Hyprland recomposites and re-blurs the whole surface on every redraw.
    readonly property bool expanded: panel !== "" || shrinkDelay.running
    implicitHeight: expanded ? 760 : Theme.gap + Theme.barHeight + 4
    Timer { id: shrinkDelay; interval: 350 }
    onPanelChanged: if (panel === "") shrinkDelay.restart()
    exclusiveZone: Theme.barHeight + Theme.gap
    color: "transparent"
    WlrLayershell.namespace: "quickshell:bar"
    WlrLayershell.layer: WlrLayer.Top
    // Keyboard only while a panel wants it (launcher typing, wifi password).
    WlrLayershell.keyboardFocus: panel === "launcher" ? WlrKeyboardFocus.Exclusive
        : panel !== "" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: Region {
        Region { item: leftIsland }
        Region { item: centerIsland }
        Region { item: rightIsland }
        Region { item: popout }
    }

    // ── Popout state ────────────────────────────────────────────────────────
    property string panel: ""          // open panel name, "" = closed
    property string shown: ""          // last panel, kept while it animates out
    property real anchorX: 0
    property real anchorW: 0

    function toggle(name, item) {
        if (panel === name) { panel = ""; return }
        const p = item.mapToItem(bar.contentItem, 0, 0)
        anchorX = p.x
        anchorW = item.width
        shown = name
        panel = name
    }
    // For IPC/keybinds: open a panel from its bar pill.
    property string launcherSeed: ""   // pre-filled launcher query (";" = clipboard)
    function toggleByName(name) {
        launcherSeed = name === "clipboard" ? ";" : ""
        if (name === "clipboard") name = "launcher"
        const item = ({ media: mediaPill, mixer: audioPill, net: netPill, calendar: clockPill, weather: weatherPill, sys: sysPill, launcher: launcherPill, windows: titlePill, power: powerPill, notifs: notifPill })[name]
        if (item) toggle(name, item)
    }

    HyprlandFocusGrab {
        windows: [bar]
        // Arm only once the surface has grown: grabbing while the layer
        // surface is mid-resize gets the grab cleared instantly (panel never opened).
        active: bar.panel !== "" && bar.height > Theme.barHeight + 50
        onCleared: bar.panel = ""
    }

    // ── Bar: three islands ─────────────────────────────────────────────────
    // Values in ink, icons muted, accent only for "this is on/open".
    component Sep: Rectangle {
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        width: 1; height: 14
        color: Theme.hairline
    }
    component Icon: Label {
        icon: true
        font.pixelSize: 14
        color: Theme.overlay2
    }

    Island {
        id: leftIsland
        x: 12
        y: Theme.gap
        ignition: 0

        Pill {
            id: launcherPill
            active: bar.panel === "launcher"
            onClicked: b => b === Qt.RightButton ? Quickshell.execDetached(["kitty", "-e", "yazi"]) : bar.toggle("launcher", launcherPill)
            Icon { text: "󱄅"; font.pixelSize: 15; color: launcherPill.active || launcherPill.hovered ? Theme.accent : Theme.subtext0 }
        }

        Workspaces { monitor: bar.monitor }

        Pill {
            id: titlePill
            readonly property var win: Icons.focused(bar.monitor)
            readonly property string iconSrc: Icons.appIcon(win)
            padding: 10
            active: bar.panel === "windows"
            onClicked: bar.toggle("windows", titlePill)
            IconImage {
                anchors.verticalCenter: parent.verticalCenter
                visible: titlePill.iconSrc !== ""
                source: titlePill.iconSrc
                implicitSize: 16
            }
            Label {
                visible: !bar.compact
                text: Icons.title(bar.monitor)
                color: titlePill.active ? Theme.accent : Theme.subtext0
                font.weight: Font.Normal
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 320)
            }
        }
    }

    Island {
        id: centerIsland
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.gap
        ignition: 120

        Pill {
            id: clockPill
            active: bar.panel === "calendar"
            padding: 12
            property bool short: bar.compact
            onClicked: b => b === Qt.RightButton ? short = !short : bar.toggle("calendar", clockPill)

            // A neon sign that glitches now and then. Deliberately not an
            // infinite animation: those keep every bar redrawing at 60fps
            // (measured: 12% of a core idle -> ~1%).
            Timer {
                interval: 40000
                running: true
                repeat: true
                onTriggered: { interval = 25000 + Math.random() * 35000; if (!clockPill.hovered) glitch.restart() }
            }
            SequentialAnimation {
                id: glitch
                NumberAnimation { target: clockPill; property: "opacity"; to: 0.35; duration: 45 }
                NumberAnimation { target: clockPill; property: "opacity"; to: 1; duration: 35 }
                PauseAnimation { duration: 90 }
                NumberAnimation { target: clockPill; property: "opacity"; to: 0.55; duration: 30 }
                NumberAnimation { target: clockPill; property: "opacity"; to: 1; duration: 160 }
            }

            Label {
                visible: !clockPill.short
                text: Qt.formatDateTime(clock.date, "ddd d MMM")
                color: Theme.subtext0
                font.weight: Font.Normal
            }
            Label {
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: clockPill.active ? Theme.accent : Theme.text
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
        }

        Sep {}

        Pill {
            id: weatherPill
            active: bar.panel === "weather"
            onClicked: bar.toggle("weather", weatherPill)
            Icon { text: Icons.weather(Weather.desc); color: weatherPill.active ? Theme.accent : Theme.overlay2 }
            Label { text: Weather.temp.replace("C", ""); color: Theme.subtext1 }
        }
    }

    Island {
        id: rightIsland
        anchors.right: parent.right
        anchors.rightMargin: 12
        y: Theme.gap
        ignition: 240

        MediaPill {
            id: mediaPill
            bar: bar
            visible: Player.active !== null && !bar.compact
        }
        Sep { visible: mediaPill.visible }

        Pill {
            id: audioPill
            readonly property PwNode sink: Pipewire.defaultAudioSink
            readonly property PwNode src: Pipewire.defaultAudioSource
            readonly property real vol: sink?.audio?.volume ?? 0
            readonly property bool muted: sink?.audio?.muted ?? true
            readonly property bool micMuted: src?.audio?.muted ?? false
            active: bar.panel === "mixer"
            onClicked: b => {
                if (b === Qt.RightButton) sink.audio.muted = !muted
                else if (b === Qt.MiddleButton) {   // cycle output device
                    const sinks = Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
                    Pipewire.preferredDefaultAudioSink = sinks[(sinks.indexOf(sink) + 1) % sinks.length]
                }
                else bar.toggle("mixer", audioPill)
            }
            onScrolled: s => { if (sink) sink.audio.volume = Math.max(0, Math.min(1.5, vol + s * 0.05)) }

            Icon { text: Icons.volume(audioPill.sink, audioPill.vol, audioPill.muted); color: audioPill.active ? Theme.accent : Theme.overlay2 }
            Label {
                text: audioPill.muted ? "muted" : Math.round(audioPill.vol * 100)
                color: audioPill.muted ? Theme.overlay1 : Theme.text
            }
            // Mic only earns a spot when it's muted.
            Icon { visible: audioPill.micMuted; text: "󰍭"; color: Theme.alert }
        }

        Pill {
            id: netPill
            active: bar.panel === "net"
            onClicked: b => b === Qt.RightButton ? Quickshell.execDetached(["kitty", "-e", "nmtui"]) : bar.toggle("net", netPill)

            Icon { text: Net.icon; color: !Net.ssid ? Theme.alert : netPill.active ? Theme.accent : Theme.overlay2 }
            Label {
                visible: !Net.ssid || netPill.hovered
                text: Net.ssid || "offline"
                color: Net.ssid ? Theme.subtext1 : Theme.alert
            }
        }

        // Left: Bluetooth settings (blueman). Right: adapter power.
        Pill {
            id: btPill
            readonly property var dev: Icons.btConnected()
            visible: !!Bluetooth.defaultAdapter
            onClicked: b => b === Qt.RightButton ? Bluetooth.defaultAdapter.enabled = !Icons.btOn() : Quickshell.execDetached(["blueman-manager"])
            Icon {
                text: !Icons.btOn() ? "󰂲" : btPill.dev ? "󰂱" : "󰂯"
                color: btPill.dev || btPill.hovered ? Theme.accent : Icons.btOn() ? Theme.overlay2 : Theme.overlay0
            }
            Label {
                visible: !!btPill.dev && btPill.hovered
                text: btPill.dev ? btPill.dev.name + (btPill.dev.batteryAvailable ? ` · ${Math.round(btPill.dev.battery * 100)}%` : "") : ""
                color: Theme.subtext1
            }
        }

        Pill {
            id: sysPill
            active: bar.panel === "sys"
            onClicked: b => b === Qt.RightButton ? Quickshell.execDetached(["kitty", "-e", "btop"]) : bar.toggle("sys", sysPill)

            Icon { text: "󰍛"; color: sysPill.active ? Theme.accent : Theme.overlay2 }
            Label { text: Math.round(Sys.cpu * 100) + "%"; color: Theme.text }
            Label { visible: sysPill.hovered; text: Sys.memUsed.toFixed(1) + "G"; color: Theme.subtext0 }
            Label {
                readonly property bool hot: Sys.temp >= 80
                visible: sysPill.hovered || hot
                text: Sys.temp + "°"
                color: hot ? Theme.alert : Theme.subtext0
            }
        }

        Pill {
            id: awakePill
            onClicked: Sys.awake = !Sys.awake
            Icon { text: Sys.awake ? "󰅶" : "󰾪"; color: Sys.awake ? Theme.accent : awakePill.hovered ? Theme.subtext0 : Theme.overlay0 }
        }

        Sep { visible: trayPill.visible }

        Pill {
            id: trayPill
            visible: SystemTray.items.values.length > 0
            padding: 8
            Repeater {
                model: SystemTray.items
                delegate: IconImage {
                    id: trayIcon
                    required property SystemTrayItem modelData
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 15
                    // Greyscale until hovered, so app colours don't fight the palette.
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        saturation: trayMouse.containsMouse ? 0 : -1
                        brightness: trayMouse.containsMouse ? 0 : -0.1
                        Behavior on saturation { NumberAnimation { duration: 200 } }
                    }
                    source: {
                        const i = modelData.icon
                        if (!i.includes("?path=")) return i
                        const [name, path] = i.split("?path=")
                        return `file://${path}/${name.slice(name.lastIndexOf("/") + 1)}`
                    }
                    MouseArea {
                        id: trayMouse
                        anchors.fill: parent
                        anchors.margins: -3
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: m => {
                            const it = trayIcon.modelData
                            if (m.button === Qt.MiddleButton) it.secondaryActivate()
                            else if (m.button === Qt.RightButton || it.onlyMenu) {
                                if (it.hasMenu) {
                                    const p = trayIcon.mapToItem(bar.contentItem, 0, trayIcon.height + 10)
                                    it.display(bar, p.x, p.y)
                                }
                            } else it.activate()
                        }
                    }
                }
            }
        }

        Pill {
            id: notifPill
            active: bar.panel === "notifs"
            onClicked: b => b === Qt.RightButton ? Notifs.dnd = !Notifs.dnd : bar.toggle("notifs", notifPill)
            Item {
                width: bell.implicitWidth
                height: bell.implicitHeight
                anchors.verticalCenter: parent.verticalCenter
                Icon {
                    id: bell
                    text: Notifs.dnd ? "󰂛" : "󰂚"
                    color: notifPill.active ? Theme.accent : Notifs.dnd ? Theme.overlay0 : Theme.overlay2
                }
                // Unread dot.
                Rectangle {
                    visible: Notifs.history.length > 0 && !Notifs.dnd
                    x: bell.width - 5; y: 1
                    width: 7; height: 7; radius: 4
                    color: Theme.accent
                    border.width: 1.5
                    border.color: Theme.base
                }
            }
        }

        Pill {
            id: powerPill
            active: bar.panel === "power"
            onClicked: b => b === Qt.RightButton ? Quickshell.execDetached(["systemctl", "suspend"]) : bar.toggle("power", powerPill)
            Icon { text: "󰐥"; color: powerPill.active || powerPill.hovered ? Theme.alert : Theme.overlay2 }
        }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // ── Morphing popout ─────────────────────────────────────────────────────
    // Closed, it's collapsed onto the pill that opened it; open, it springs
    // to the panel's size. Switching panels slides/resizes it in place.
    Rectangle {
        id: popout

        readonly property bool open: bar.panel !== ""
        readonly property real pad: 14
        readonly property real targetW: (loader.item?.implicitWidth ?? 0) + pad * 2
        readonly property real targetH: (loader.item?.implicitHeight ?? 0) + pad * 2

        x: open ? Math.max(12, Math.min(bar.width - 12 - targetW, bar.anchorX + bar.anchorW / 2 - targetW / 2)) : bar.anchorX
        y: Theme.gap + Theme.barHeight + 8
        width: open ? targetW : bar.anchorW
        height: open ? targetH : 0
        opacity: open ? 1 : 0
        visible: opacity > 0
        clip: true
        radius: Theme.radius
        // Solid: Hyprland blends in linear light, so even 6% transparency lets
        // bright text behind show at ~20% perceived brightness.
        color: Theme.base
        border.width: 1
        border.color: Theme.hairline

        Behavior on x { NumberAnimation { duration: 420; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
        Behavior on width { NumberAnimation { duration: 420; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
        Behavior on height { NumberAnimation { duration: popout.open ? 460 : 220; easing.type: popout.open ? Easing.BezierSpline : Easing.InCubic; easing.bezierCurve: Theme.spring } }
        Behavior on opacity { NumberAnimation { duration: popout.open ? 120 : 260 } }

        // Lamp-lit edge where it leaves the bar.
        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.4
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: Theme.a(Theme.accent, 0.55) }
                GradientStop { position: 1; color: "transparent" }
            }
        }

        Loader {
            id: loader
            x: popout.pad
            y: popout.pad
            source: bar.shown ? bar.shown[0].toUpperCase() + bar.shown.slice(1) + "Panel.qml" : ""
            onLoaded: {
                item.opacity = 0; fadeIn.restart()
                if (item.seed !== undefined) item.seed = bar.launcherSeed
                if (item.monitor !== undefined) item.monitor = bar.monitor
            }
            Connections {
                target: loader.item
                ignoreUnknownSignals: true
                function onCloseRequested() { bar.panel = "" }
            }
            NumberAnimation { id: fadeIn; target: loader.item; property: "opacity"; to: 1; duration: 260; easing.type: Easing.OutCubic }
        }
    }
}

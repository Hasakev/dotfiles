import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

// Volume / mic-mute OSD on the focused screen. Click-through overlay that
// springs up from the bottom edge and sinks away after a moment.
PanelWindow {
    id: osd

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    property bool shown: false
    property bool mic: false        // last change was the mic mute
    property bool armed: false      // ignore the initial property burst

    screen: Quickshell.screens.find(s => Hyprland.monitorFor(s) === Hyprland.focusedMonitor) ?? null
    anchors.bottom: true
    margins.bottom: 70
    implicitWidth: 320
    implicitHeight: 64
    exclusiveZone: 0
    color: "transparent"
    mask: Region {}
    WlrLayershell.namespace: "quickshell:osd"
    WlrLayershell.layer: WlrLayer.Overlay

    function show(isMic) {
        if (!armed) return
        mic = isMic
        shown = true
        hide.restart()
    }
    Timer { interval: 1500; running: true; onTriggered: osd.armed = true }
    Timer { id: hide; interval: 1400; onTriggered: osd.shown = false }

    Connections {
        target: osd.sink?.audio ?? null
        function onVolumeChanged() { osd.show(false) }
        function onMutedChanged() { osd.show(false) }
    }
    Connections {
        target: osd.source?.audio ?? null
        function onMutedChanged() { osd.show(true) }
    }

    Rectangle {
        id: card
        readonly property real vol: osd.sink?.audio?.volume ?? 0
        readonly property bool muted: osd.mic ? (osd.source?.audio?.muted ?? true) : (osd.sink?.audio?.muted ?? true)
        readonly property color accent: osd.mic ? Theme.magenta : vol > 1 ? Theme.amber : Theme.blue

        width: parent.width
        height: 48
        radius: 24
        y: osd.shown ? 8 : 70
        opacity: osd.shown ? 1 : 0
        scale: osd.shown ? 1 : 0.85
        color: Theme.base   // solid: see popout note in Bar.qml
        border.width: 1
        border.color: Theme.hairline
        Behavior on y { NumberAnimation { duration: osd.shown ? 380 : 300; easing.type: osd.shown ? Easing.OutBack : Easing.InCubic } }
        Behavior on opacity { NumberAnimation { duration: 220 } }
        Behavior on scale { NumberAnimation { duration: 380; easing.type: Easing.OutBack } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        Label {
            id: icon
            icon: true
            x: 18
            anchors.verticalCenter: parent.verticalCenter
            text: osd.mic ? (card.muted ? "󰍭" : "󰍬") : Icons.volume(osd.sink, card.vol, card.muted)
            color: card.muted ? Theme.overlay1 : card.accent
            font.pixelSize: 20
        }

        Item {
            anchors.left: icon.right; anchors.leftMargin: 14
            anchors.right: pct.left; anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            height: 6

            Rectangle { anchors.fill: parent; radius: 3; color: Theme.a(Theme.surface1, 0.8) }
            Rectangle {
                height: parent.height
                radius: 3
                width: parent.width * (osd.mic ? (card.muted ? 0 : 1) : Math.min(1, card.vol))
                opacity: card.muted ? 0.3 : 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Theme.a(card.accent, 0.5) }
                    GradientStop { position: 1; color: card.accent }
                }
                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Rectangle {   // hot tip
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12; height: 12; radius: 6
                    color: Theme.a(card.accent, 0.35)
                    visible: !card.muted && parent.width > 0
                }
            }
        }

        Label {
            id: pct
            anchors.right: parent.right; anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            horizontalAlignment: Text.AlignRight
            text: card.muted ? "off" : osd.mic ? "on" : Math.round(card.vol * 100) + "%"
            color: card.muted ? Theme.overlay1 : card.accent
            font.weight: Font.Bold
        }
    }
}

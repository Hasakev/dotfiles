import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Now-playing pill with a live cava spectrum.
// Left: media panel · Middle: play/pause · Right: next · Scroll: prev/next
Pill {
    id: root

    required property var bar
    readonly property MprisPlayer p: Player.active

    active: bar.panel === "media"
    onClicked: b => {
        if (b === Qt.MiddleButton) p.togglePlaying()
        else if (b === Qt.RightButton) p.next()
        else bar.toggle("media", root)
    }
    onScrolled: s => s > 0 ? p.previous() : p.next()

    Label {
        text: (root.p?.dbusName ?? "").includes("spotify") ? "󰓇" : root.p?.isPlaying ? "󰐊" : "󰏤"
        icon: true
        color: root.active ? Theme.accent : Theme.overlay2
        font.pixelSize: 14
    }

    Label {
        text: root.p?.trackTitle || "Nothing playing"
        color: root.p?.isPlaying ? Theme.subtext1 : Theme.overlay1
        font.weight: Font.Normal
        elide: Text.ElideRight
        width: Math.min(implicitWidth, 150)
    }

    // Spectrum: thin bars that grow from the centre line.
    Row {
        anchors.verticalCenter: parent.verticalCenter
        height: 16
        spacing: 2
        visible: root.p?.isPlaying ?? false
        Repeater {
            model: 12   // loudest of each group of 4 cava bands
            delegate: Rectangle {
                required property int index
                readonly property real v: Math.max(...Cava.bars.slice(index * 4, index * 4 + 4), 0)
                anchors.verticalCenter: parent.verticalCenter
                width: 2
                radius: 1
                height: 2 + 14 * v
                color: Theme.a(Player.artColor, 0.35 + 0.65 * v)
                Behavior on height { NumberAnimation { duration: 60 } }
            }
        }
    }
}

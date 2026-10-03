import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire

// Mixer: output device picker + volume, per-app streams, microphone.
Item {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio)
    readonly property var streams: linkTracker.linkGroups.map(g => g.source).filter(n => n && n.isStream)

    implicitWidth: 340
    implicitHeight: col.implicitHeight

    PwNodeLinkTracker { id: linkTracker; node: root.sink }
    PwObjectTracker { objects: [...root.sinks, ...root.sources, ...root.streams] }

    component Section: Label {
        color: Theme.overlay1
        font.pixelSize: 10
        font.weight: Font.Bold
        font.letterSpacing: 1.5
    }

    component Channel: Row {
        id: ch
        required property PwNode node
        property string icon: ""
        property string iconName: ""
        property string name: ""
        property color accent: Theme.blue
        readonly property bool muted: node?.audio?.muted ?? false
        width: parent.width
        spacing: 10

        Item {
            width: 28; height: 28
            anchors.verticalCenter: parent.verticalCenter
            IconImage {
                anchors.fill: parent
                visible: ch.iconName !== ""
                source: ch.iconName ? Quickshell.iconPath(ch.iconName, true) : ""
            }
            IconButton {
                anchors.centerIn: parent
                visible: ch.iconName === ""
                text: ch.muted ? "󰖁" : ch.icon
                accent: ch.accent
                onClicked: ch.node.audio.muted = !ch.muted
            }
        }
        Column {
            width: parent.width - 38 - 44
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Label { width: parent.width; text: ch.name; elide: Text.ElideRight; color: ch.muted ? Theme.overlay1 : Theme.subtext1; font.pixelSize: 11 }
            NeonSlider {
                width: parent.width
                accent: ch.accent
                dim: ch.muted
                value: ch.node?.audio?.volume ?? 0
                onMoved: v => ch.node.audio.volume = v
            }
        }
        Label {
            width: 34
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: Math.round((ch.node?.audio?.volume ?? 0) * 100) + "%"
            color: ch.muted ? Theme.overlay0 : ch.accent
            font.pixelSize: 11
        }
    }

    // Device list: the current one is highlighted; click another to make it default.
    component DevicePicker: Column {
        id: picker
        property var devices: []
        property var current: null
        signal picked(var node)
        width: parent.width
        spacing: 2
        visible: devices.length > 1
        Repeater {
            model: picker.devices
            delegate: Rectangle {
                id: dev
                required property PwNode modelData
                readonly property bool cur: modelData === picker.current
                width: picker.width
                height: 26
                radius: 6
                color: cur ? Theme.a(Theme.accent, 0.12) : hov.containsMouse ? Theme.a(Theme.text, 0.06) : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
                Label {
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 20
                    elide: Text.ElideRight
                    text: dev.modelData.description || dev.modelData.name
                    color: dev.cur ? Theme.accent : Theme.overlay2
                    font.pixelSize: 11
                }
                MouseArea {
                    id: hov
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: picker.picked(dev.modelData)
                }
            }
        }
    }

    Column {
        id: col
        width: parent.width
        spacing: 10

        Section { text: "OUTPUT" }
        Channel {
            node: root.sink
            icon: Icons.volume(root.sink, root.sink?.audio?.volume ?? 0, false)
            name: root.sink?.description || root.sink?.name || "No output"
        }

        DevicePicker {
            devices: root.sinks
            current: root.sink
            onPicked: n => Pipewire.preferredDefaultAudioSink = n
        }

        Section { text: "APPS"; visible: root.streams.length > 0 }
        Repeater {
            model: root.streams
            delegate: Channel {
                required property PwNode modelData
                node: modelData
                accent: Theme.teal
                icon: "󰎆"
                iconName: modelData.properties["application.icon-name"] ?? ""
                name: modelData.properties["application.name"] || modelData.description || modelData.name
            }
        }

        Section { text: "MICROPHONE" }
        Channel {
            node: root.source
            icon: (root.source?.audio?.muted ?? false) ? "󰍭" : "󰍬"
            name: root.source?.description || root.source?.name || "No input"
        }
        DevicePicker {
            devices: root.sources
            current: root.source
            onPicked: n => Pipewire.preferredDefaultAudioSource = n
        }
    }
}

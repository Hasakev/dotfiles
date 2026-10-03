import QtQuick
import Quickshell

// System monitor: CPU / RAM / temp history, per-core load, GPU, top processes.
Item {
    id: root

    implicitWidth: 440
    implicitHeight: col.implicitHeight

    Component.onCompleted: Sys.detailed = true
    Component.onDestruction: Sys.detailed = false

    function tempColor(t) { return t >= 80 ? Theme.red : t >= 65 ? Theme.amber : Theme.green }

    component Card: Rectangle {
        id: card
        default property alias content: inner.data
        property string title
        property string value
        property string sub
        property color accent: Theme.cyan
        radius: 10
        color: Theme.a(Theme.surface0, 0.6)
        border.width: 1
        border.color: Theme.hairline
        implicitHeight: inner.y + inner.implicitHeight + 10

        Label { id: t; x: 12; y: 10; text: card.title; color: Theme.overlay1; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.5 }
        Label { anchors.right: parent.right; anchors.rightMargin: 12; y: 6; text: card.value; color: card.accent; font.pixelSize: 18; font.weight: Font.DemiBold }
        Label { x: 12; y: 26; text: card.sub; color: Theme.overlay2; font.pixelSize: 10; visible: text !== "" }
        Column {
            id: inner
            x: 12
            y: card.sub ? 44 : 34
            width: card.width - 24
            spacing: 6
        }
    }

    Column {
        id: col
        width: parent.width
        spacing: 8

        Card {
            width: parent.width
            title: "CPU"
            value: Math.round(Sys.cpu * 100) + "%"
            accent: Theme.cyan
            Spark { width: parent.width; height: 50; values: Sys.cpuHist; accent: Theme.cyan }
            // Per-core load, bars grow from the bottom.
            Row {
                width: parent.width
                height: 22
                spacing: 3
                Repeater {
                    model: Sys.cores.length
                    delegate: Item {
                        required property int index
                        readonly property real v: Sys.cores[index] ?? 0
                        width: (parent.width - (Sys.cores.length - 1) * 3) / Sys.cores.length
                        height: parent.height
                        Rectangle { anchors.fill: parent; radius: 2; color: Theme.a(Theme.surface1, 0.7) }
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: Math.max(2, parent.height * parent.v)
                            radius: 2
                            color: parent.v > 0.85 ? Theme.red : parent.v > 0.5 ? Theme.amber : Theme.cyan
                            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }
                    }
                }
            }
        }

        Row {
            width: parent.width
            spacing: 8
            Card {
                width: (parent.width - 8) / 2
                title: "MEMORY"
                value: Sys.memUsed.toFixed(1) + "G"
                sub: `of ${Sys.memTotal.toFixed(0)}G · swap ${Sys.swapUsed.toFixed(1)}G`
                accent: Theme.teal
                Spark { width: parent.width; height: 40; values: Sys.memHist; accent: Theme.teal }
            }
            Card {
                width: (parent.width - 8) / 2
                title: "CPU TEMP"
                value: Sys.temp + "°"
                sub: "k10temp"
                accent: root.tempColor(Sys.temp)
                Spark { width: parent.width; height: 40; values: Sys.tempHist; max: 100; accent: root.tempColor(Sys.temp) }
            }
        }

        Card {
            width: parent.width
            visible: Sys.gpu !== null
            title: "GPU"
            value: Math.round((Sys.gpu?.util ?? 0) * 100) + "%"
            sub: `${(Sys.gpu?.memUsed ?? 0).toFixed(1)} / ${(Sys.gpu?.memTotal ?? 0).toFixed(0)}G VRAM · ${Sys.gpu?.temp ?? 0}° · ${Math.round(Sys.gpu?.power ?? 0)}W`
            accent: Theme.green
            Repeater {
                model: [["util", Sys.gpu?.util ?? 0], ["vram", (Sys.gpu?.memUsed ?? 0) / (Sys.gpu?.memTotal || 1)]]
                delegate: Row {
                    required property var modelData
                    spacing: 8
                    Label { width: 30; text: modelData[0]; color: Theme.overlay1; font.pixelSize: 10 }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: col.width - 24 - 38; height: 4; radius: 2
                        color: Theme.a(Theme.surface1, 0.8)
                        Rectangle {
                            width: parent.width * Math.min(1, modelData[1]); height: 4; radius: 2
                            color: Theme.green
                            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
        }

        Card {
            width: parent.width
            title: "PROCESSES"
            accent: Theme.blue
            Repeater {
                model: Sys.procs
                delegate: Rectangle {
                    id: proc
                    required property var modelData
                    width: parent.width
                    height: 24
                    radius: 6
                    color: hov.hovered ? Theme.a(Theme.red, 0.1) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    HoverHandler { id: hov }   // passive: stays hovered over the kill button

                    Label { x: 6; anchors.verticalCenter: parent.verticalCenter; width: 200; elide: Text.ElideRight; text: proc.modelData.name; color: Theme.subtext1; font.pixelSize: 11 }
                    Label { x: 220; anchors.verticalCenter: parent.verticalCenter; width: 60; horizontalAlignment: Text.AlignRight; text: proc.modelData.cpu.toFixed(0) + "%"; color: proc.modelData.cpu > 50 ? Theme.amber : Theme.cyan; font.pixelSize: 11 }
                    Label { x: 290; anchors.verticalCenter: parent.verticalCenter; width: 50; horizontalAlignment: Text.AlignRight; text: proc.modelData.mem.toFixed(1) + "%"; color: Theme.teal; font.pixelSize: 11 }

                    // Kill button fades in on hover (SIGTERM).
                    IconButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰅖"
                        size: 12
                        accent: Theme.red
                        opacity: hov.hovered ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                        onClicked: Sys.kill(proc.modelData.pid)
                    }
                }
            }
        }

        Row {
            anchors.right: parent.right
            spacing: 6
            IconButton { text: "󰄪"; size: 13; accent: Theme.cyan; onClicked: Quickshell.execDetached(["kitty", "-e", "btop"]) }
        }
    }
}

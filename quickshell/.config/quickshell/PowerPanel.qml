import QtQuick
import Quickshell

// Session actions. Lock and suspend fire on click; log out, reboot and
// shut down need a ~0.8s press-and-hold (the tile fills while you hold).
Item {
    id: root

    signal closeRequested()

    readonly property var actions: [
        { glyph: "󰌾", label: "Lock",      hold: false, cmd: ["hyprlock"] },
        { glyph: "󰤄", label: "Suspend",   hold: false, cmd: ["systemctl", "suspend"] },
        { glyph: "󰍃", label: "Log out",   hold: true,  cmd: ["sh", "-c", "command -v hyprshutdown >/dev/null && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"] },
        { glyph: "󰜉", label: "Reboot",    hold: true,  cmd: ["systemctl", "reboot"] },
        { glyph: "󰐥", label: "Shut down", hold: true,  cmd: ["systemctl", "poweroff"] }
    ]

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight + hint.implicitHeight + 10

    function run(a) { root.closeRequested(); Quickshell.execDetached(a.cmd) }

    Row {
        id: row
        spacing: 8

        Repeater {
            model: root.actions
            delegate: Rectangle {
                id: tile
                required property var modelData
                required property int index
                readonly property bool danger: modelData.hold
                readonly property color tint: danger ? Theme.alert : Theme.accent
                property real progress: 0

                width: 78
                height: 86
                radius: 12
                clip: true
                color: mouse.containsMouse ? Theme.a(tint, 0.1) : Theme.a(Theme.text, 0.04)
                Behavior on color { ColorAnimation { duration: 150 } }
                scale: mouse.pressed ? 0.96 : 1
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                // Tiles rise in one after another when the panel opens.
                opacity: 0
                transform: Translate { id: rise; y: 8 }
                Component.onCompleted: enter.start()
                ParallelAnimation {
                    id: enter
                    SequentialAnimation {
                        PauseAnimation { duration: tile.index * 40 }
                        ParallelAnimation {
                            NumberAnimation { target: tile; property: "opacity"; to: 1; duration: 220 }
                            NumberAnimation { target: rise; property: "y"; to: 0; duration: 320; easing.type: Easing.OutCubic }
                        }
                    }
                }

                // Hold fill
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: parent.height * tile.progress
                    color: Theme.a(tile.tint, 0.28)
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        icon: true
                        text: tile.modelData.glyph
                        font.pixelSize: 22
                        color: mouse.containsMouse ? tile.tint : Theme.subtext1
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tile.modelData.label
                        font.pixelSize: 11
                        color: mouse.containsMouse ? Theme.text : Theme.subtext0
                    }
                }

                NumberAnimation {
                    id: fill
                    target: tile
                    property: "progress"
                    to: 1
                    duration: 800
                    onFinished: if (tile.progress >= 1) root.run(tile.modelData)
                }
                NumberAnimation { id: drain; target: tile; property: "progress"; to: 0; duration: 200; easing.type: Easing.OutCubic }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: if (tile.danger) { drain.stop(); fill.start() }
                    onReleased: if (tile.danger) { fill.stop(); drain.start() }
                    onCanceled: if (tile.danger) { fill.stop(); drain.start() }
                    onClicked: if (!tile.danger) root.run(tile.modelData)
                }
            }
        }
    }

    Label {
        id: hint
        anchors.top: row.bottom
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Hold to log out, reboot or shut down"
        color: Theme.overlay1
        font.pixelSize: 10
    }
}

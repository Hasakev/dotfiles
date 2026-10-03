import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets

// Every window on this monitor, grouped by workspace. Click to jump to it.
Item {
    id: root

    signal closeRequested()
    property var monitor: null

    readonly property var groups: Hyprland.workspaces.values
        .filter(w => w.id > 0 && w.monitor === monitor && w.toplevels.values.length > 0)
        .sort((a, b) => a.id - b.id)

    implicitWidth: 360
    implicitHeight: Math.max(col.implicitHeight, 40)

    Label {
        visible: root.groups.length === 0
        anchors.centerIn: parent
        text: "No windows here"
        color: Theme.overlay1
    }

    Column {
        id: col
        width: parent.width
        spacing: 4

        Repeater {
            model: root.groups
            delegate: Column {
                id: grp
                required property var modelData
                width: col.width
                spacing: 2

                Label {
                    text: "WORKSPACE " + grp.modelData.id
                    color: grp.modelData.active ? Theme.accent : Theme.overlay1
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 1.5
                    topPadding: 6
                    bottomPadding: 2
                }

                Repeater {
                    model: grp.modelData.toplevels.values
                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        readonly property bool cur: modelData === Hyprland.activeToplevel
                        readonly property string iconSrc: Icons.appIcon(modelData)
                        width: grp.width
                        height: 34
                        radius: 8
                        color: cur ? Theme.a(Theme.accent, 0.13) : hov.hovered ? Theme.a(Theme.text, 0.06) : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        IconImage {
                            id: ic
                            x: 10
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 20
                            source: row.iconSrc
                            visible: row.iconSrc !== ""
                        }
                        Label {
                            x: 10
                            anchors.verticalCenter: parent.verticalCenter
                            visible: row.iconSrc === ""
                            icon: true
                            text: "󰖯"
                            font.pixelSize: 16
                            color: Theme.overlay2
                        }
                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: 42
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.title
                            elide: Text.ElideRight
                            color: row.cur ? Theme.text : Theme.subtext0
                            font.weight: row.cur ? Font.DemiBold : Font.Normal
                            transform: Translate { x: hov.hovered ? 3 : 0; Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } } }
                        }
                        HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: { Icons.focusWindow(row.modelData); root.closeRequested() } }
                    }
                }
            }
        }
    }
}

import QtQuick
import Quickshell

// Notification history with Do Not Disturb and clear-all.
Item {
    id: root

    property real now: Date.now()
    // Opening the centre clears the pop-ups: they're all listed here anyway,
    // and the toast layer would otherwise sit on top of this panel.
    Component.onCompleted: Notifs.toasts = []
    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.now = Date.now() }

    implicitWidth: 380
    implicitHeight: header.height + 10 + Math.min(list.contentHeight, 460) + (Notifs.history.length ? 0 : 90)

    Item {
        id: header
        width: parent.width
        height: 30

        Label { anchors.verticalCenter: parent.verticalCenter; text: "Notifications"; font.pixelSize: 14; font.weight: Font.DemiBold }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            // Do Not Disturb switch
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Label { anchors.verticalCenter: parent.verticalCenter; text: "Do not disturb"; font.pixelSize: 11; color: Theme.subtext0 }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34; height: 18; radius: 9
                    color: Notifs.dnd ? Theme.a(Theme.accent, 0.35) : Theme.a(Theme.text, 0.08)
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Rectangle {
                        x: Notifs.dnd ? parent.width - width - 3 : 3
                        anchors.verticalCenter: parent.verticalCenter
                        width: 12; height: 12; radius: 6
                        color: Notifs.dnd ? Theme.accent : Theme.overlay2
                        Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.dnd = !Notifs.dnd }
                }
            }

            Rectangle {
                visible: Notifs.history.length > 0
                width: clearLabel.implicitWidth + 18; height: 22; radius: 7
                color: clearMouse.containsMouse ? Theme.a(Theme.alert, 0.15) : Theme.a(Theme.text, 0.06)
                Behavior on color { ColorAnimation { duration: 120 } }
                Label { id: clearLabel; anchors.centerIn: parent; text: "Clear"; font.pixelSize: 11; color: clearMouse.containsMouse ? Theme.alert : Theme.subtext1 }
                MouseArea { id: clearMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clearAll() }
            }
        }
    }

    Column {
        visible: Notifs.history.length === 0
        anchors.horizontalCenter: parent.horizontalCenter
        y: header.height + 26
        spacing: 6
        Label { anchors.horizontalCenter: parent.horizontalCenter; icon: true; text: Notifs.dnd ? "󰂛" : "󰂚"; font.pixelSize: 26; color: Theme.overlay0 }
        Label { anchors.horizontalCenter: parent.horizontalCenter; text: "All caught up"; color: Theme.overlay1 }
    }

    ListView {
        id: list
        y: header.height + 10
        width: parent.width
        height: Math.min(contentHeight, 460)
        clip: true
        spacing: 6
        boundsBehavior: Flickable.StopAtBounds
        model: ScriptModel { values: Notifs.history }

        remove: Transition { ParallelAnimation {
            NumberAnimation { property: "x"; to: 380; duration: 220; easing.type: Easing.InCubic }
            NumberAnimation { property: "opacity"; to: 0; duration: 220 }
        } }
        displaced: Transition { NumberAnimation { property: "y"; duration: 240; easing.type: Easing.OutCubic } }
        add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }

        delegate: Rectangle {
            id: item
            required property var modelData
            width: list.width
            height: card.implicitHeight
            radius: 12
            color: card.hovered ? Theme.a(Theme.text, 0.06) : Theme.a(Theme.text, 0.03)
            Behavior on color { ColorAnimation { duration: 120 } }
            NotifCard {
                id: card
                n: item.modelData
                width: parent.width
                compact: false
                now: root.now
                onDismissRequested: item.modelData.dismiss()
            }
            TapHandler { onTapped: Notifs.activate(item.modelData) }
        }
    }
}

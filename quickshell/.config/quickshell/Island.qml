import QtQuick

// One of the bar's three glass islands. Ignites like a sign on startup and
// eases its width when modules come and go.
Rectangle {
    id: root

    default property alias content: row.data
    property int ignition: 0

    implicitWidth: row.implicitWidth + 8
    implicitHeight: Theme.barHeight
    radius: Theme.radius
    color: Theme.island
    border.width: 1
    border.color: Theme.hairline
    Behavior on implicitWidth { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

    // Faint sheen along the top edge, like light catching glass.
    Rectangle {
        x: root.radius
        y: 1
        width: root.width - root.radius * 2
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.5; color: Theme.a(Theme.text, 0.09) }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2
    }

    opacity: 0
    SequentialAnimation on opacity {
        PauseAnimation { duration: root.ignition }
        NumberAnimation { to: 0.7; duration: 50 }
        NumberAnimation { to: 0.15; duration: 80 }
        NumberAnimation { to: 1; duration: 50 }
        NumberAnimation { to: 0.5; duration: 90 }
        NumberAnimation { to: 1; duration: 320; easing.type: Easing.OutQuad }
    }
}

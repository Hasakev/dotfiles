import QtQuick

// Thin glowing track with a knob; emits moved(value) while dragged.
Item {
    id: root

    property real value: 0          // 0..1 (may exceed 1; fill clamps)
    property color accent: Theme.blue
    property bool dim: false
    signal moved(real value)

    implicitWidth: 200
    implicitHeight: 16

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: Theme.a(Theme.surface1, 0.8)

        Rectangle {
            width: parent.width * Math.min(1, root.value)
            height: parent.height
            radius: 2
            opacity: root.dim ? 0.35 : 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Theme.a(root.accent, 0.5) }
                GradientStop { position: 1; color: root.accent }
            }
            Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
    }

    Rectangle {
        id: knob
        x: track.width * Math.min(1, root.value) - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: drag.pressed || drag.containsMouse ? 14 : 10
        height: width
        radius: width / 2
        color: root.dim ? Theme.overlay1 : root.accent
        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
        Behavior on x { enabled: !drag.pressed; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Rectangle {   // halo
            anchors.centerIn: parent
            width: parent.width + 8
            height: width
            radius: width / 2
            color: Theme.a(root.accent, drag.pressed ? 0.3 : 0.12)
        }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        function set(m) { root.moved(Math.max(0, Math.min(1, m.x / width))) }
        onPressed: m => set(m)
        onPositionChanged: m => { if (pressed) set(m) }
        onWheel: w => root.moved(Math.max(0, Math.min(1, root.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}

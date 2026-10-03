import QtQuick

// Round glyph button with a neon hover halo and a press squish.
Rectangle {
    id: root

    property alias text: glyph.text
    property alias size: glyph.font.pixelSize
    property color accent: Theme.cyan
    property bool on: false
    signal clicked()

    implicitWidth: glyph.implicitHeight + 14
    implicitHeight: implicitWidth
    radius: width / 2
    color: on ? Theme.a(accent, 0.22) : mouse.containsMouse ? Theme.a(accent, 0.14) : "transparent"
    border.width: 1
    border.color: on || mouse.containsMouse ? Theme.a(accent, 0.45) : "transparent"
    scale: mouse.pressed ? 0.88 : 1
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

    Label {
        id: glyph
        icon: true
        anchors.centerIn: parent
        font.pixelSize: 16
        color: root.on || mouse.containsMouse ? root.accent : Theme.subtext0
        glow: root.on
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

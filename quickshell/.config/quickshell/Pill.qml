import QtQuick

// A bar module: no box of its own. Hover lifts a soft plate behind it; an
// open popout tints the plate with the accent. Click + scroll signals.
Item {
    id: root

    default property alias content: row.data
    property bool active: false     // its popout is open
    property int padding: 10
    readonly property bool hovered: hover.hovered

    signal clicked(int button)
    signal scrolled(int steps)

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: Theme.barHeight - 8
    Behavior on implicitWidth { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    // Declared before the content so controls inside (tray icons, etc.) sit
    // on top and get their own clicks; this catches the rest of the pill.
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: e => root.clicked(e.button)
        onWheel: w => root.scrolled(w.angleDelta.y > 0 ? 1 : -1)
    }
    // Passive, so the plate stays lit while hovering an inner control.
    HoverHandler { id: hover }

    Rectangle {
        anchors.fill: parent
        radius: 9
        color: root.active ? Theme.a(Theme.accent, 0.14) : Theme.a(Theme.text, root.hovered ? 0.07 : 0)
        scale: mouse.pressed ? 0.94 : 1
        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 7
    }

}

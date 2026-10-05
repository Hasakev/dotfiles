import QtQuick

// Titled panel card: title + big value (top right), optional sub line, then content.
Rectangle {
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

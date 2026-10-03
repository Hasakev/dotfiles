import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

// One notification: image/app icon, app · age, summary, body, actions.
// Used by the toasts and the history panel.
Item {
    id: root

    required property var n
    property bool compact: false
    property real now: Date.now()
    readonly property bool hovered: hover.hovered
    readonly property bool critical: n?.urgency === NotificationUrgency.Critical
    readonly property string iconSrc: {
        if (!n) return ""
        if (n.image) return n.image
        const i = n.appIcon || DesktopEntries.heuristicLookup(n.desktopEntry || n.appName)?.icon || ""
        return !i ? "" : i.startsWith("/") ? "file://" + i : i.includes("://") ? i : Quickshell.iconPath(i, true)
    }
    signal dismissRequested()

    implicitWidth: 360
    implicitHeight: body.implicitHeight + 24

    HoverHandler { id: hover }

    // Critical: neon edge.
    Rectangle {
        visible: root.critical
        x: 0; y: 10
        width: 3; height: parent.height - 20
        radius: 2
        color: Theme.alert
    }

    Item {
        id: art
        x: 14; y: 12
        width: 36; height: 36
        ClippingRectangle {
            anchors.fill: parent
            radius: 9
            color: Theme.a(Theme.text, 0.05)
            visible: root.iconSrc !== ""
            IconImage { anchors.fill: parent; source: root.iconSrc; asynchronous: true }
        }
        Label {
            anchors.centerIn: parent
            visible: root.iconSrc === ""
            icon: true
            text: "󰂚"
            font.pixelSize: 20
            color: Theme.overlay2
        }
    }

    Column {
        id: body
        anchors.left: art.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 14
        y: 12
        spacing: 3

        Item {
            width: parent.width
            height: appLabel.implicitHeight
            Label {
                id: appLabel
                width: parent.width - 40
                text: root.n?.appName || "Notification"
                elide: Text.ElideRight
                color: root.critical ? Theme.alert : Theme.overlay2
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
            Label {
                anchors.right: parent.right
                visible: !root.hovered
                text: root.n ? Notifs.age(root.n, root.now) : ""
                color: Theme.overlay1
                font.pixelSize: 10
            }
        }
        Label {
            width: parent.width
            text: root.n?.summary ?? ""
            color: Theme.text
            font.pixelSize: 12
            font.weight: Font.DemiBold
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
        Label {
            width: parent.width
            visible: text !== ""
            text: root.n?.body ?? ""
            textFormat: Text.StyledText
            color: Theme.subtext0
            font.pixelSize: 11
            font.weight: Font.Normal
            wrapMode: Text.Wrap
            maximumLineCount: root.compact ? 2 : 4
            elide: Text.ElideRight
            linkColor: Theme.accent
            onLinkActivated: l => Qt.openUrlExternally(l)
        }
        Row {
            visible: (root.n?.actions?.length ?? 0) > 0 && !root.compact
            topPadding: 5
            spacing: 6
            Repeater {
                model: root.n?.actions ?? []
                delegate: Rectangle {
                    required property var modelData
                    visible: modelData.identifier !== "default"
                    width: actLabel.implicitWidth + 20
                    height: 24
                    radius: 7
                    color: actMouse.containsMouse ? Theme.a(Theme.accent, 0.2) : Theme.a(Theme.text, 0.06)
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Label { id: actLabel; anchors.centerIn: parent; text: parent.modelData.text; font.pixelSize: 11; color: Theme.subtext1 }
                    MouseArea {
                        id: actMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { parent.modelData.invoke(); Notifs.hideToast(root.n) }
                    }
                }
            }
        }
    }

    // Close (dismiss for good) appears on hover in place of the age.
    IconButton {
        anchors.right: parent.right
        anchors.rightMargin: 8
        y: 6
        visible: root.hovered
        text: "󰅖"
        size: 11
        onClicked: root.dismissRequested()
    }
}

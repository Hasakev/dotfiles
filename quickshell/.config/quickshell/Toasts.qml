import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Notification toasts under the right island of the focused monitor.
// Slide in with a spring, pause while hovered, swipe right to dismiss,
// click to run the default action. Timing out only hides (stays in history).
PanelWindow {
    id: win

    screen: Quickshell.screens.find(s => Hyprland.monitorFor(s) === Hyprland.focusedMonitor) ?? null
    visible: Notifs.toasts.length > 0
    anchors { top: true; right: true }
    margins { top: Theme.gap + Theme.barHeight + 8; right: 12 }
    implicitWidth: 380
    implicitHeight: Math.max(1, stack.implicitHeight + 16)
    exclusiveZone: 0
    color: "transparent"
    mask: Region { item: stack }
    WlrLayershell.namespace: "quickshell:toasts"
    WlrLayershell.layer: WlrLayer.Overlay

    Column {
        id: stack
        width: 360
        anchors.right: parent.right
        spacing: 8
        move: Transition { NumberAnimation { property: "y"; duration: 260; easing.type: Easing.OutCubic } }

        Repeater {
            model: ScriptModel { values: Notifs.toasts }
            delegate: Item {
                id: toast
                required property var modelData
                readonly property var n: modelData
                readonly property bool critical: card.critical
                readonly property int timeout: critical ? 0
                    : (n.expireTimeout > 0 ? Math.min(n.expireTimeout * 1000, 15000) : 6000)
                property bool leaving: false

                width: stack.width
                height: card.implicitHeight

                function leave(dismiss) {
                    if (leaving) return
                    leaving = true
                    exitAnim.dismiss = dismiss
                    exitAnim.start()
                }

                Connections { target: toast.n; function onClosed() { Notifs.hideToast(toast.n) } }

                Rectangle {
                    id: bg
                    width: parent.width
                    height: parent.height
                    radius: Theme.radius
                    color: Theme.base   // solid: see popout note in Bar.qml
                    border.width: 1
                    border.color: Theme.hairline
                    opacity: Math.max(0, 1 - Math.abs(x) / 260)

                    NotifCard {
                        id: card
                        n: toast.n
                        width: parent.width
                        onDismissRequested: toast.leave(true)
                    }

                    // Timeout line drains along the bottom; frozen while hovered.
                    Rectangle {
                        id: life
                        visible: toast.timeout > 0
                        x: Theme.radius
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 1
                        height: 1.5
                        width: (parent.width - Theme.radius * 2) * life.remaining
                        color: Theme.a(Theme.accent, 0.6)
                        property real remaining: 1
                        NumberAnimation on remaining {
                            id: drain
                            from: 1; to: 0
                            duration: toast.timeout
                            running: toast.timeout > 0
                            paused: toast.timeout > 0 && !toast.leaving && (card.hovered || drag.active)
                            onFinished: toast.leave(false)
                        }
                    }

                    DragHandler {
                        id: drag
                        xAxis.enabled: true
                        yAxis.enabled: false
                        xAxis.minimum: -40
                        onActiveChanged: if (!active) {
                            if (bg.x > 110) toast.leave(true)
                            else snapBack.start()
                        }
                    }
                    NumberAnimation { id: snapBack; target: bg; property: "x"; to: 0; duration: 300; easing.type: Easing.OutBack }
                    TapHandler { onTapped: Notifs.activate(toast.n) }
                }

                // Enter: slide in from the right with a little overshoot.
                Component.onCompleted: { bg.x = 380; enterAnim.start() }
                NumberAnimation { id: enterAnim; target: bg; property: "x"; to: 0; duration: 480; easing.type: Easing.OutBack; easing.overshoot: 1.1 }

                SequentialAnimation {
                    id: exitAnim
                    property bool dismiss: false
                    NumberAnimation { target: bg; property: "x"; to: 400; duration: 260; easing.type: Easing.InCubic }
                    ScriptAction {
                        script: {
                            if (exitAnim.dismiss) toast.n.dismiss()
                            Notifs.hideToast(toast.n)
                        }
                    }
                }
            }
        }
    }
}

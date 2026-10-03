pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification daemon (replaces dunst). Everything lands in history; a toast
// is shown unless Do Not Disturb is on (critical ones always break through).
Singleton {
    id: root

    property bool dnd: false
    property var toasts: []      // Notifications currently popped up, newest first
    readonly property var history: server.trackedNotifications.values.slice().reverse()

    function hideToast(n) { toasts = toasts.filter(t => t !== n) }
    function clearAll() { for (const n of history) n.dismiss(); toasts = [] }

    // Default action if the app offered one ("default" per spec), else the only action.
    function activate(n) {
        const a = n.actions.find(a => a.identifier === "default") ?? (n.actions.length === 1 ? n.actions[0] : null)
        a?.invoke()
        hideToast(n)
    }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true
            root.received[n.id] = Date.now()
            if (n.transient && root.dnd) return
            // A replacement (same id) re-emits: move it to the top instead of duplicating.
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                root.toasts = [n, ...root.toasts.filter(t => t !== n)].slice(0, 5)
        }
    }

    // Notifications carry no timestamp; remember when each id arrived.
    property var received: ({})
    function age(n, now) {
        const m = Math.floor((now - (received[n.id] ?? now)) / 60000)
        return m < 1 ? "now" : m < 60 ? m + "m" : m < 1440 ? Math.floor(m / 60) + "h" : Math.floor(m / 1440) + "d"
    }
}

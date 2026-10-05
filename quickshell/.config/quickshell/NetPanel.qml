import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking

// Connectivity: Wi-Fi networks and Bluetooth devices, click to (dis)connect.
Item {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btDevices: Bluetooth.devices.values
        .filter(d => d.paired || d.connected)
        .sort((a, b) => b.connected - a.connected || a.name.localeCompare(b.name))

    implicitWidth: 380
    implicitHeight: col.implicitHeight

    // Network awaiting a password, and the last failure message.
    property var askFor: null
    property string error: ""

    Component.onCompleted: { Net.setScanning(true); Net.detailed = true }
    Component.onDestruction: { Net.setScanning(false); Net.detailed = false }

    function dbmColor(d) { return d >= -60 ? Theme.good : d >= -70 ? Theme.amber : Theme.alert }
    function pingColor() { return Net.ping >= 80 || Net.loss >= 5 ? Theme.alert : Net.ping >= 30 || Net.jitter >= 20 ? Theme.amber : Theme.accent }
    readonly property string internet: !Networking.canCheckConnectivity ? "" : ({
        [NetworkConnectivity.Full]: "online", [NetworkConnectivity.Limited]: "no internet",
        [NetworkConnectivity.Portal]: "login portal", [NetworkConnectivity.None]: "offline" })[Networking.connectivity] ?? "checking…"

    function pick(n) {
        error = ""
        if (n.connected) n.disconnect()
        else if (n.known || !Net.secure(n)) n.connect()
        else askFor = askFor === n ? null : n
    }

    Connections {
        target: root.askFor
        function onConnectionFailed(reason) {
            root.error = reason === ConnectionFailReason.NoSecrets ? "Wrong password" : ConnectionFailReason.toString(reason)
        }
        function onConnectedChanged() { if (root.askFor?.connected) root.askFor = null }
    }

    component Header: Item {
        id: h
        property string title
        property bool on
        property bool busy: false
        property color accent: Theme.cyan
        signal toggled()
        signal refresh()
        width: parent.width
        height: 30
        Label { anchors.verticalCenter: parent.verticalCenter; text: h.title; color: Theme.overlay1; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.5 }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            IconButton {
                text: "󰑐"
                size: 13
                accent: h.accent
                visible: h.on
                onClicked: h.refresh()
                RotationAnimation on rotation { running: h.busy; from: 0; to: 360; duration: 800; loops: Animation.Infinite }
            }
            // Pill switch with a sliding knob.
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 36; height: 18; radius: 9
                color: h.on ? Theme.a(h.accent, 0.3) : Theme.a(Theme.surface1, 0.8)
                border.width: 1
                border.color: h.on ? Theme.a(h.accent, 0.6) : "transparent"
                Behavior on color { ColorAnimation { duration: 200 } }
                Rectangle {
                    x: h.on ? parent.width - width - 3 : 3
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12; height: 12; radius: 6
                    color: h.on ? h.accent : Theme.overlay1
                    Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: h.toggled() }
            }
        }
    }

    component Entry: Rectangle {
        id: e
        property string icon
        property string label
        property string detail
        property bool cur
        property bool busy: false
        property color accent: Theme.cyan
        signal clicked()
        width: parent.width
        height: 30
        radius: 7
        color: cur ? Theme.a(accent, 0.12) : hov.containsMouse ? Theme.a(Theme.surface1, 0.6) : "transparent"
        border.width: cur ? 1 : 0
        border.color: Theme.a(accent, 0.35)
        Behavior on color { ColorAnimation { duration: 150 } }

        Label { id: ic; icon: true; x: 10; anchors.verticalCenter: parent.verticalCenter; text: e.icon; color: e.cur ? e.accent : Theme.overlay2; font.pixelSize: 14; glow: e.cur }
        Label {
            anchors.left: ic.right; anchors.leftMargin: 10; anchors.right: det.left; anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: e.label; elide: Text.ElideRight
            color: e.cur ? Theme.text : Theme.subtext0
            font.pixelSize: 11
        }
        Label {
            id: det
            anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
            text: e.detail; color: Theme.overlay1; font.pixelSize: 10
            SequentialAnimation on opacity { running: e.busy; loops: Animation.Infinite; NumberAnimation { to: 0.2; duration: 400 } NumberAnimation { to: 1; duration: 400 } }
        }
        MouseArea { id: hov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: e.clicked() }
    }

    // One "key  value" line in the connection card.
    component KV: Item {
        property string k
        property string v
        property color vColor: Theme.subtext1
        width: parent.width
        height: 16
        visible: v !== ""
        Label { text: parent.k; color: Theme.overlay1; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
        Label {
            x: 64; width: parent.width - 64; elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
            text: parent.v; color: parent.vColor; font.pixelSize: 11
        }
    }

    Column {
        id: col
        width: parent.width
        spacing: 4

        Header {
            title: "WI-FI"
            on: Net.radio
            busy: Net.scanning
            onToggled: Net.setRadio(!Net.radio)
            onRefresh: Net.setScanning(!Net.scanning)
        }

        Card {
            width: parent.width
            visible: Net.radio && !!Net.ssid
            title: "CONNECTION"
            value: Net.link.dbm ? Net.link.dbm + " dBm" : ""
            accent: root.dbmColor(Net.link.dbm)
            sub: Net.link.freq ? `${Net.iface} · ${Net.band(Net.link.freq)} · ch ${Net.link.chan} · ${Math.round(Net.link.freq)} MHz` : Net.iface
            KV { k: "link"; v: Net.link.rx ? `↓ ${Net.link.rx} · ↑ ${Net.link.tx} Mbit/s` : "" }
            KV {
                k: "channel"
                v: !Net.link.chan ? "" : Net.link.shared ? `shared with ${Net.link.shared} other network${Net.link.shared > 1 ? "s" : ""}` : "clear"
                vColor: Net.link.shared ? Theme.amber : Theme.good
            }
            KV { k: "security"; v: Net.active ? WifiSecurityType.toString(Net.active.security) : "" }
            KV { k: "address"; v: Net.link.ip ?? "" }
            KV { k: "gateway"; v: Net.link.gw ?? "" }
            KV { k: "dns"; v: Net.link.dns ?? "" }
            KV { k: "internet"; v: root.internet; vColor: root.internet === "online" ? Theme.good : Theme.amber }
        }

        Row {
            width: parent.width
            spacing: 8
            visible: Net.radio && !!Net.ssid
            Card {
                width: (parent.width - 8) / 2
                title: "TRAFFIC"
                value: "↓ " + Net.rate(Net.downHist[Net.downHist.length - 1] ?? 0)
                sub: "↑ " + Net.rate(Net.upHist[Net.upHist.length - 1] ?? 0)
                // Down and up share one scale so their heights compare.
                Item {
                    readonly property real max: Math.max(10240, ...Net.downHist, ...Net.upHist)
                    width: parent.width; height: 36
                    Spark { anchors.fill: parent; values: Net.downHist; max: parent.max; accent: Theme.accent }
                    Spark { anchors.fill: parent; values: Net.upHist; max: parent.max; accent: Theme.subtext1 }
                }
            }
            Card {
                width: (parent.width - 8) / 2
                title: "LATENCY"
                value: Net.pingHist.length ? Math.round(Net.ping) + " ms" : "…"
                sub: `jitter ${Math.round(Net.jitter)} ms · ${Net.loss}% loss`
                accent: root.pingColor()
                Spark { width: parent.width; height: 36; values: Net.pingHist; max: Math.max(20, ...Net.pingHist); accent: root.pingColor() }
            }
        }
        Repeater {
            model: Net.radio ? Net.networks.slice(0, 7) : []
            delegate: Column {
                id: netRow
                required property var modelData
                readonly property bool asking: root.askFor === modelData
                width: col.width
                spacing: 4

                Entry {
                    icon: Net.bars(Math.round(netRow.modelData.signalStrength * 100))
                    label: netRow.modelData.name
                    busy: netRow.modelData.stateChanging
                    detail: (Net.secure(netRow.modelData) ? "󰌾 " : "")
                        + (Net.aps[netRow.modelData.name] ? Net.bandInfo(netRow.modelData.name) + " · " : "")
                        + (netRow.modelData.stateChanging ? "…" : netRow.modelData.connected ? "connected"
                           : Math.round(netRow.modelData.signalStrength * 100) + "%")
                    cur: netRow.modelData.connected
                    onClicked: root.pick(netRow.modelData)
                }

                // Password field slides open under the network.
                Rectangle {
                    width: parent.width
                    height: netRow.asking ? 34 : 0
                    visible: height > 0
                    clip: true
                    radius: 7
                    color: Theme.a(Theme.surface0, 0.8)
                    border.width: 1
                    border.color: root.error ? Theme.a(Theme.red, 0.6) : Theme.a(Theme.cyan, 0.4)
                    Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                    TextInput {
                        id: psk
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 12
                        focus: netRow.asking
                        onVisibleChanged: if (visible) { text = ""; forceActiveFocus() }
                        onAccepted: { root.error = ""; netRow.modelData.connectWithPsk(text) }
                        Keys.onEscapePressed: root.askFor = null
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 12
                        visible: psk.text === ""
                        text: root.error || "Password, then Enter"
                        color: root.error ? Theme.red : Theme.overlay1
                        font.pixelSize: 11
                    }
                }
            }
        }

        Item { width: 1; height: 6 }

        Header {
            title: "BLUETOOTH"
            accent: Theme.blue
            visible: !!root.adapter
            on: root.adapter?.enabled ?? false
            busy: root.adapter?.discovering ?? false
            onToggled: root.adapter.enabled = !root.adapter.enabled
            onRefresh: root.adapter.discovering = !root.adapter.discovering
        }
        Repeater {
            model: root.adapter?.enabled ? root.btDevices : []
            delegate: Entry {
                required property var modelData
                accent: Theme.blue
                icon: modelData.connected ? "󰂱" : "󰂯"
                label: modelData.name
                busy: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
                detail: busy ? "…" : modelData.connected
                    ? (modelData.batteryAvailable ? `󰥉 ${Math.round(modelData.battery * 100)}%` : "connected") : ""
                cur: modelData.connected
                onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
            }
        }
    }
}

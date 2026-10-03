import QtQuick
import Quickshell
import Quickshell.Hyprland

// Workspace glyphs over a liquid plate: on a switch the leading edge shoots
// ahead and the trailing edge catches up, so the plate stretches.
Item {
    id: root

    required property HyprlandMonitor monitor

    // Paired workspaces per output, as in hyprland.lua's workspace rules.
    readonly property var persistent: ({ "HDMI-A-1": [1, 3, 5], "DP-1": [2, 4, 6] })[monitor?.name] ?? []
    readonly property var ids: {
        const s = new Set(persistent)
        for (const w of Hyprland.workspaces.values)
            if (w.id > 0 && w.monitor === monitor) s.add(w.id)
        return [...s].sort((a, b) => a - b)
    }
    readonly property int activeId: monitor?.activeWorkspace?.id ?? -1
    readonly property int activeIndex: ids.indexOf(activeId)
    readonly property int slot: 28
    readonly property int spacing: 2
    property bool facingLeft: false

    implicitWidth: row.implicitWidth + 8
    implicitHeight: Theme.barHeight - 8

    function occupied(id) {
        const w = Hyprland.workspaces.values.find(w => w.id === id)
        return (w?.toplevels?.values?.length ?? 0) > 0
    }

    // Group numeral 1/2/3 for paired workspaces (1+2, 3+4, 5+6).
    function glyph(id) {
        if (id === activeId) return "󰮯"
        if (!occupied(id)) return "󰊠"
        return ["󰎤", "󰎧", "󰎪"][Math.floor((id - 1) / 2)] ?? "󰊠"
    }

    // Paired groups: HDMI-A-1 shows 2g-1, DP-1 shows 2g; switch both together.
    function view(g) {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${g * 2 - 1} })`)
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${g * 2} })`)
    }

    function moveBlob() {
        if (activeIndex < 0) return
        const l = 4 + activeIndex * (slot + spacing), r = l + slot
        const right = l > blob.l
        if (l !== blob.l) facingLeft = !right
        leadAnim.stop(); trailAnim.stop()
        leadAnim.property = right ? "r" : "l"; leadAnim.to = right ? r : l
        trailAnim.property = right ? "l" : "r"; trailAnim.to = right ? l : r
        leadAnim.start(); trailAnim.start()
    }
    onActiveIndexChanged: moveBlob()
    onIdsChanged: moveBlob()
    Component.onCompleted: { blob.l = 4 + Math.max(0, activeIndex) * (slot + spacing); blob.r = blob.l + slot }

    Rectangle {
        id: blob
        property real l: 4
        property real r: 4 + root.slot
        x: l
        width: r - l
        y: 0
        height: parent.height
        radius: 9
        visible: root.activeIndex >= 0
        color: Theme.a(Theme.accent, 0.13)
    }
    NumberAnimation { id: leadAnim; target: blob; duration: 170; easing.type: Easing.OutCubic }
    NumberAnimation { id: trailAnim; target: blob; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.2 }

    Row {
        id: row
        x: 4
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.spacing

        Repeater {
            model: root.ids
            delegate: Item {
                id: ws
                required property int modelData
                readonly property bool isActive: modelData === root.activeId
                width: root.slot
                height: root.height - 6

                Label {
                    id: glyphLabel
                    anchors.centerIn: parent
                    text: root.glyph(ws.modelData)
                    icon: true
                    font.pixelSize: 14
                    color: ws.isActive ? Theme.accent : hover.containsMouse ? Theme.subtext1
                         : root.occupied(ws.modelData) ? Theme.subtext0 : Theme.overlay0
                    glow: ws.isActive
                    // Pac-Man faces the way he just travelled.
                    transform: Scale {
                        origin.x: glyphLabel.width / 2
                        xScale: ws.isActive && root.facingLeft ? -1 : 1
                    }
                    scale: hover.pressed ? 0.8 : ws.isActive ? 1.1 : 1
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ws.modelData <= 6 ? root.view(Math.ceil(ws.modelData / 2)) : Hyprland.dispatch(`hl.dsp.focus({ workspace = ${ws.modelData} })`)
                }
            }
        }
    }

    // Scroll flips between the paired workspace groups.
    WheelHandler {
        onWheel: e => {
            const g = Math.floor((root.activeId - 1) / 2) + 1 + (e.angleDelta.y > 0 ? -1 : 1)
            if (g >= 1 && g <= 3) root.view(g)
        }
    }
}

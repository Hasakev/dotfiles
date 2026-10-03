import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

// App launcher. Plain text: fuzzy apps (+ live calculator for math).
// ">cmd" runs a shell command (Shift+Enter: in a terminal).
// ";text" searches clipboard history (cliphist); Enter copies.
// ↑/↓ or Tab to move, Enter to launch, Esc to close.
Item {
    id: root

    signal closeRequested()
    property string seed: ""
    onSeedChanged: { input.text = seed; input.cursorPosition = seed.length }

    readonly property string q: input.text
    readonly property string mode: q.startsWith(">") ? "run" : q.startsWith(";") ? "clip" : "apps"
    property var clips: []
    readonly property int rowH: 44
    readonly property int maxRows: 8

    readonly property var results: {
        if (mode === "run") {
            const cmd = q.slice(1).trim()
            return cmd ? [{ kind: "run", title: cmd, sub: "Enter: run · Shift+Enter: run in terminal", glyph: "" }] : []
        }
        if (mode === "clip") {
            const t = q.slice(1).toLowerCase()
            return clips.filter(c => c.text.toLowerCase().includes(t)).slice(0, 50)
                .map(c => ({ kind: "clip", title: c.text, sub: "", glyph: "󰅌", line: c.line }))
        }
        const out = []
        const v = Apps.calc(q)
        if (v !== null) out.push({ kind: "calc", title: v, sub: q.replace(/^=/, "").trim() + "  ·  Enter copies", glyph: "󰃬" })
        for (const e of Apps.search(q).slice(0, 40))
            out.push({ kind: "app", title: e.name, sub: e.genericName || e.comment || "", icon: e.icon, entry: e })
        return out
    }

    implicitWidth: 460
    implicitHeight: field.height + 10 + Math.max(1, Math.min(results.length, maxRows)) * rowH

    function activate(r, shift) {
        if (!r) return
        if (r.kind === "app") Apps.launch(r.entry)
        else if (r.kind === "calc") Quickshell.execDetached(["wl-copy", r.title])
        else if (r.kind === "run") Quickshell.execDetached(shift ? ["kitty", "--hold", "sh", "-c", r.title] : ["sh", "-c", r.title])
        else if (r.kind === "clip") Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "_", r.line])
        closeRequested()
    }

    Process {
        running: root.mode === "clip"
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.clips = text.split("\n").filter(l => l).map(l => ({ line: l, text: l.slice(l.indexOf("\t") + 1) }))
        }
    }

    // ── Search field ────────────────────────────────────────────────────────
    Rectangle {
        id: field
        width: parent.width
        height: 42
        radius: 10
        color: Theme.a(Theme.surface0, 0.8)
        border.width: 1
        border.color: Theme.a(root.mode === "run" ? Theme.amber : root.mode === "clip" ? Theme.magenta : Theme.cyan, 0.45)
        Behavior on border.color { ColorAnimation { duration: 200 } }

        Label {
            id: prompt
            icon: true
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            text: root.mode === "run" ? "" : root.mode === "clip" ? "󰅌" : "󰍉"
            color: root.mode === "run" ? Theme.amber : root.mode === "clip" ? Theme.magenta : Theme.cyan
            font.pixelSize: 15
        }
        TextInput {
            id: input
            anchors.left: prompt.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.text
            selectionColor: Theme.a(Theme.cyan, 0.4)
            font.family: Theme.font
            font.pixelSize: 14
            focus: true
            Component.onCompleted: forceActiveFocus()
            onTextChanged: list.currentIndex = 0

            Keys.onEscapePressed: root.closeRequested()
            Keys.onDownPressed: list.incrementCurrentIndex()
            Keys.onUpPressed: list.decrementCurrentIndex()
            Keys.onTabPressed: list.incrementCurrentIndex()
            Keys.onBacktabPressed: list.decrementCurrentIndex()
            Keys.onReturnPressed: e => root.activate(root.results[list.currentIndex], e.modifiers & Qt.ShiftModifier)
            Keys.onEnterPressed: e => root.activate(root.results[list.currentIndex], e.modifiers & Qt.ShiftModifier)
        }
        Label {
            anchors.left: input.left
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            text: "Search apps   ·   > run   ·   ; clipboard   ·   2+2"
            color: Theme.overlay0
            font.pixelSize: 12
        }
    }

    // ── Results ─────────────────────────────────────────────────────────────
    ListView {
        id: list
        y: field.height + 10
        width: parent.width
        height: Math.min(count, root.maxRows) * root.rowH
        clip: true
        model: root.results
        currentIndex: 0
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: 160
        highlightResizeDuration: 0
        keyNavigationWraps: true

        // Neon selection bar that glides between rows.
        highlight: Rectangle {
            radius: 9
            color: Theme.a(Theme.cyan, 0.12)
            border.width: 1
            border.color: Theme.a(Theme.cyan, 0.4)
            Rectangle {
                x: 0; width: 3; height: parent.height * 0.5
                anchors.verticalCenter: parent.verticalCenter
                radius: 2
                color: Theme.blue
            }
        }

        // Rows cascade in when results change.
        add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 } }
        displaced: Transition { NumberAnimation { property: "y"; duration: 160; easing.type: Easing.OutCubic } }

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property bool sel: ListView.isCurrentItem
            width: list.width
            height: root.rowH

            Item {
                id: iconBox
                x: 12
                width: 26; height: 26
                anchors.verticalCenter: parent.verticalCenter
                // Resolve against the icon theme up front; missing icons fall
                // back to a glyph instead of spamming load warnings.
                readonly property string iconSrc: row.modelData.kind === "app" && row.modelData.icon
                    ? (row.modelData.icon.startsWith("/") ? "file://" + row.modelData.icon : Quickshell.iconPath(row.modelData.icon, true)) : ""
                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 26
                    visible: iconBox.iconSrc !== ""
                    source: iconBox.iconSrc
                    asynchronous: true
                }
                Label {
                    anchors.centerIn: parent
                    visible: iconBox.iconSrc === ""
                    icon: true
                    text: row.modelData.glyph ?? "󰣆"
                    font.pixelSize: 18
                    color: row.sel ? Theme.blue : Theme.overlay2
                }
                scale: row.sel ? 1.12 : 1
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
            }

            Column {
                anchors.left: iconBox.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                // Selected row nudges right a touch.
                transform: Translate { x: row.sel ? 4 : 0; Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } } }

                Label {
                    width: parent.width
                    text: row.modelData.title
                    elide: Text.ElideRight
                    color: row.sel ? Theme.text : Theme.subtext0
                    font.pixelSize: row.modelData.kind === "calc" ? 16 : 12
                    font.weight: row.sel || row.modelData.kind === "calc" ? Font.Bold : Font.Medium
                    maximumLineCount: 1
                }
                Label {
                    width: parent.width
                    visible: text !== ""
                    text: row.modelData.sub
                    elide: Text.ElideRight
                    color: Theme.overlay1
                    font.pixelSize: 10
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: list.currentIndex = row.index
                onClicked: root.activate(row.modelData, false)
            }

            // Desktop actions (e.g. "New Private Window") on the selected app.
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                visible: row.sel && row.modelData.kind === "app"
                Repeater {
                    model: row.sel && row.modelData.entry ? Array.from(row.modelData.entry.actions).slice(0, 3) : []
                    delegate: Rectangle {
                        required property var modelData
                        height: 22
                        width: chip.implicitWidth + 16
                        radius: 11
                        color: chipMouse.containsMouse ? Theme.a(Theme.cyan, 0.25) : Theme.a(Theme.surface1, 0.9)
                        border.width: 1
                        border.color: Theme.a(Theme.cyan, 0.35)
                        Label { id: chip; anchors.centerIn: parent; text: parent.modelData.name; font.pixelSize: 10; color: Theme.subtext1 }
                        MouseArea {
                            id: chipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { Apps.launch(row.modelData.entry, parent.modelData); root.closeRequested() }
                        }
                    }
                }
            }
        }
    }

    Label {
        y: field.height + 22
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.results.length === 0
        text: root.mode === "clip" ? "Clipboard is empty" : root.mode === "run" ? "Type a command" : "No matches"
        color: Theme.overlay0
    }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Audio spectrum from cava, 0..1 per bar. Only runs while media plays.
Singleton {
    id: root

    readonly property int count: 48
    property var bars: Array(count).fill(0)

    Process {
        running: Player.active?.isPlaying ?? false
        command: ["cava", "-p", Quickshell.shellPath("cava.conf")]
        stdout: SplitParser {
            onRead: line => root.bars = line.split(";").filter(s => s !== "").map(v => v / 100)
        }
        onRunningChanged: if (!running) root.bars = Array(root.count).fill(0)
    }
}

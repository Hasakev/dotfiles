//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

ShellRoot {
    Variants {
        id: bars
        model: Quickshell.screens
        delegate: Bar {}
    }

    Osd {}
    Toasts {}

    // Volume/mute/default device data is only live for tracked nodes.
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    // qs ipc call notifs <clear|toggleDnd>
    IpcHandler {
        target: "notifs"
        function clear(): void { Notifs.clearAll() }
        function toggleDnd(): void { Notifs.dnd = !Notifs.dnd }
    }

    // qs ipc call bar toggle <media|mixer|net|calendar|weather>
    IpcHandler {
        target: "bar"
        function toggle(panel: string): void {
            const b = bars.instances.find(b => b.monitor === Hyprland.focusedMonitor)
            b?.toggleByName(panel)
        }
    }
}

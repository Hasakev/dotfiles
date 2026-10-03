#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# audio-opacity.sh
# Event-driven audio-aware opacity via Hyprland IPC.
# Pins unfocused windows producing audio to full opacity.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

get_audio_pids() {
    pw-dump 2>/dev/null \
        | python3 -c "
import json, sys
for n in json.load(sys.stdin):
    p = n.get('info', {})
    if 'Stream/Output/Audio' in p.get('props', {}).get('media.class', '') \
            and p.get('state') == 'running':
        pid = p.get('props', {}).get('application.process.id')
        if pid:
            print(pid)
"
}

# Props multiply with decoration.inactive_opacity unless overridden, so keep the
# value at 1.0 and toggle only the override: 0 = normal dimming, 1 = fully opaque.
set_prop() {
    hyprctl dispatch "hl.dsp.window.set_prop({ window = \"address:$1\", prop = \"$2\", value = \"$3\" })" &>/dev/null
}

pin_opacity() {
    set_prop "$1" opacity_inactive 1.0
    set_prop "$1" opacity_inactive_override "$2"
}

apply_opacity() {
    mapfile -t pids < <(get_audio_pids | sort -u)

    # Reset all windows to standard Hyprland-managed opacity
    hyprctl clients -j 2>/dev/null \
        | python3 -c "import json, sys; [print(c['address']) for c in json.load(sys.stdin)]" \
        | while read -r addr; do
            pin_opacity "$addr" 0
        done

    # Pin windows with active audio streams to full opacity regardless of focus
    if [[ ${#pids[@]} -gt 0 ]]; then
        hyprctl clients -j 2>/dev/null \
            | python3 -c "
import json, sys
clients = {}
for c in json.load(sys.stdin):
    clients.setdefault(c.get('pid'), []).append(c['address'])
# Browsers play audio from a child process (e.g. Chromium's AudioService), so
# walk up to the nearest ancestor that owns a window.
for pid in map(int, sys.argv[1:]):
    while pid > 1 and pid not in clients:
        try:
            pid = int(open(f'/proc/{pid}/stat').read().rsplit(')', 1)[1].split()[1])
        except OSError:
            break
    if pid in clients:
        print(*clients[pid], sep='\\n')
" "${pids[@]}" \
            | while read -r addr; do
                pin_opacity "$addr" 1
            done
    fi
}

main() {
    nc -U "$SOCKET" | while IFS= read -r event; do
        case "$event" in
            activewindow\>* | closewindow\>*)
                apply_opacity
                ;;
        esac
    done
}

main "$@"

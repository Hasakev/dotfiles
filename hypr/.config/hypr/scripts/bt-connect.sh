#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# bt-connect.sh
# Attempts to connect to a known Bluetooth device on Hyprland launch.
# Retries until success or max attempts is reached.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

DEVICE_NAME="HT-S100F"
MAX_ATTEMPTS=10
RETRY_DELAY=3   # seconds between attempts
INIT_DELAY=5    # seconds to wait for bluetoothd to be ready

log() { echo "[bt-connect] $*" | systemd-cat -t bt-connect -p info; }

# Resolve MAC from device name via bluetoothctl
resolve_mac() {
    bluetoothctl devices | awk -v name="$DEVICE_NAME" '$0 ~ name { print $2 }'
}

main() {
    log "Waiting ${INIT_DELAY}s for bluetooth stack to initialise..."
    sleep "$INIT_DELAY"

    # Ensure bluetooth service is up
    if ! systemctl is-active --quiet bluetooth; then
        log "bluetooth.service is not active — attempting to start"
        systemctl start bluetooth || { log "Failed to start bluetooth.service"; exit 1; }
        sleep 2
    fi

    local mac
    mac=$(resolve_mac)

    if [[ -z "$mac" ]]; then
        log "Device '${DEVICE_NAME}' not found in paired devices. Aborting."
        exit 1
    fi

    log "Resolved '${DEVICE_NAME}' → ${mac}"

    for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
        log "Connection attempt ${attempt}/${MAX_ATTEMPTS}..."

        if bluetoothctl connect "$mac" 2>&1 | grep -q "Connection successful"; then
            log "Connected to '${DEVICE_NAME}' (${mac})"
            exit 0
        fi

        log "Attempt ${attempt} failed. Retrying in ${RETRY_DELAY}s..."
        sleep "$RETRY_DELAY"
    done

    log "All ${MAX_ATTEMPTS} attempts failed. Giving up."
    exit 1
}

main "$@"

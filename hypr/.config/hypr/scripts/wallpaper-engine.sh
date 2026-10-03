#!/usr/bin/env bash
# Animated wallpapers via linux-wallpaperengine on physical AND Sunshine outputs.
#
# Selection lives in one state file (OUTPUT<TAB>wallpaper-dir per line), which is
# the single source of truth. waypaper updates it live via post_command:
#     post_command = bash ~/.config/hypr/scripts/wallpaper-engine.sh set "$monitor" "$wallpaper"
# and the same file is replayed on startup and on monitor hotplug (physical
# monitors and HEADLESS-SUNSHINE appear at different times: desk vs. Moonlight).
# hyprpaper stays as the static fallback under any output WPE doesn't cover.
set -u

ASSETS=/mnt/data/SteamLibrary/steamapps/common/wallpaper_engine/assets
STATE="$HOME/.config/hypr/wallpaper-engine.map"
OUTPUTS=(DP-1 HDMI-A-1 HEADLESS-SUNSHINE)

# Seed defaults on first run (render-verified wallpapers; the SYKM/three-body
# ones crash WPE with "Projection must have a width").
seed() {
  [ -f "$STATE" ] && return
  local WS=/mnt/data/SteamLibrary/steamapps/workshop/content/431960
  printf '%s\t%s\n' \
    DP-1              "$WS/2930492593" \
    HDMI-A-1          "$WS/2872906858" \
    HEADLESS-SUNSHINE "$WS/2149429963" > "$STATE"
}

# set OUTPUT -> dir in the state file ("All" fans out to every known output).
set_wp() {
  local mon="$1" dir="$2" tmp; tmp=$(mktemp)
  local targets=("$mon"); [ "$mon" = "All" ] && targets=("${OUTPUTS[@]}")
  grep -vP "^($(IFS='|'; echo "${targets[*]}"))\t" "$STATE" 2>/dev/null > "$tmp"
  local o; for o in "${targets[@]}"; do printf '%s\t%s\n' "$o" "$dir" >> "$tmp"; done
  mv "$tmp" "$STATE"
}

launch() {
  pkill -f linux-wallpaperengine 2>/dev/null
  local present args=() line out dir
  present=$(hyprctl monitors -j 2>/dev/null | python3 -c 'import json,sys;[print(m["name"]) for m in json.load(sys.stdin)]' 2>/dev/null)
  while IFS=$'\t' read -r out dir; do
    [ -n "$out" ] && grep -qx "$out" <<<"$present" && [ -d "$dir" ] \
      && args+=(--screen-root "$out" --bg "$dir")
  done < "$STATE"
  [ ${#args[@]} -eq 0 ] && return
  setsid linux-wallpaperengine --assets-dir "$ASSETS" \
    --silent --fps 30 --disable-particles "${args[@]}" \
    >/tmp/wallpaper-engine.log 2>&1 &
}

seed

# status: show per-output mapping, marking which are live right now.
if [ "${1:-}" = "list" ] || [ "${1:-}" = "status" ]; then
  present=$(hyprctl monitors -j 2>/dev/null | python3 -c 'import json,sys;[print(m["name"]) for m in json.load(sys.stdin)]' 2>/dev/null)
  while IFS=$'\t' read -r out dir; do
    [ -n "$out" ] || continue
    grep -qx "$out" <<<"$present" && mark="●" || mark="○"
    title=$(python3 -c "import json;print(json.load(open('$dir/project.json')).get('title','?'))" 2>/dev/null)
    printf '%s %-18s %s  (%s)\n' "$mark" "$out" "$(basename "$dir")" "${title:-?}"
  done < "$STATE"
  echo "  ● live   ○ not connected"
  exit 0
fi

# post_command path: record the pick and re-apply, then exit.
if [ "${1:-}" = "set" ]; then
  set_wp "${2:-All}" "$(dirname "${3:?wallpaper path required}")"
  launch
  exit 0
fi

# autostart path: apply, then relaunch on any monitor add/remove.
launch
SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
python3 -c '
import socket,sys
s=socket.socket(socket.AF_UNIX); s.connect(sys.argv[1])
for line in s.makefile():
    if line.startswith(("monitoradded","monitorremoved")): print("go",flush=True)
' "$SOCK" 2>/dev/null | while read -r _; do
  sleep 1
  launch
done

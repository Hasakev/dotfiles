# Quickshell migration — phase 1

Goal: replace Waybar with a Quickshell bar in the Chongqing Nights style, plus
morphing popouts and a volume OSD. Dunst / rofi / wlogout stay for now.

- [x] Install quickshell + cava
- [x] Theme singleton (palette from waybar/style.css)
- [x] Bar per screen: launcher, weather, workspaces, window title | clock, media | audio, mic, net, bt, sys, awake, tray, power
- [x] Liquid workspace pill (leading edge fast, trailing edge slow)
- [x] Morphing popout: calendar, media, mixer, network/BT, weather
- [x] Cava visualizer in media pill + mirrored spectrum in media panel
- [x] Neon ignition on startup, stutter on hover, breathing clock border
- [x] Volume OSD (click-through overlay)
- [x] IPC + keybinds (Super+A media, Super+Shift+A mixer, Super+W network)
- [x] Super+1/2/3 fixed natively in hyprland.lua (view.sh is root-owned + uses dead syntax)
- [x] Autostart: waybar -> qs in hyprland.lua (backup: hyprland.lua.pre-quickshell)
- [x] Verify: launches clean, no QML warnings, panels screenshotted

## Review

Bugs found + fixed during verification:
- Two wifi cards see the same SSID; dedupe ran before sort and kept the inactive copy -> "Offline".
- Loader path casing ("media" -> mediaPanel.qml).
- QtQuick.Controls' Label shadowed ours in CalendarPanel -> namespaced import.
- MonthGrid collapses rows to 0px with a Rectangle delegate root; must be a Text.
- FileView reload() is async; reading text() right after gave "" -> NaN cpu. blockLoading.

Pre-existing bugs found:
- waybar temperature read thermal_zone0 = iwlwifi card, not the CPU (now k10temp).
- view.sh / view_group.sh use legacy `dispatch workspace N`, which errors under the lua config.

Open:
- Popout see-through: ROOT CAUSE FOUND (phase 5) — Hyprland blends in linear light; panels now solid.
- Not verified by real clicks (user was in a fullscreen app): hover stutter, slider drag,
  tray menus, OSD on volume keys.
- Dropped vs waybar: mic "live" indicator, network bandwidth tooltips.

# Phase 2 — system panel, launcher, optimisation

- [x] Clock: replace infinite breathing (12% CPU idle!) with a periodic neon glitch
- [x] Bar surfaces only grow to popout height while a panel is open (760px -> 48px)
- [x] Native Quickshell.Networking instead of nmcli polling; in-panel PSK entry
- [x] System panel: CPU/RAM/temp history graphs, per-core bars, GPU (nvidia-smi, only while open), top processes + kill
- [x] Launcher (Super+D, grows from launcher pill): fuzzy apps + frecency, icons, desktop actions, keyboard nav
  - [x] auto calculator  - [x] `;` clipboard (cliphist, also Super+V)  - [x] `>` run command
- [x] Measure: idle CPU 13% -> 0%, RSS 475MB -> 290MB (clean restart). Playing cost NOT measured.

## Review (phase 2)

Verified via a headless harness (panels rendered on HEADLESS-SUNSHINE, screenshotted) and
logic probes (search ranking, calculator incl. rejection of non-math input).

Bugs caught before they shipped:
- DesktopEntry.keywords is a list -> fuzzy() threw on the first keystroke.
- Fuzzy ranking let scattered matches beat word starts ("stm" -> SchedExt over Steam): gap penalty.
- Launcher icons: iconPath fallback syntax didn't resolve + anchors.fill requested 2x2 icons.
- Wi-Fi scanner request dropped if NM device appeared after the panel opened -> Binding.
- Quickshell.Networking is lazy: only connects on first access.

Not verified by real input (user was fullscreen in Discord): typing in the launcher, wifi
password entry, kill button, Super+D / Super+V binds end to end.


# Phase 3 — de-clanker the look

- [x] Palette: warm asphalt greys, off-white ink, ONE accent (sodium amber), neon pink = alerts only
- [x] Inter with tabular figures; icon glyphs on Symbols Nerd Font, muted
- [x] Bar = three glass islands (no per-module boxes/borders); hover plate, accent tint when open
- [x] Detail on demand: SSID, BT device, RAM, temp on hover; mic icon only when muted; slider dropped
- [x] Tray icons greyscale until hovered; window-title glyph dropped
- [x] Kept: Pac-Man (amber), liquid plate, island ignition, amber cava, clock glitch. Dropped hover stutter.
- [x] Panels + OSD restyled; glyphs moved to icon font (fixed tofu boxes in mixer)

Note: Theme keeps legacy names (cyan/teal/blue/...) as aliases onto the new roles so every
panel recoloured at once. Replace with role names (accent/alert/good/text...) when next touching a file.

# Phase 4 — blue + fixes

- [x] Super+D (and every keybind-opened panel) closed instantly: HyprlandFocusGrab armed during
      the layer-surface resize -> grab cleared. Now arms once the surface has expanded.
- [x] Palette back to blue: slate surfaces, cool ink, accent #6fa8ff; amber now a real warning colour.

# Phase 5 — enhancements

- [x] Window title: real app icon + click-to-open window switcher (all windows on the monitor, by workspace)
- [x] Power panel from the power button; hold-to-confirm for log out / reboot / shut down
- [x] hyprlock restyled (backup hyprlock.conf.pre-quickshell) — NOT verified (would lock the session)
- [x] Accent from HDMI-A-1 wallpaper preview; verified live switch incl. atomic mv of the map file
- [x] Notification centre replaced dunst: toasts, swipe, history, DND, Super+N, `qs ipc call notifs clear|toggleDnd`
      dunst D-Bus activation blocked via ~/.local/share/dbus-1/services/org.knopwob.dunst.service
- [x] Root cause of see-through panels: linear-light blending -> panels/toasts/OSD solid
- [x] Idle 0% CPU, RSS 325MB

Not verified by real input: notification action buttons/swipe, power tiles, window switcher click-to-focus.

# Phase 6 — user-reported issues

- [x] Tray icons unclickable: Pill's MouseArea was declared after its content, so it sat on top
      and ate every click. Now underneath; hover via passive HoverHandler. (Needs a real click to confirm.)
- [x] Media panel made low-key: square art, no spinning disc / blurred wash / big spectrum.
- [x] Accent: wallpaper hue clamped to 194°-216° (blues only).
- [x] Yeti Nano missing: mixer only showed the *default* source (G733). Added an input picker
      listing all sources (reusable DevicePicker for outputs + inputs).

# Phase 7 — media panel v3 + accent

- [x] Accent: wallpaper hue unclamped again (user: doesn't need to stay blue)
- [x] Media panel: 120px cover with blurred halo in the cover's colour, controls on hover,
      title in Inter Display, spectrum seek bar (48 cava bands, lit up to the playhead, click to seek),
      synced lyrics from lrclib.net (only fetched while panel open, cached per song)
- [x] Player.artColor (cover's prominent hue via shared Accent.vivid) tints panel + bar visualizer
- [x] Verified live with Spotify: cover colour, spectrum, lyrics in sync, log clean

# Phase 8 — detailed Wi-Fi breakdown (net panel)

All of it polled only while the net panel is open (`Net.detailed`, same pattern as `Sys.detailed`).
Quickshell.Networking has no band/channel/rate/IP, so: `nmcli` (AP list, IP/gw/DNS), `iw` (dBm, bitrate),
/sys byte counters (throughput), one long-running `ping` to the gateway (latency).

- [x] Net.qml: `detailed` flag; `link` {iface, freq, chan, dbm, rxRate, txRate, ip, gw, dns};
      `aps` ssid -> [{chan, freq, signal}] from `nmcli dev wifi list ifname <dev> --rescan no` every 5s
- [x] Net.qml: throughput from /sys/class/net/<if>/statistics rx/tx_bytes every 1s -> downHist/upHist
- [x] Net.qml: `ping -i 1 <gw>` Process + SplitParser -> pingHist, avg, jitter (restarts if gw changes)
- [x] Extract SysPanel's Card component to Card.qml (reused by NetPanel; SysPanel unchanged)
- [x] NetPanel: connected card at top: SSID, band/channel (+ "N other networks on ch X"), dBm,
      rx/tx link rate, security, IP/gw/DNS, internet state (Networking.connectivity)
- [x] NetPanel: throughput card (down/up Spark) + latency card (Spark, avg + jitter, amber/red when bad)
- [x] NetPanel rows: band + channel per SSID ("2.4G ch11 · 66%"; multi-band SSIDs show both)
- [x] Panel width 320 -> 380 so row details don't elide
- [x] Verify: qs log clean, screenshot of open panel, values match `iw`/`nmcli`/`ping` in a terminal;
      idle CPU unchanged with panel closed (no Processes running)
- [x] Root cause found while verifying: Bar never cleared `shown`, so a closed panel stayed loaded and
      its onDestruction never ran -> Sys's top/nvidia-smi, the wifi scanner (and the new ping) kept running
      after close. Now `shown` clears when shrinkDelay ends (popout fade is 260ms < 350ms).

Review: verified live (screenshots): values match `iw`/`nmcli`; ping + top start on open and are gone
1s after close; qs log clean. Panel's own scanning does NOT cause the latency spikes (106ms avg closed vs
32ms open) — wlan1 has power_save on, likely culprit.

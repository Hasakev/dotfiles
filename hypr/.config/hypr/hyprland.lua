-- Hyprland config (lua). Migrated from hyprland.conf for 0.55+, where hyprlang
-- is deprecated. See https://wiki.hypr.land/Configuring/Start/

local theme = require("theme")

------------------
---- MONITORS ----
------------------

hl.monitor({ output = "DP-1",      mode = "preferred",    position = "0x0",    scale = 1, transform = 3 })
hl.monitor({ output = "HDMI-A-1",  mode = "1920x1080@144", position = "1080x0", scale = 1 })

-- Rule for the virtual output the sunshine-headless service creates. Declaring
-- it here (not just in the service) is what forces scale 1 -- a headless output
-- created via `hyprctl output create` defaults to scale 2, and setting scale
-- AFTER creation races and doesn't stick. Hyprland applies this rule at
-- creation time, same as the physical monitors above.
hl.monitor({ output = "HEADLESS-SUNSHINE", mode = "1920x1080@60", position = "auto", scale = 1 })

-- Headless output + Sunshine are owned by the `sunshine-headless` systemd --user
-- service (WantedBy=default.target), NOT autostart. Hyprland boots with zero
-- outputs when the physical monitors are off, and never flushes its autostart
-- queue until an output exists -- the service creates the virtual output itself,
-- breaking that chicken-and-egg deadlock, and restarts sunshine if it dies.
-- Sunshine pins to this output via output_name=HEADLESS-SUNSHINE in sunshine.conf.

hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-1",     default = true })
hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "4", monitor = "DP-1" })
hl.workspace_rule({ workspace = "5", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "6", monitor = "DP-1" })
-- Dedicated remote workspace so Moonlight always lands somewhere known
hl.workspace_rule({ workspace = "7", monitor = "HEADLESS-SUNSHINE", default = true })


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local fileManager = "dolphin"
local menu        = "hyprlauncher"


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_THEME",    "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE",     "24")
hl.env("HYPRCURSOR_SIZE",  "24")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")

-- ---- IBus / Hyprland Wayland setup ----
-- Do NOT set GTK_IM_MODULE=ibus or QT_IM_MODULE=ibus on Wayland.
-- IBus specifically warns about this on newer versions.
hl.env("XMODIFIERS", "@im=ibus")
hl.env("SDL_IM_MODULE", "ibus")
hl.env("GLFW_IM_MODULE", "ibus")


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("qs")   -- Quickshell bar/popouts/OSD (~/.config/quickshell)
    hl.exec_cmd("hypridle")
    -- dunst removed: Quickshell owns org.freedesktop.Notifications (Notifs.qml)
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("sleep 1 && hyprpaper")

    -- Animated wallpapers (linux-wallpaperengine) layered over hyprpaper's static
    -- fallback, on both physical monitors and the Sunshine headless output.
    hl.exec_cmd("bash ~/.config/hypr/scripts/wallpaper-engine.sh")

    hl.exec_cmd("bash ~/.config/hypr/scripts/bt-connect.sh")      -- Bluetooth
    hl.exec_cmd("bash ~/.config/hypr/scripts/audio-opacity.sh")   -- Audio-aware opacity daemon

    -- Clipboard
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Portals
    hl.exec_cmd("sleep 1 && /usr/lib/xdg-desktop-portal-hyprland")

    -- Mouse
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")

    -- IBus
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XMODIFIERS SDL_IM_MODULE GLFW_IM_MODULE")
    hl.exec_cmd("sleep 2; ibus start --type wayland")
end)


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 4,

        border_size = 2,

        col = {
            active_border   = { colors = { theme.blue, theme.cyan }, angle = 45 },
            inactive_border = "rgba(ffffff10)",
        },

        resize_on_border = false,
        allow_tearing    = false,

        layout = "dwindle",
    },

    decoration = {
        rounding = 12,

        active_opacity   = 1.0,
        inactive_opacity = 0.8,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a, -- was rgba(1a1a1aee)
        },

        blur = {
            enabled           = true,
            size              = 6,
            passes            = 2,
            new_optimizations = true,
            xray              = false,
            vibrancy          = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = false,
    },

    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1} } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1} } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind("CTRL + ALT + T",  hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("vivaldi"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("qs ipc call bar toggle clipboard"))   -- launcher in clipboard mode (was wofi)
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("zeditor"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Real fullscreen (exclusive, best performance)
hl.bind("CTRL + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
-- Fake fullscreen (borderless / tiled)
hl.bind("CTRL + ALT + F",   hl.dsp.window.fullscreen({ mode = "fullscreen" }))

-- Minimize / restore
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.window.move({ workspace = "special" }))
hl.bind(mainMod .. " + M",         hl.dsp.workspace.toggle_special())
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.window.move({ workspace = "+0" }))

-- print screen
hl.bind("Print", hl.dsp.exec_cmd("grimblast copy area"))
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd([[grim -g "$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | "\(.x),\(.y) \(.width)x\(.height)"')" - | wl-copy]]))

-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    hl.bind(mainMod .. " + SHIFT + " .. (i % 10), hl.dsp.window.move({ workspace = i }))
end

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                 { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Workspace groups: HDMI-A-1 shows 2n-1, DP-1 shows 2n, switched together.
-- (Replaces scripts/view.sh, whose legacy dispatch syntax errors under lua.)
for n = 1, 3 do
    hl.bind(mainMod .. " + " .. n, function()
        hl.dispatch(hl.dsp.focus({ workspace = n * 2 - 1 }))
        hl.dispatch(hl.dsp.focus({ workspace = n * 2 }))
    end)
end

-- Quickshell panels
hl.bind(mainMod .. " + A",         hl.dsp.exec_cmd("qs ipc call bar toggle media"))
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd("qs ipc call bar toggle mixer"))
hl.bind(mainMod .. " + W",         hl.dsp.exec_cmd("qs ipc call bar toggle net"))
hl.bind(mainMod .. " + N",         hl.dsp.exec_cmd("qs ipc call bar toggle notifs"))

hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("qs ipc call bar toggle launcher"))   -- Quickshell launcher (was rofi drun)
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Frosted glass behind the Quickshell bar/popouts; they animate themselves.
hl.layer_rule({
    name  = "quickshell-glass",
    match = { namespace = "^quickshell" },
    blur         = true,
    ignore_alpha = 0.3,
    no_anim      = true,
})

hl.window_rule({
    name  = "spotify-player",
    match = { class = "^(spotify-player)$" },

    float  = true,
    center = true,
    size   = "470 940",
})

hl.window_rule({
    name  = "rofi",
    match = { class = "^(rofi)$" },

    float  = true,
    center = true,
})

hl.window_rule({
    -- Ignore maximize requests from all apps.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

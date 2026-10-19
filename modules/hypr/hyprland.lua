-- ~/.config/hypr/hyprland.lua
-- Converted from hyprlang (hyprland.conf) to Hyprland 0.55+ native Lua config.
-- Reference: https://wiki.hypr.land/Configuring/Start/
-- A few dispatcher names below (marked "VERIFY") aren't shown in the official
-- example config; check `hyprctl` / the LSP stubs in /usr/share/hypr/stubs
-- before trusting them blindly.

--------------------------------
---- ENVIRONMENT VARIABLES ----
--------------------------------
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1") -- Fix java wm bug
hl.env("AQ_TRACE", "1")
hl.env("ANKI_WAYLAND", "1") -- Set anki to wayland mode
hl.env("EGL_PLATFORM", "wayland") -- Set egl backend to wayland
hl.env("GBM_BACKEND", "nvidia-drm") -- nvidia gbm backend
hl.env("LIBVA_DRIVER_NAME", "nvidia") -- nvidia vaapi
hl.env("MOZ_DISABLE_RDD_SANDBOX", "1") -- Allow vaapi outside firefox rdd
hl.env("MOZ_ENABLE_WAYLAND", "1") -- Enable wayland on firefox
hl.env("NVD_BACKEND", "direct") -- Set libva-nvidia direct backend
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct") -- Set qt theme
hl.env("SSH_AUTH_SOCK", "$XDG_RUNTIME_DIR/gcr/ssh") -- GCR ssh keyring
hl.env("WLR_NO_HARDWARE_CURSORS", "1") -- Software cursors (nvidia bug)
hl.env("XCURSOR_THEME", "Simp1e") -- Set cursor theme
hl.env("XDG_SESSION_TYPE", "wayland") -- Set xdg type to wayland
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia") -- nvidia glx libraries
hl.env("XCURSOR_SIZE", "18") -- cursor size
hl.env("WINIT_UNIX_BACKEND", "wayland")
hl.env("WLR_BACKEND", "vulkan")
hl.env("WLR_RENDERER", "vulkan")
hl.env("DISPLAY", ":0")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("BROWSER", "google-chrome-stable")
hl.env("CHROMIUM_FLAGS", "--ozone-platform=wayland")

-------------------
---- AUTOSTART ----
-------------------
-- Things that should only run once, at Hyprland startup (old "exec-once").
hl.on("hyprland.start", function()
    hl.exec_cmd("xrandr --output DP-1 --primary")
    -- hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1") -- NixOS: polkit agent runs as a systemd user service
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("ssh-agent -a $XDG_RUNTIME_DIR/ssh-agent.socket")
    hl.exec_cmd('pass-cli ssh-agent load --vault-name "Personal"')

    hl.exec_cmd(os.getenv("HOME") .. "/.local/scripts/theming.sh") -- Theming script (gsettings, setcursor)
    -- hl.exec_cmd("/usr/lib/mate-polkit/polkit-mate-authentication-agent-1") -- Polkit for root escalation -- NixOS: polkit agent runs as a systemd user service
    hl.exec_cmd("vesktop --start-minimized") -- Discord
    hl.exec_cmd("xrandr --output DP-1 --primary") -- Set Xwayland primary monitor (duplicate of above, kept as in original)
    -- hl.exec_cmd("teams-for-linux --start-minimized") -- Start teams on startup
    hl.exec_cmd("steam --start-minimized")
    hl.exec_cmd("qbittorrent")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("signal-desktop")
end)

-- Old plain "exec" (relaunch.sh restarts quickshell/swaybg -- both once at cold
-- boot AND on every subsequent reload). A bare top-level call runs while the
-- config is still being parsed, before the Wayland socket is ready for a
-- client like the bar to connect -- that's what caused it to be missing on
-- fresh launch until a manual reload. Firing it from both lifecycle events
-- instead means it's reliable at boot AND still restarts on reload/theme
-- changes, matching the original intent.
local function relaunchBar()
    hl.exec_cmd(os.getenv("HOME") .. "/.local/scripts/relaunch.sh")
end
hl.on("hyprland.start", relaunchBar)
hl.on("config.reloaded", relaunchBar)

------------------
---- CURSOR ------
------------------
hl.config({
    cursor = {
        no_hardware_cursors = true,
    },
})

------------------
---- MONITORS ----
------------------
-- Pivoted monitor on the left, main monitor to the right (see original comment)
hl.monitor({
    output = "DP-1",
    mode = "3440x1440@165",
    position = "0x0",
    scale = 1,
    bitdepth = 10,
})
-- HDMI monitor (commented out but preserved from original config)
-- hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "0x0", scale = 1 })

hl.config({
    render = {
        direct_scanout = false,
        -- cm_fs_passthrough = 0,
        cm_auto_hdr = 0, -- or 2 if you want hdredid instead of hdr
    },
})

------------------
---- XWAYLAND ----
------------------
hl.config({
    xwayland = {
        enabled = true,
        force_zero_scaling = true,
        use_nearest_neighbor = false,
    },
})

---------------
---- INPUT ----
---------------
hl.config({
    input = {
        repeat_rate = 50,
        repeat_delay = 375,
        follow_mouse = 1, -- Disable follow mouse for window focus
        sensitivity = -0.5, -- Reduce sensitivity
        force_no_accel = 1,
        float_switch_override_focus = 0,
        kb_layout = "se",
    },
})

-------------------
---- GENERAL ------
-------------------
hl.config({
    general = {
        gaps_out = 4, -- Outer monitor gaps
        gaps_in = 2, -- Inner window gaps
        border_size = 3, -- Set window border width
        col = {
            -- Active border colour (gradient)
            active_border = { colors = { "0xff7aa2f7", "0xff7dcfff" }, angle = 45 },
            -- Inactive gray
            inactive_border = "0xff171a1f",
        },
        -- resize_on_border = false, -- ("no_border_on_floating" had no direct new equivalent found; verify)
        layout = "dwindle", -- Set default layout
    },
})

----------------
---- MISC ------
----------------
hl.config({
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        animate_mouse_windowdragging = false,
        mouse_move_enables_dpms = false,
        mouse_move_focuses_monitor = true,
        focus_on_activate = true,
        enable_swallow = false, -- Disable window swallowing
        -- vfr = false, -- Enable variable framerate
        vrr = 0, -- Enable variable refresh rate
    },
})

--------------------
---- DECORATION ----
--------------------
hl.config({
    decoration = {
        rounding = 5, -- Disable rounding
        -- shadow = {
        --     enabled = true,
        --     range = 4,
        --     render_power = 2,
        --     color = 0x66000000,
        -- },
        -- blur = {
        --     enabled = true,
        --     size = 1,
        --     passes = 3,
        --     -- xray = true,
        -- },
    },
})

hl.layer_rule({
    name = "blur-waybar",
    match = { namespace = "waybar" },
    blur = true,
})

hl.layer_rule({
    name = "blur-quickshell-bar",
    match = { namespace = "quickshell-bar" },
    blur = true,
})

--------------------
---- ANIMATIONS ----
--------------------
hl.config({
    animations = {
        enabled = false,
    },
})
-- Curve/animation definitions were commented out in the original config,
-- so nothing further to port here. See:
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/

------------------
---- DWINDLE -----
------------------
hl.config({
    dwindle = {
        -- no_gaps_when_only = false,
        preserve_split = true, -- you probably want this
    },
})

------------------------------------
---- WINDOW / LAYER RULES ----------
------------------------------------
-- Float common dialogs by class
local floatClasses = { "file_progress", "confirm", "dialog", "download", "notification", "error", "splash", "confirmreset" }
for _, class in ipairs(floatClasses) do
    hl.window_rule({
        name = "float-" .. class,
        match = { class = "^(" .. class .. ")$" },
        float = true,
    })
end

hl.window_rule({
    name = "steam-app-monitor",
    match = { class = "^(steam_app_\\d+)$" },
    monitor = "DP-1",
})

-- Chiaki
-- hl.window_rule({ name = "chiaki-immediate", match = { class = "chiaki" }, immediate = true, no_anim = true, no_blur = true, fullscreen = true })
-- hl.window_rule({ name = "chiaki-opacity", match = { class = "chiaki" }, opacity = { value = 1.0, override = true } })

-- Float dialogs by title
hl.window_rule({
    name = "float-open-file",
    match = { title = "^(Open File)$" },
    float = true,
})
hl.window_rule({
    name = "float-branchdialog",
    match = { title = "^(branchdialog)$" },
    float = true,
})

-- Float specific apps
hl.window_rule({
    name = "float-pavucontrol",
    match = { class = "^(pavucontrol)$" },
    float = true,
})
hl.window_rule({
    name = "float-file-roller",
    match = { class = "^(file-roller)$" },
    float = true,
})

-- Idle inhibit
hl.window_rule({
    name = "idle-inhibit-mpv",
    match = { class = "^(mpv)$" },
    idle_inhibit = "focus",
})
hl.window_rule({
    name = "idle-inhibit-firefox",
    match = { class = "^(firefox)$" },
    idle_inhibit = "fullscreen",
})
hl.window_rule({
    name = "idle-inhibit-chromium",
    match = { class = "^(chromium)$" },
    idle_inhibit = "fullscreen",
})
hl.window_rule({
    name = "idle-inhibit-chrome",
    match = { class = "^(google-chrome-stable)$" },
    idle_inhibit = "fullscreen",
})

-- Force tiling
hl.window_rule({
    name = "tile-popcorn-time",
    match = { class = "^(Popcorn-Time)$" },
    tile = true,
})

------------------------
---- WORKSPACE RULES ----
------------------------
-- Alternating workspaces for dual monitor setup was the intent in the
-- original comment, but all 9 lines pinned every workspace to DP-1.
for i = 1, 9 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "DP-1" })
end

---------------------
---- KEYBINDINGS ----
---------------------
-- SUPER CTRL, V — Clipboard manager
hl.bind("SUPER + CTRL + V", hl.dsp.exec_cmd("qs ipc call clipboard toggle"))

-- Media keys (mpc)
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd("mpc next"))
hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("mpc prev"))
hl.bind("SUPER + I", hl.dsp.exec_cmd("mpc toggle"))
-- hl.bind("SUPER + SHIFT + K", hl.dsp.exec_cmd("mpc pause"))

-- Screenshots
local scriptDir = os.getenv("HOME") .. "/.local/scripts/screenshot-wayland-local.sh"
hl.bind("Print", hl.dsp.exec_cmd(scriptDir .. " --monitor"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(scriptDir .. " --selection"))
hl.bind("SUPER + Print", hl.dsp.exec_cmd(scriptDir .. " --active"))

-- Apps
hl.bind("SUPER + N", hl.dsp.exec_cmd("thunar"))
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("ghostty"))
hl.bind("SUPER + B", hl.dsp.exec_cmd("librewolf"))
hl.bind("SUPER + W", hl.dsp.exec_cmd("vesktop"))
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("qs ipc call launcher toggle"))
hl.bind("SUPER + SHIFT + SPACE", hl.dsp.exec_cmd("qs ipc call powermenu toggle"))
-- VERIFY: no confirmed native "reload" dispatcher in the docs I could check;
-- shelling out to hyprctl still works fine.
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind("SUPER + O", hl.dsp.exec_cmd("google-chrome-stable"))
hl.bind("SUPER + SHIFT + RETURN", hl.dsp.exec_cmd("alacritty -e nvim ~/.config/hypr/hyprland.lua"))

-- Volume (repeating, like the old "binde")
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/scripts/volume.sh up"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/scripts/volume.sh down"), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/scripts/volume.sh mute"), { repeating = true })

-- Window management
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ action = "toggle" })) -- VERIFY: exact fullscreen() signature
hl.bind("SUPER + Tab", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + P", hl.dsp.window.pseudo()) -- dwindle
hl.bind("SUPER + S", hl.dsp.layout("togglesplit")) -- dwindle

-- Lock screen
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd("hyprlock"))

-- Focus movement
hl.bind("SUPER + H", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + L", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + K", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + J", hl.dsp.focus({ direction = "down" }))

-- Move window between tiles
-- VERIFY: hl.dsp.window.move() is confirmed for moving to a workspace;
-- directional move is inferred by analogy with hl.dsp.focus().
hl.bind("SUPER + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind("SUPER + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind("SUPER + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + SHIFT + J", hl.dsp.window.move({ direction = "down" }))

-- Resize active window (repeating)
-- Hyprland's own error output confirmed the real signature: positional
-- x/y (not dx/dy) or a keep_aspect_ratio flag.
hl.bind("SUPER + CTRL + H", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + CTRL + L", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + CTRL + K", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
hl.bind("SUPER + CTRL + J", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })

-- Switch workspaces
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind("SUPER + ALT + up", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + ALT + down", hl.dsp.focus({ workspace = "e-1" }))

-- Mouse-driven move/resize + scroll workspace switching
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

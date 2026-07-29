-- Hyprland Lua config — migrated from hyprland.conf
-- Refer to https://wiki.hypr.land/0.56.0/Configuring/Start/
-- Hyprland 0.56.1 | Bright Scar

------------------
---- MONITORS ----
------------------

require("monitors")

---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local fileManager = "dolphin"
local menu        = "hyprlauncher"
local editor      = "nvim ."
local explorer    = "dolphin"
local browser     = "zen-browser"

-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/0.56.0/Configuring/Basics/Autostart/
hl.on("hyprland.start", function()
    hl.exec_cmd(terminal)
    hl.exec_cmd("quickshell")
    hl.exec_cmd("mullvad-daemon")
    hl.exec_cmd("udiskie --tray --notify")
    hl.exec_cmd("kdeconnectd")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("systemctl --user start hyprpolkitagent.service 2>/dev/null || hyprpolkitagent")
end)

-- Quickshell blur layer rule
hl.layer_rule({
    name = "quickshell-blur",
    match = { namespace = "^quickshell:" },
    blur = true,
})

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/0.56.0/Configuring/Advanced-and-Cool/Environment-variables/
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Flatpak desktop entry / icon discovery
hl.env("XDG_DATA_DIRS",
    "/var/lib/flatpak/exports/share:" ..
    "/home/nero/.local/share/flatpak/exports/share:" ..
    "/usr/local/share:/usr/share:" ..
    "/home/nero/.nix-profile/share:" ..
    "/nix/var/nix/profiles/default/share")

-- NVIDIA multi-GPU configuration
require("nvidia")

-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/0.56.0/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart
-- and are not applied on-the-fly for security reasons

-- hl.config({
--     ecosystem = { enforce_permissions = true },
-- })
-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

-----------------------
---- LOOK AND FEEL ----
-----------------------

require("theme")

-------------
--- INPUT ---
-------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
})

-- See https://wiki.hypr.land/0.56.0/Configuring/Advanced-and-Cool/Gestures/
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

---------------------
---- KEYBINDINGS ----
---------------------

require("keybindings")

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/0.56.0/Configuring/Basics/Window-Rules/
-- See https://wiki.hypr.land/0.56.0/Configuring/Basics/Workspace-Rules/

-- Ignore maximize requests from all apps
hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name = "fix-xwayland-drags",
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

-- Hyprland-run windowrule
hl.window_rule({
    name = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})
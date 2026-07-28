# Hyprland .conf → .lua Migration Plan

## STATUS: PLAN ONLY — DO NOT EXECUTE YET

## Current State

- **Running:** Hyprland 0.56.1
- **Config entry:** `~/.config/hypr/hyprland.conf` (hyprlang format)
- **Warning:** "You are using the .conf config format, support for which will be removed in Hyprland 0.57"
- **Deadline:** 0.57 release (estimated weeks, not months — Hyprland ships roughly monthly)

## What Needs Migration (Hyprland core only)

These files use hyprlang syntax and are sourced by `hyprland.conf`:

| File | Role | Migrate? |
|------|------|----------|
| `hyprland.conf` | Entry point | YES → `hyprland.lua` |
| `theme.conf` | Look & feel, animations, layouts, misc, cursor | YES → `theme.lua` |
| `keybindings.conf` | All binds | YES → `keybindings.lua` |
| `nvidia.conf` | Env vars + cursor setting | YES → `nvidia.lua` |
| `monitors_positioning.conf` | Monitor rules | YES → `monitors.lua` |
| `flatpak.conf` | Single env var | YES → inline in `hyprland.lua` |
| `workflows/*.conf` | 5 workflow profiles | DEFER — not sourced by hyprland.conf, loaded externally by quickshell/HyDE |
| `animations/theme.conf` | DEPRECATED, not sourced | SKIP — already dead |
| `themes/theme.conf` | DEPRECATED, HyDE artifact | SKIP — already dead |
| `themes/colors.conf` | DEPRECATED, empty | SKIP — already dead |
| `themes/wallbash.conf` | DEPRECATED, HyDE artifact | SKIP — already dead |
| `hyprland-gui.conf` | HyprMod generated, commented out | SKIP — not sourced |

## What Does NOT Migrate (separate apps, own config formats)

| File | App | Why |
|------|-----|-----|
| `hypridle.conf` | hypridle | Separate binary, uses its own hyprlang config |
| `hyprlock.conf` + `hyprlock/miku.conf` | hyprlock | Separate binary, uses its own hyprlang config |
| `hyprpaper.conf` | hyprpaper | Separate binary, uses its own hyprlang config |
| `pyprland.toml` | pyprland | Separate community project, TOML format |
| `scripts/reload-monitors.sh` | Bash script | Not a config, stays as-is |
| `shaders/*.frag` | GLSL shaders | Binary assets, not hyprlang |

## Syntax Translation Reference

Verified against wiki.hypr.land/0.56.0 and /usr/share/hypr/hyprland.lua

### Variables
```
# OLD (.conf)
$terminal = kitty
$menu = hyprlauncher

-- NEW (.lua)
local terminal = "kitty"
local menu = "hyprlauncher"
```

### Config blocks
```
# OLD
general {
    gaps_in = 2
    layout = dwindle
}

-- NEW
hl.config({
    general = {
        gaps_in = 2,
        layout = "dwindle",
    }
})
```

### Colors (gradients)
```
# OLD
col.active_border = rgba(00c8aaee) rgba(b589d6ee) 45deg

-- NEW
col = {
    active_border = { colors = { "rgba(00c8aaee)", "rgba(b589d6ee)" }, angle = 45 },
    inactive_border = "rgba(595959aa)",
},
```

### Environment variables
```
# OLD
env = LIBVA_DRIVER_NAME,nvidia

-- NEW
hl.env("LIBVA_DRIVER_NAME", "nvidia")
```

### Sourcing files
```
# OLD
source = ~/.config/hypr/nvidia.conf

-- NEW
require("nvidia")
-- or: require("./nvidia")
-- relative to hyprland.lua location
```

### Binds
```
# OLD
bind = $mainMod, Q, killactive,
bind = $mainMod, R, exec, $menu

-- NEW
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + R", hl.dsp.exec_cmd(menu))
```

### Bind flags
```
# OLD: bindel = ,XF86AudioRaiseVolume, exec, ...
-- NEW: hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("..."), { locked = true, repeating = true })

# OLD: bindl = ,XF86AudioNext, exec, ...
-- NEW: hl.bind("XF86AudioNext", hl.dsp.exec_cmd("..."), { locked = true })
```

### Mouse binds
```
# OLD: bindm = $mainMod, mouse:272, movewindow
-- NEW: hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
```

### Window rules
```
# OLD
windowrule {
    name = suppress-maximize-events
    match:class = .*
    suppress_event = maximize
}

-- NEW
hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})
```

### Layer rules
```
# OLD
layerrule {
    name = quickshell-blur
    match:namespace = ^quickshell:
    blur = true
}

-- NEW
hl.layer_rule({
    name = "quickshell-blur",
    match = { namespace = "^quickshell:" },
    blur = true,
})
```

### Monitors
```
# OLD
monitor=eDP-1, 2560x1600@240, 0x0, 1.6

-- NEW (syntax from official example config)
hl.monitor({
    output = "eDP-1",
    mode = "2560x1600@240",
    position = "0x0",
    scale = 1.6,
})
```

### Workspace rules
```
# OLD
workspace = 1, monitor:eDP-1

-- NEW
hl.workspace_rule({
    workspace = 1,
    monitor = "eDP-1",
})
```

### Autostart (exec-once)
```
# OLD
exec-once = kitty
exec-once = quickshell

-- NEW
hl.on("hyprland.start", function()
    hl.exec_cmd("kitty")
    hl.exec_cmd("quickshell")
    hl.exec_cmd("mullvad-daemon")
    hl.exec_cmd("udiskie --tray --notify")
    hl.exec_cmd("kdeconnectd")
    hl.exec_cmd("wl-paste --watch cliphist store")
    pcall(os.execute, "systemctl --user start hyprpolkitagent.service 2>/dev/null || hyprpolkitagent &")
end)
```

### Gestures
```
# OLD
gesture = 3, horizontal, workspace

-- NEW
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})
```

### Animations (curves + animation entries)
```
# OLD
bezier = easeOutQuint, 0.23, 1, 0.32, 1
animation = global, 1, 7, default

-- NEW
hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.animation({ leaf = "global", enabled = true, speed = 7, bezier = "default" })
```

## Safety Strategy

1. **Keep .conf files in place** — do NOT delete them until .lua is verified
2. **Create .lua files alongside** — Hyprland checks for .lua FIRST, falls back to .conf
3. **Test incrementally** — after writing hyprland.lua, run `hyprctl reload` and check for errors
4. **If .lua fails** — delete it, .conf fallback kicks in automatically
5. **Stow will handle both** — both .conf and .lua in the repo, stow symlinks both
6. **Git branch** — all work on `hypr-lua-migration` branch, merge only after verified

## File Mapping

### New files to create:

```
hypr/.config/hypr/
├── hyprland.lua          (entry point — replaces hyprland.conf)
├── monitors.lua          (from monitors_positioning.conf)
├── nvidia.lua            (from nvidia.conf)
├── theme.lua             (from theme.conf)
└── keybindings.lua       (from keybindings.conf)
```

### Files that stay unchanged:
- hypridle.conf, hyprlock.conf, hyprlock/miku.conf, hyprpaper.conf
- pyprland.toml, scripts/, shaders/
- workflows/*.conf (not Hyprland config, loaded externally)
- animations/*.conf (not sourced by active config)
- themes/*.conf (all DEPRECATED)

### Old files to keep (as fallback):
- hyprland.conf, monitors_positioning.conf, nvidia.conf, theme.conf, keybindings.conf, flatpak.conf

## Verification Steps

After creating all .lua files:

1. `hyprctl reload` — must return "ok"
2. `hyprctl getoption general:gaps_in` — must return 2
3. `hyprctl getoption decoration:rounding` — must return 20
4. `hyprctl getoption cursor:no_hardware_cursors` — must return 1 (true)
5. `hyprctl getoption general:allow_tearing` — must return 1 (true)
6. `hyprctl monitors` — must show eDP-1 at 2560x1600@240, scale 1.6
7. Check warning banner is gone
8. Test key binds: SUPER+R (launcher), SUPER+Q (close), SUPER+L (lock)
9. Test volume keys, brightness keys
10. If anything breaks: `rm ~/.config/hypr/hyprland.lua` → instant fallback to .conf
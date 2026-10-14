-- Keybindings — migrated from keybindings.conf
-- See https://wiki.hypr.land/0.56.0/Configuring/Basics/Binds/

local mainMod = "SUPER"

-- Variables
local editor   = "nvim ."
local explorer = "dolphin"
local browser  = "zen-browser"

----------------###
--- KEYBINDINGS ---###
----------------###

-- Launch apps and manage windows
hl.bind(mainMod .. " + code:36", hl.dsp.exec_cmd("kitty"))          -- Terminal (keycode 36 = T)
hl.bind(mainMod .. " + Q", hl.dsp.window.close())                    -- killactive
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(explorer))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" })) -- togglefloating
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("hyprlauncher"))           -- Hyprlauncher
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())                    -- dwindle pseudo
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))             -- dwindle togglesplit
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("hyprlauncher"))          -- Hyprlauncher desktop entries
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))               -- Lock the screen
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("hyprshutdown"))   -- Graceful Hyprland exit
hl.bind(mainMod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("wlogout -p layer-shell -c 30 -r 30"))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("killall quickshell && quickshell"))
hl.bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end)
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("killall hyprpaper && hyprpaper"))
hl.bind("SUPER + F", hl.dsp.window.float({ action = "toggle" }))

-- Hypr native tools
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("ronema"))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("hyprlauncher --provider emoji"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("killall hyprsunset 2>/dev/null || hyprsunset -t 3500"))

-- Screen capture
hl.bind("Print", hl.dsp.exec_cmd(
    'grimblast copy area && notify-send -u low -t 1500 "Screen Shoot" "Copied to clipboard"'))

-- Laptop lid switch: disable internal panel when closed, re-enable on open.
-- Lua-era switch keys are INFIX (switch:on:<name>), not .conf suffix form
-- (verified against Hyprland 0.56.2 source, KeybindManager.cpp:536-546).
-- Polarity: lid CLOSE fires :on, lid OPEN fires :off (libinput switch state).
-- Re-enable carries the FULL spec (idempotent — guards against auto-placement).

-- Panel seat is LOCATION-DEPENDENT under the nwg-displays profile workflow
-- (0x0 at away locations so auto-left-docked externals sit flush against
-- the panel's left edge; 3840x0 at home). The open path restores the seat
-- captured at close instead of a hardcoded coordinate. Same-tick reads in
-- the close handler see the PRE-transition layout — exactly the settled
-- seat to restore. Boot with lid already closed fires no switch transition,
-- so hyprland.lua's start block calls capturePanelSeat() before disabling.
panelSeat = "3840x0" -- global: hyprland.lua's start block reads it too
function capturePanelSeat()
    local m = hl.get_monitor("eDP-1")
    if m then panelSeat = m.x .. "x" .. m.y end
end

-- Layer-heal: Hyprland 0.56.x does NOT reposition layer-shell surfaces
-- (quickshell bar, hyprpaper) when a monitor is disabled programmatically —
-- upstream discussion #15760, unfixed as of 0.56.2. The surviving monitor
-- re-seats to the origin but the bar keeps stale coordinates, rendering
-- half off-screen. A 1px position wiggle forces real moves, which layers
-- DO follow, re-anchoring them. The return move re-asserts the monitor's
-- SEAT from the table below: fixed coordinates for the Loja heads (the
-- panel disable can re-seat survivors to the origin, so explicit seats
-- guarantee truth), auto-side for the workshop (origin contract). Heads
-- absent from the table keep their current x,y — home heads re-seat
-- exactly where nwg-displays placed them.
local lidSides = {
    ["LG Electronics LG SMART WQHD 0x01010101"] = "0x0",       -- loja: 34" leftmost
    ["LG Electronics LG ULTRAWIDE 0x0005EAFC"]  = "3440x0",    -- loja: portrait right
    ["LG Electronics 25UM58G 0x01010101"]       = "auto-left", -- workshop
}

local function lidHealLayers()
    for _, m in ipairs(hl.get_monitors()) do
        if m.name ~= "eDP-1" and m.name ~= "FALLBACK" then
            local side = lidSides[tostring(m.description)]
            local x, y = m.x, m.y
            -- wiggle out 1px now (real move), return via timer (real move).
            -- Same-tick moves coalesce; the timer guarantees both render.
            hl.monitor({ output = m.name, position = (x + 1) .. "x" .. y })
            hl.timer(function()
                hl.monitor({ output = m.name, position = side or (x .. "x" .. y) })
            end, { timeout = 150, type = "oneshot" })
        end
    end
end

hl.bind("switch:on:Lid Switch", function()
    capturePanelSeat()
    hl.monitor({ output = "eDP-1", disabled = true })
    lidHealLayers()
end, { locked = true })

hl.bind("switch:off:Lid Switch", function()
    hl.monitor({ output = "eDP-1", mode = "2560x1600@240", position = panelSeat, scale = 1.6, disabled = false })
    -- Defer the heal: on lid-open the surviving monitor's auto-side re-seat
    -- is still pending when the bind body runs. Reading m.x in this tick
    -- captures the stale lid-closed position and the 1px wiggle lands inside
    -- eDP-1's zone -> transient overlap warning (i18n Engine.cpp:246).
    -- Heal 250ms later, when the re-seat has settled: fresh read, and the
    -- wiggle can never overlap. Close path needs no delay — eDP-1 is out of
    -- the layout when its wiggle fires, so there is nothing to overlap.
    hl.timer(function() lidHealLayers() end, { timeout = 250, type = "oneshot" })
end, { locked = true })

-- Force hyprctl reload
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd('hyprctl reload && notify-send -t 1500 "Reloaded" "hyprctl"'))

-- Hot reload monitor config only
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("bash $HOME/.config/hypr/scripts/reload-monitors.sh"))

-- Move focus with arrows
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left"  }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up"   }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down"  }))

-- Workspace navigation + move windows (loop: keys 1-9 and 0 for workspace 10)
for i = 1, 10 do
    local key = tostring(i % 10) -- 10 maps to key 0
    hl.bind(mainMod       .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod           .. " + S",       hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move and resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true }) -- LMB
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true }) -- RMB

-- Multimedia and brightness keys
local vol_flags = { locked = true, repeating = true }

hl.bind("XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), vol_flags)
hl.bind("XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), vol_flags)
hl.bind("XF86AudioMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), vol_flags)
hl.bind("XF86AudioMicMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), vol_flags)
hl.bind("XF86MonBrightnessUp",
    hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), vol_flags)
hl.bind("XF86MonBrightnessDown",
    hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), vol_flags)

-- Media controls using playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
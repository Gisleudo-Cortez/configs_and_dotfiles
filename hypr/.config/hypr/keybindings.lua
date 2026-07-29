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
hl.bind("Print", hl.dsp.exec_cmd('grimblast copy area && notify-send -u low -t 1500 "Screen Shoot" "Copied to clipboard"'))

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
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Media controls using playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
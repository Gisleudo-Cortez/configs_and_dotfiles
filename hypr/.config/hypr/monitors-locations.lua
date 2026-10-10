-- Portable monitor entries + workspace pin — deliberately SEPARATE from
-- monitors.lua: nwg-displays regenerates monitors.lua on every GUI Apply
-- (writing only the currently-connected heads, connector-named), which
-- strips anything else living there. Disconnected desc:-matched entries
-- auto-skip while absent, so listing every known location is safe.
--
-- The home layout (panel + portrait G5 + LG) is owned by monitors.lua.

-- WORK - LG ULTRAWIDE (disconnected at home, active at work)
hl.monitor({
    output   = "desc:LG Electronics LG ULTRAWIDE 0x0005EAFC",
    mode     = "2560x1080@74.99",
    position = "auto-left",
    scale    = 1,
})

-- Workshop - LG Electronics 25UM58G
hl.monitor({
    output   = "desc:LG Electronics 25UM58G 0x01010101",
    mode     = "2560x1080@74.99100",
    position = "auto-left",
    scale    = 1,
})

-- Pin workspace 1 to the built-in display so it always opens there.
hl.workspace_rule({
    workspace = "1",
    monitor   = "eDP-1",
})
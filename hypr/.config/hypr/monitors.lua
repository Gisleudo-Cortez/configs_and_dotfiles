-- Monitor positioning — migrated from monitors_positioning.conf
-- See https://wiki.hypr.land/0.56.0/Configuring/Basics/Monitors/

-- Laptop + variable external displays.
-- Both the work LG ULTRAWIDE and the home LG SMART WQHD are listed here.
-- Hyprland auto-skips disconnected description-based monitor entries; only
-- the currently connected external monitor will be activated. Using "auto"
-- for all positioning prevents cursor-barrier bugs caused by conflicting
-- directional hints (auto-left vs auto-right) when only one external is
-- connected.

-- LAPTOP SCREEN - always present
hl.monitor({
    output   = "eDP-1",
    mode     = "2560x1600@240",
    position = "0x0",
    scale    = 1.6,
})

-- Pin workspace 1 to the built-in display so it always opens there.
hl.workspace_rule({
    workspace = "1",
    monitor   = "eDP-1",
})

-- WORK - LG ULTRAWIDE (disconnected at home, active at work)
hl.monitor({
    output   = "desc:LG Electronics LG ULTRAWIDE 0x0005EAFC",
    mode     = "2560x1080@74.99",
    position = "auto-left",
    scale    = 1,
})

-- HOME - LG SMART WQHD (disconnected at work, active at home)
hl.monitor({
    output   = "desc:LG Electronics LG SMART WQHD 0x01010101",
    mode     = "3440x1440@99.8",
    position = "auto-right",
    scale    = 1,
})

-- Workshop - LG Electronics 25UM58G
hl.monitor({
    output   = "desc:LG Electronics 25UM58G 0x01010101",
    mode     = "2560x1080@74.99100",
    position = "auto-left",
    scale    = 1,
})
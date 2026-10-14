-- Away-location monitor profiles — deliberately SEPARATE from monitors.lua:
-- nwg-displays regenerates monitors.lua on every GUI Apply / profile load
-- (writing only the currently-connected heads, connector-named), which
-- strips anything else living there. Disconnected desc:-matched entries
-- auto-skip while absent, so every location can stay listed.
--
-- PROFILE WORKFLOW (~/.config/nwg-displays/profiles/, stowed into the repo):
--   Each location owns a profile — "Loja" (store), "Casa" (home). Applying
--   one in nwg-displays regenerates monitors.lua with that location's
--   layout. Apply the matching profile after changing locations.
--
-- GEOMETRY:
--   * LOJA runs lid-closed on two externals (since 2026-10-14): the 34"
--     LG SMART WQHD leftmost at 0x0, the LG ULTRAWIDE portrait
--     (transform 1) at 3440x0, flush right of the 34". The Loja profile
--     carries the panel as active:false; the lid-close bind disables it
--     live, and the boot-with-lid-closed hook covers cold starts.
--   * The origin contract (panel at 0x0, externals auto-left) still
--     governs the WORKSHOP: directional autos dock relative to the layout
--     ORIGIN, not to other monitors (live-verified 0.56.2; wiki: "the
--     left monitors will just be left of the origin").
--   * Home ("Casa") keeps its own coordinates; lines for heads that live
--     elsewhere are inert there.
--
-- The lid-open re-enable restores the seat captured at lid-close
-- (keybindings.lua: capturePanelSeat) — no hardcoded panel coordinate.

-- LOJA — LG SMART WQHD 34" (3440x1440, leftmost, landscape)
hl.monitor({
    output   = "desc:LG Electronics LG SMART WQHD 0x01010101",
    mode     = "3440x1440@99.98",
    position = "0x0",
    scale    = 1,
})

-- LOJA — LG ULTRAWIDE (2560x1080, portrait, flush right of the 34")
hl.monitor({
    output   = "desc:LG Electronics LG ULTRAWIDE 0x0005EAFC",
    mode     = "2560x1080@74.99",
    position = "3440x0",
    scale    = 1,
    transform = 1,
})

-- WORKSHOP — LG 25UM58G (origin contract: auto-left of the origin panel)
-- Serial 0x01010101 is a real EDID serial on LG heads that report none
-- (the 34" SMART WQHD carries the same string) — verify this unit's exact
-- description with `hyprctl monitors` at the workshop and correct if needed.
hl.monitor({
    output   = "desc:LG Electronics 25UM58G 0x01010101",
    mode     = "2560x1080@74.99100",
    position = "auto-left",
    scale    = 1,
})

-- Pin workspace 1 to the built-in display so it always opens there.
-- (Migrates to a surviving head while the panel is disabled at the Loja.)
hl.workspace_rule({
    workspace = "1",
    monitor   = "eDP-1",
})
# Display profiles — nwg-displays package

~/.config/nwg-displays is a directory symlink into this package (GNU Stow),
so the tool's config, every profile save, and active_profile.json land in
the repo as diffs. nwg-displays ignores this README; it is repo-only
documentation.

## Profile workflow

One profile per location. Apply the matching profile in nwg-displays after
changing locations — an Apply auto-runs hyprctl reload and writes both
monitors.conf and monitors.lua through the stow symlinks.

- Loja.json — store: panel at 0x0, LG ULTRAWIDE docks auto-left at -2560x0
- Casa.json — home: 3-head (panel 3840x0, G5 portrait 5440x0, LG 6880x710)

The away-head rules (desc-matched, auto-left) live in the hypr package:
hypr/.config/hypr/monitors-locations.lua. Origin contract documented there:
directional autos dock relative to the layout origin, so away profiles seat
the panel at 0x0.

## Confirmed monitor descriptions (hyprctl monitors)

| Head | Description string | Status |
|------|--------------------|--------|
| eDP-1 — built-in panel | BOE 0x0A99 | verified 2026-10-14 |
| Store LG ULTRAWIDE (HDMI-A-1) | LG Electronics LG ULTRAWIDE 0x0005EAFC | verified 2026-10-14 |
| Home G5 (HDMI-A-1) | PLACEHOLDER in Casa.json | capture at home |
| Home LG (DP-1) | PLACEHOLDER in Casa.json (serial hint 0x9195A922) | capture at home |
| Workshop LG 25UM58G | placeholder serial 0x01010101 in monitors-locations.lua | capture at workshop |

## Home-session checklist (completes the desc migration)

1. `hyprctl monitors` — copy the description lines for the G5 (HDMI-A-1,
   portrait 2560x1440@144) and the home LG (DP-1, 2560x1080@100). The
   serial hint from git history is 0x9195A922 — verify against live output,
   do not trust the hint.
2. Replace the two placeholder descriptions in profiles/Casa.json.
3. Flip use-desc to true in BOTH places that matter:
   - this package's `config` file (drives the GUI Apply writer), and
   - the "config" block embedded in EACH profile JSON (profile loads read
     use-desc from the profile, not the global config).
   Or simpler: flip the global `config`, then re-save both profiles from
   the GUI so they embed the new value.
4. Apply Casa; verify with `hyprctl monitors` + `hyprctl configerrors`.
5. Re-save Loja too, so its embedded config block matches.
6. Commit; active_profile.json will have appeared in this package after
   the first profile apply — commit it as well.

With use-desc true every generated entry is desc:-prefixed: rules target
physical monitors, and the connector-name collision class (the G5 portrait
flashing onto the store LG through the shared HDMI-A-1 name) is structurally
impossible. A profile entry whose description is wrong is a silently inert
rule — that head falls back to defaults — which is why the true-up comes
before the flip.

## Workshop-session checklist

- `hyprctl monitors` for the 25UM58G; correct the desc in
  hypr/.config/hypr/monitors-locations.lua if the real serial differs from
  the 0x01010101 placeholder. Save a workshop profile while there.
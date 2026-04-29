# Quickshell Bar — Implementation Plan

## Concept and Inspiration

A floating "floating island" status bar for Hyprland, built with Quickshell (QML/QtQuick).
Replaces Waybar entirely. Visual language: dark navy background, purple (#b589d6) accent,
cyan (#03edf9) highlights, L-shaped HUD corner markers — cyberpunk/ghost-in-the-shell aesthetic.

**Reference style:** split into three pills (left / center / right) floating above the screen,
with blur behind via Hyprland layerrule. Popups appear below the right island. Toast
notifications appear top-right with a fade animation.

---

## Architecture

```
shell.qml  (ShellRoot, one Variants per component per screen)
├── Bar.qml               → PanelWindow, top edge, exclusive zone
│   ├── IslandLeft        → workspaces dots + active window title
│   ├── IslandCenter      → clock / date → opens CalendarPopup
│   └── IslandRight       → stats, BT, volume, media, notif, clip
├── CalendarPopup.qml     → top-right popup, month grid + holidays
├── NotifPopup.qml        → top-right popup, notification list
├── ClipPopup.qml         → top-right popup, clipboard history (cliphist)
├── MprisPopup.qml        → top-right popup, media prev/play/next
└── NotifToast.qml        → top-right toast, fade in/out on new notif

Support components (not in qmldir singletons):
  Island.qml, BarSep.qml, StatChip.qml, HudCorners.qml

Singletons (declared in qmldir):
  Colors, Geometry, SysStats, Battery, NetMonitor, Holidays,
  NotifService, ClipService, PopupState
```

### Key Quickshell API notes

- **PanelWindow**: use `implicitWidth`/`implicitHeight` (not `width`/`height` — deprecated 0.2.1).
  `exclusiveZone` must be a constant, not `height` self-reference.
- **PanelWindow opacity**: does NOT expose an `opacity` property. To animate fade, wrap content
  in an inner `Item` and animate that item's opacity. Use `visible: innerItem.opacity > 0` on
  the PanelWindow itself.
- **Process signals**: `onExited:` (not `onFinished:`). `onStarted:` fires when process starts and
  stdin pipe is ready — write stdin there, not immediately after setting `running = true`.
- **qmldir with Quickshell VFS**: when qmldir exists, synthesis is DISABLED. ALL types (singletons
  AND regular components) must be explicitly declared in qmldir or they won't be visible.
- **Quickshell.Bluetooth**: use `Bluetooth.defaultAdapter?.enabled` (null guard — no adapter → null).
- **Quickshell.Services.Mpris**: `Mpris.players` (ObjectModel), `.count`, `.values[i].isPlaying`,
  `.togglePlaying()`, `.next()`, `.previous()`, `.trackTitle`, `.trackArtist`, `.identity`.
- **Quickshell.Services.Notifications**: `NotificationServer` with `keepOnReload: true`,
  `onNotification(notif)` signal, `notif.tracked = true` to persist, `.trackedNotifications` (ObjectModel).
- **Hyprland layerrule** (0.46+ block syntax):
  ```
  layerrule { name = qs-blur; match:namespace = ^quickshell:; blur = true }
  ```

---

## Current Implementation Status

### Working (confirmed compiled)
| File | Status | Notes |
|---|---|---|
| `shell.qml` | ✅ | ShellRoot + Variants for all screens |
| `Bar.qml` | ✅ | PanelWindow top-anchored, exclusiveZone |
| `Island.qml` | ✅ | Frosted-glass pill base, glow ring |
| `HudCorners.qml` | ✅ | L-shaped cyan corner markers |
| `BarSep.qml` | ✅ | Thin vertical separator |
| `StatChip.qml` | ✅ | Icon + value inline chip |
| `IslandLeft.qml` | ✅ | Workspace dots (Hyprland), active title |
| `IslandCenter.qml` | ✅ | Clock HH:MM:SS + date, opens calendar |
| `IslandRight.qml` | ✅ | Stats/BT/volume/media/notif/clip |
| `Colors.qml` | ✅ | Color palette singleton |
| `Geometry.qml` | ✅ | Sizing constants singleton |
| `SysStats.qml` | ✅ | CPU/RAM/disk/GPU via /proc + nvidia-smi |
| `Battery.qml` | ✅ | BAT0 capacity + status polling |
| `NetMonitor.qml` | ✅ | /proc/net/dev, tx/rx kbps |
| `Holidays.qml` | ✅ | nager.at API + Mossoró municipal holidays |
| `NotifService.qml` | ✅ | NotificationServer + unreadCount signal |
| `ClipService.qml` | ✅ | cliphist list + decode via stdin/onStarted |
| `PopupState.qml` | ✅ | Active popup name + screen singleton |
| `CalendarPopup.qml` | ✅ | Month grid, holiday dots, legend |
| `NotifPopup.qml` | ✅ | Scrollable notif list, dismiss per-item + all |
| `ClipPopup.qml` | ✅ | Scrollable clip history, click to copy |
| `MprisPopup.qml` | ✅ | Track info + prev/play/next controls |

### Broken / Not yet verified
| File | Issue | Fix needed |
|---|---|---|
| `NotifToast.qml` | `opacity` property not on PanelWindow | Wrap content in inner Item, animate that |

---

## Bug Log

### Fixed this session
- `Bar.qml`: `height:` → `implicitHeight:` on PanelWindow (deprecated Quickshell 0.2.1)
- `ClipService`: `write()` after `running = true` is a race (stdin not open yet) — fixed with `onStarted`
- `IslandRight`: duplicate `ClipService.refresh()` removed; Bluetooth null guard added
- `qmldir`: all 13 regular components now explicitly declared (Quickshell VFS disables synthesis)
- `ClipService._copyProc`: needed valid `command` at init even if overridden at runtime

### Active bug
- **NotifToast.qml line 50**: `NumberAnimation on opacity { }` — PanelWindow has no `opacity`
  property. Fix: move opacity + animations + content into inner `Item id: toast`, change
  PanelWindow `visible: toast.opacity > 0`.

### Known limitations
- `SysStats` GPU: hardcoded to `nvidia-smi`. AMD/Intel GPUs show 0% (non-crashing).
- `Battery`: hardcoded path `BAT0`. Desktops with no battery will silently show 0%.
- `ClipService` copy: relies on `cliphist decode | wl-copy` via stdin — requires cliphist + wl-copy installed.
- `Holidays`: fetches from nager.at over the network — fails silently offline.
- `Mpris.players.values`: ObjectModel — if API changes, iterate with `for (let i=0; i<count; i++)` instead.

---

## Next Steps

### Immediate (required to boot)
1. **Fix NotifToast opacity** — wrap content in `Item { id: toast; opacity: 0 }`, animate that,
   set PanelWindow `visible: toast.opacity > 0`.

### Short-term (polish)
2. **Visual test** — confirm bar appears on all monitors, popups open/close, stats update.
3. **IslandRight layout** — review spacing with all widgets visible; `Layout.fillWidth: true` on
   the island means it grows to fill remaining space, which may look uneven.
4. **Volume scroll** — test `MouseArea.onWheel` works in Quickshell (may need `WheelHandler` instead).
5. **GPU widget** — hide GPU chip when `gpuPercent === 0` (no nvidia-smi) to avoid showing stale 0%.

### Medium-term (features)
6. **Brightness control** — add slider or click widget using `brightnessctl s X%`.
7. **Network interface selector** — NetMonitor currently sums all non-lo interfaces; show active one.
8. **Notification badge** — `unreadCount` badge on the bell could show a count number.
9. **Fish greeting** — Lain/GITS/Lovecraft ASCII art + rotating quotes in `config.fish`.

### Long-term / Nice-to-have
10. **SDDM theme** — pixie-sddm with `#b589d6` accent color.
11. **Obsidian theme** — cybr-obsidian adapted to purple palette.
12. **Stow deploy** — quickshell already added; verify `~/.config/quickshell` symlinks are live.

---

## Quickshell Reload

After any change:
```fish
pkill quickshell; quickshell &
# or use quickshell's built-in reload if running:
# quickshell msg reload
```

To test a single file in isolation:
```fish
quickshell -p /path/to/File.qml
```

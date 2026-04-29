# Quickshell Bar — Implementation Plan

## Concept and Inspiration

A floating "floating island" status bar for Hyprland, built with Quickshell (QML/QtQuick).
Replaces Waybar entirely. Visual language: dark navy background, purple (#b589d6) accent,
cyan (#03edf9) highlights, L-shaped HUD corner markers — cyberpunk/ghost-in-the-shell aesthetic.

**Reference style:** split into three pills (left / center / right) floating above the screen,
with blur behind via Hyprland layerrule. Popups appear below the right island. Toast
notifications appear top-right with a fade animation.

---

## Architecture (current)

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
```

---

## Quickshell API Reference (verified 0.2.1)

### PanelWindow
- Use `implicitWidth`/`implicitHeight` — `width`/`height` are deprecated.
- **No `opacity` property** — wrap content in inner `Item`, animate that item's opacity.
- **Screen assignment**: do NOT declare `required property var screen` in component files —
  this shadows PanelWindow's built-in `screen` and breaks per-monitor placement.
  Use `screen: modelData` from Variants; it sets PanelWindow.screen directly.
- `exclusiveZone` must use a constant value, not a self-referencing property.

### Process (Quickshell.Io)
- Signal: `onExited:` (not `onFinished:`).
- Signal: `onStarted:` — stdin pipe is ready here; write() in this handler, not after `running = true`.
- `stdinEnabled: true` required for stdin piping.
- All Process objects need a valid initial `command: [...]` even if overridden at runtime.

### Quickshell.Bluetooth
```
Bluetooth.defaultAdapter        → BluetoothAdapter (can be null)
Bluetooth.defaultAdapter.enabled → bool (r/w)
Bluetooth.defaultAdapter.scanning → bool (read-only)
Bluetooth.defaultAdapter.devices  → ObjectModel<BluetoothDevice>
Bluetooth.defaultAdapter.startDiscovery()
Bluetooth.defaultAdapter.stopDiscovery()

BluetoothDevice:
  .name       → string
  .address    → string (MAC)
  .connected  → bool (r/w — setting it calls connect()/disconnect())
  .paired     → bool
  .bonded     → bool
  .trusted    → bool (r/w)
  .battery    → int (percent, when batteryAvailable)
  .batteryAvailable → bool
  .icon       → string (freedesktop icon name)
  .state      → enum (connecting, connected, disconnecting, disconnected)
  .connect()  / .disconnect() / .pair() / .forget()
```

### Quickshell.Services.Pipewire
```
import Quickshell.Services.Pipewire

Pipewire.nodes                      → ObjectModel<PwNode> (all nodes)
Pipewire.defaultAudioSink           → PwNode (current default output, read-only)
Pipewire.preferredDefaultAudioSink  → PwNode (r/w — set to switch default)
Pipewire.defaultAudioSource         → PwNode (mic)
Pipewire.preferredDefaultAudioSource → PwNode (r/w)

PwNode:
  .name        → string (internal)
  .description → string (human-readable, e.g. "Built-in Audio Analog Stereo")
  .isSink      → bool
  .isStream    → bool  
  .audio       → PwNodeAudio (null if not audio node)
  .ready       → bool

PwNodeAudio:
  .volume   → real  (0.0–1.0, average across channels, r/w)
  .muted    → bool  (r/w)
  .channels → list<PwAudioChannel>
```

### Quickshell.Services.Mpris
```
Mpris.players  → ObjectModel<MprisPlayer>
MprisPlayer: .trackTitle, .trackArtist, .identity, .isPlaying,
             .togglePlaying(), .next(), .previous()
```

### Network (no native module)
Use `nmcli` via Process:
```
# Active connection info
nmcli -t -f NAME,TYPE,DEVICE,SIGNAL con show --active

# WiFi signal for specific device
nmcli -t -f SIGNAL,SSID dev wifi list ifname wlan0 --rescan no

# IP address
nmcli -t -f IP4.ADDRESS dev show <device>
```

### Docker (no native module)
Use Process:
```
docker ps --format "{{.Names}}\t{{.Status}}\t{{.Image}}\t{{.ID}}"
```

---

## Hover Popup Architecture

Hover-triggered popups (Bluetooth connected-devices, Network detail) need a different
trigger than click popups. Strategy: extend `PopupState` with a `hover` layer.

```qml
// PopupState.qml additions:
property string hoverActive: ""
property var hoverScreen: null

function showHover(name, scrn) { hoverActive = name; hoverScreen = scrn }
function clearHover(name) { if (hoverActive === name) { hoverActive = ""; hoverScreen = null } }
```

Popup visibility for hover-capable popups:
```qml
visible: (PopupState.active === "bluetooth" && PopupState.screen === screen)
      || (PopupState.hoverActive === "bluetooth" && PopupState.hoverScreen === screen)
```

Hover trigger in IslandRight uses `HoverHandler` + `Timer` (500ms delay) to avoid
flicker when moving mouse across the bar.

---

## Planned Features (priority order)

### 1. Stat chip icons + tooltips  ← quick win
**Problem:** CPU icon `""` and RAM icon `""` may not render in all Nerd Font versions.
**Fix:** Switch to verified icons, add tooltip support to `StatChip.qml`.

New icons:
| Widget | Icon | Codepoint | Tooltip content |
|--------|------|-----------|-----------------|
| CPU | `󰻠` | U+F3EE0 | `CPU: X%` |
| RAM | `󰍛` | U+F034B | `RAM: X% used` |
| Disk | `󰋊` | U+F02CA | `Disk /: X%` |
| GPU | `󰢮` | U+F08AE | `GPU: X% · VRAM: Y/Z GB` (hidden if no nvidia-smi) |
| Network | `󰀸`/`󰈀` | wifi/eth | tx/rx shown inline |
| Bluetooth | `󰂯`/`󰂲` | U+F00CF/D0 | `Bluetooth: On · N connected` |
| Volume | `󰕾`/`󰖀`/`󰕿`/`󰝟` | existing | `Volume: X% · click=mute · scroll=±5%` |
| Battery | dynamic | existing | `Battery: X% · Charging/Discharging` |
| Docker | `󰡨` | U+F0868 | `Docker: N running` |
| Media | `󰝚` | existing | `<track> — <artist>` |
| Notif | `󱅫`/`󰂚` | existing | `N unread notifications` |
| Clip | `󰅎` | existing | `Clipboard history` |

**Implementation:** Add `property string tooltip: ""` to `StatChip.qml`, use
`HoverHandler + ToolTip` (QtQuick.Controls attached props).

---

### 2. Bluetooth popup (hover + click)  ← new component
**New files:** `BluetoothPopup.qml`
**Modified:** `IslandRight.qml`, `Bar.qml`, `PopupState.qml`, `qmldir`

Behavior:
- **Hover (500ms delay):** opens `BluetoothPopup` showing connected devices + battery
- **Click:** opens `BluetoothPopup` AND triggers `Bluetooth.defaultAdapter.startDiscovery()`
- **Popup auto-closes** when mouse leaves both the BT icon and the popup (500ms grace)

`BluetoothPopup.qml` sections:
1. Header row: "󰂯 Bluetooth" + on/off toggle
2. "Connected" section: lists `Bluetooth.defaultAdapter.devices` filtered by `.connected`
   - Per device: icon, name, battery% (if available), disconnect button
3. "Available" section (only shown after scan): lists all devices not connected
   - Per device: name, paired badge, connect button
4. Scan status: spinner while `Bluetooth.defaultAdapter.scanning`, "Scan" button otherwise

Data access (no service singleton needed — Bluetooth module is reactive):
```qml
// Connected devices
Repeater {
    model: Bluetooth.defaultAdapter?.devices
    delegate: ... // filter by modelData.connected
}
```

---

### 3. Audio device popup  ← new component + service
**New files:** `AudioService.qml` (singleton), `AudioPopup.qml`
**Modified:** `IslandRight.qml`, `Bar.qml`, `qmldir`

`AudioService.qml`:
```qml
pragma Singleton
import Quickshell.Services.Pipewire

QtObject {
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property string sinkName: sink?.description ?? "No output"

    // All sinks (filter Pipewire.nodes by isSink + audio !== null)
    readonly property var sinks: {
        const result = []
        if (!Pipewire.nodes) return result
        for (let i = 0; i < Pipewire.nodes.count; i++) {
            const n = Pipewire.nodes.values[i]
            if (n.isSink && n.audio) result.push(n)
        }
        return result
    }

    function setVolume(v) { if (sink?.audio) sink.audio.volume = v }
    function toggleMute() { if (sink?.audio) sink.audio.muted = !sink.audio.muted }
    function setDefaultSink(node) { Pipewire.preferredDefaultAudioSink = node }
}
```

Bar display: `<icon> <short device name> <volume%>`
- Truncate device name to ~12 chars
- Click opens `AudioPopup`
- Scroll adjusts volume via PipeWire (replace wpctl approach)
- Click on icon = mute toggle

`AudioPopup.qml` sections:
1. Header: "󰕾 Audio Output"
2. Volume slider (or click +/- buttons)
3. Sink list: Repeater over `AudioService.sinks`
   - Highlight current default
   - Click to set as default

---

### 4. Network module  ← new service + popup
**New files:** `NetworkService.qml` (singleton), `NetworkPopup.qml`
**Modified:** `IslandRight.qml`, `Bar.qml`, `qmldir`

`NetworkService.qml` — polls `nmcli` every 10s:
```
Fields: connectionName, connectionType (wifi/ethernet/vpn), device, signal (0-100)
        ipAddress, txKbps (from NetMonitor), rxKbps (from NetMonitor)
```

Bar display: `<type-icon> <connection-name-truncated>` + signal bars (WiFi only)
- Type icons: `󰀸` (WiFi), `󰈀` (Ethernet), `󰒄` (VPN), `󰲛` (disconnected)
- Signal bars rendered as colored chars or a small icon

**Hover popup (NetworkPopup.qml):**
- Shown on 400ms hover, hidden 600ms after mouse leaves
- Sections: Connection name, type, device name, IP, signal strength graph, tx/rx speeds
- Uses `PopupState.hoverActive / hoverScreen`

---

### 5. Docker module  ← new service + popup
**New files:** `DockerService.qml` (singleton), `DockerPopup.qml`
**Modified:** `IslandRight.qml`, `Bar.qml`, `qmldir`

`DockerService.qml`:
- Polls `docker ps --format "{{.Names}}\t{{.Status}}\t{{.Image}}"` every 15s
- Also watches for changes (could run `docker events --filter type=container` via persistent proc)
- Properties: `containers: []`, `running: int` (count), `available: bool` (docker daemon reachable)

Bar display: `󰡨 N` (docker icon + running count), hidden if docker not available
Click opens `DockerPopup`.

`DockerPopup.qml`:
- Header: "󰡨 Docker · N running"
- Repeater over containers: name, image (truncated), status, uptime
- Color-code by status (running=green, paused=yellow, exited=dim)
- No stop/start controls (view-only, consistent with bar philosophy)

---

## File Inventory After All Features

### New files to create
| File | Type | Purpose |
|------|------|---------|
| `AudioService.qml` | singleton | PipeWire default sink + sink list |
| `AudioPopup.qml` | component | Audio output device chooser |
| `BluetoothPopup.qml` | component | BT connected devices + scan |
| `NetworkService.qml` | singleton | nmcli active connection info |
| `NetworkPopup.qml` | component | Detailed network hover popup |
| `DockerService.qml` | singleton | docker ps container list |
| `DockerPopup.qml` | component | Running containers view |

### Files to modify
| File | Changes |
|------|---------|
| `PopupState.qml` | Add `hoverActive`, `hoverScreen`, `showHover()`, `clearHover()` |
| `StatChip.qml` | Add `tooltip` property + HoverHandler + ToolTip attached props |
| `IslandRight.qml` | Replace volume with AudioService, replace NetMonitor column with NetworkService widget, add BT hover, add Docker chip |
| `Bar.qml` | Wire up `onBtClicked`, `onAudioClicked`, `onNetHovered`/`onNetUnhovered`, `onDockerClicked` |
| `qmldir` | Declare all 7 new files |
| `plan.md` | Keep updated |

---

## Implementation Order

1. `StatChip.qml` — tooltip + icon fix (no new dependencies)
2. `PopupState.qml` — add hover layer (needed by BT + Network)
3. `AudioService.qml` + `AudioPopup.qml` — PipeWire sink switching
4. `BluetoothPopup.qml` — BT connected/scan (uses Bluetooth module directly)
5. `NetworkService.qml` + `NetworkPopup.qml` — nmcli-based network info
6. `DockerService.qml` + `DockerPopup.qml` — docker ps polling
7. `IslandRight.qml` + `Bar.qml` — wire everything together
8. `qmldir` — declare all new types

---

## Bug Log

### Fixed
- `Bar.qml`: `height:` → `implicitHeight:` on PanelWindow (deprecated 0.2.1)
- `ClipService`: stdin race → fixed with `onStarted`
- `IslandRight`: duplicate `ClipService.refresh()` removed; Bluetooth null guard
- `qmldir`: all regular components must be explicitly declared (VFS disables synthesis)
- `SysStats`/`NetMonitor`/`ClipService`: `parent` not defined in SplitParser function bodies → use Process `id`
- `NotifToast`: PanelWindow has no `opacity` → animate inner Item
- **All PanelWindow files**: `required property var screen` shadows PanelWindow.screen → removed

### Known limitations
- `SysStats` GPU: `nvidia-smi` only. AMD/Intel → 0% (graceful).
- `Battery`: hardcoded `BAT0`. Desktops → 0% silently.
- `Holidays`: fetches nager.at over network, fails silently offline.

---

## Quickshell Reload

```fish
qs-reload          # alias: pkill -x dunst; pkill quickshell; quickshell &
quickshell msg reload   # in-place reload without restarting (faster)
```

Test a single file in isolation:
```fish
quickshell -p /path/to/File.qml
```

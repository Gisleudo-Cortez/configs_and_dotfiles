pragma Singleton
import QtQuick
import Quickshell.Io

// USB device monitor — full bus enumeration via sysfs + storage via lsblk.
// Polls every 5s. Immediate refresh after mount/unmount actions.
// Bar chip: device count with USB icon. Popup: full device list with
// type, speed, power, VID:PID, and mount/unmount for storage.
QtObject {
    id: root

    // ── Public properties (consumed by widget + popup) ──────────────
    property int deviceCount: 0          // non-hub, non-controller USB devices
    property var devices: []             // [{sysfsName, manufacturer, product, vid, pid, speed, power, type, isStorage, blockDev, size, label, mountpoint, used, total, pct, mounted}]
    property string tooltipText: ""
    readonly property bool hasDevices: deviceCount > 0
    property int storageCount: 0
    property int mountedCount: 0

    // ── Internal ────────────────────────────────────────────────────

    readonly property var _proc: Process {
        id: usbProc
        running: false
        property var _devBuf: []
        property var _stgBuf: []
        // Single bash script: enumerate sysfs devices, then lsblk storage.
        // DEV|name|manuf|prod|vid|pid|speed|power|dtype
        // STG|blkname|usbparent|size|label|mount|type|used|total|pct
        command: ["bash", "-c", `
# ── USB devices from sysfs ──────────────────────────────────────────
for dev in /sys/bus/usb/devices/*/; do
  name=$(basename "$dev")
  [[ "$name" == *:* ]] && continue
  vid=$(cat "$dev/idVendor" 2>/dev/null) || continue
  cls=$(cat "$dev/bDeviceClass" 2>/dev/null)
  [[ "$cls" == "09" || "$cls" == "11" ]] && continue
  prod=$(cat "$dev/product" 2>/dev/null || echo "")
  manuf=$(cat "$dev/manufacturer" 2>/dev/null || echo "")
  pid=$(cat "$dev/idProduct" 2>/dev/null || echo "????")
  speed=$(cat "$dev/speed" 2>/dev/null || echo "0")
  power=$(cat "$dev/bMaxPower" 2>/dev/null || echo "0mA")
  # Type from device class or first interface class
  dtype="other"
  if [[ "$cls" == "08" ]]; then
    dtype="storage"
  elif [[ "$cls" == "e0" ]]; then
    dtype="wireless"
  elif [[ "$cls" == "00" || -z "$cls" ]]; then
    ifacedir=$(ls -d "$dev"*/ 2>/dev/null | head -1)
    if [[ -n "$ifacedir" ]]; then
      ifcls=$(cat "$ifacedir/bInterfaceClass" 2>/dev/null || echo "")
      case "$ifcls" in
        01) dtype="audio";;
        02) dtype="network";;
        03) dtype="input";;
        06) dtype="image";;
        07) dtype="printer";;
        08) dtype="storage";;
        0e) dtype="video";;
        e0) dtype="wireless";;
      esac
    fi
  else
    case "$cls" in
      02) dtype="network";;
      06) dtype="image";;
      07) dtype="printer";;
      03) dtype="input";;
      01) dtype="audio";;
    esac
  fi
  echo "DEV|$name|$manuf|$prod|$vid|$pid|$speed|$power|$dtype"
done

# ── USB storage from lsblk ──────────────────────────────────────────
while IFS= read -r line; do
  [[ "$line" != *'TRAN="usb"'* ]] && continue
  [[ "$line" =~ NAME="([^"]*)" ]] && name="\${BASH_REMATCH[1]}"
  [[ "$line" =~ SIZE="([^"]*)" ]] && size="\${BASH_REMATCH[1]}"
  [[ "$line" =~ LABEL="([^"]*)" ]] && label="\${BASH_REMATCH[1]}"
  [[ "$line" =~ MOUNTPOINT="([^"]*)" ]] && mount="\${BASH_REMATCH[1]}"
  [[ "$line" =~ TYPE="([^"]*)" ]] && type="\${BASH_REMATCH[1]}"
  # Find USB parent by walking sysfs tree
  usbparent=""
  if [ -d "/sys/block/$name" ]; then
    usbparent=$(basename "$(readlink -f "/sys/block/$name/device/../.." 2>/dev/null)" 2>/dev/null)
  fi
  # Disk usage if mounted
  used=""; total=""; pct=""
  if [ -n "$mount" ]; then
    dfsys=$(df -h --output=used,size,pcent "$mount" 2>/dev/null | tail -1)
    read -r used total pct _ <<< "$dfsys"
  fi
  echo "STG|$name|$usbparent|$size|$label|$mount|$type|$used|$total|$pct"
done < <(lsblk -P -o NAME,SIZE,LABEL,MOUNTPOINT,TYPE,TRAN 2>/dev/null)
        `]

        stdout: SplitParser {
            onRead: function(line) {
                line = line.trim()
                if (line.startsWith("DEV|"))
                    usbProc._devBuf.push(line)
                else if (line.startsWith("STG|"))
                    usbProc._stgBuf.push(line)
            }
        }

        onExited: {
            // ── Parse DEV lines ──────────────────────────────────────
            var devList = []
            for (var i = 0; i < usbProc._devBuf.length; i++) {
                var parts = usbProc._devBuf[i].split("|")
                // DEV|name|manuf|prod|vid|pid|speed|power|dtype
                if (parts.length < 9) continue
                devList.push({
                    sysfsName:    parts[1],
                    manufacturer: parts[2] || "Unknown",
                    product:      parts[3] || "Unknown",
                    vid:          parts[4],
                    pid:          parts[5],
                    speed:        parts[6],
                    power:        parts[7],
                    type:         parts[8],
                    isStorage:    false,
                    blockDev:     "",
                    size:         "",
                    label:        "",
                    mountpoint:   "",
                    used:         "",
                    total:        "",
                    pct:          "",
                    mounted:      false
                })
            }

            // ── Parse STG lines and merge into devices ───────────────
            var stgCount = 0
            var mntCount = 0
            for (var s = 0; s < usbProc._stgBuf.length; s++) {
                var sp = usbProc._stgBuf[s].split("|")
                // STG|blkname|usbparent|size|label|mount|type|used|total|pct
                if (sp.length < 10) continue
                var blkName  = sp[1]
                var usbPar   = sp[2]
                var blkSize  = sp[3]
                var blkLabel = sp[4]
                var blkMount = sp[5]
                var blkType  = sp[6]
                var blkUsed  = sp[7]
                var blkTotal = sp[8]
                var blkPct   = sp[9]
                var isMounted = blkMount !== ""
                if (isMounted) mntCount++
                stgCount++

                // Match to device by USB parent sysfs name
                for (var d = 0; d < devList.length; d++) {
                    var dev = devList[d]
                    if (dev.sysfsName === usbPar) {
                        if (blkType === "part") {
                            // Partition — takes priority over disk
                            dev.isStorage  = true
                            dev.blockDev   = blkName
                            dev.size       = blkSize
                            dev.label      = blkLabel
                            dev.mountpoint = blkMount
                            dev.used       = blkUsed
                            dev.total      = blkTotal
                            dev.pct        = blkPct
                            dev.mounted    = isMounted
                        } else if (!dev.isStorage) {
                            // Disk with no partition yet seen
                            dev.isStorage  = true
                            dev.blockDev   = blkName
                            dev.size       = blkSize
                            dev.label      = blkLabel
                            dev.mountpoint = blkMount
                            dev.mounted    = isMounted
                        }
                        break
                    }
                }
            }

            // ── Sort: storage first, then by type, then by name ──────
            devList.sort(function(a, b) {
                if (a.isStorage && !b.isStorage) return -1
                if (!a.isStorage && b.isStorage) return 1
                if (a.type < b.type) return -1
                if (a.type > b.type) return 1
                return (a.product || "").localeCompare(b.product || "")
            })

            root.devices      = devList
            root.deviceCount  = devList.length
            root.storageCount = stgCount
            root.mountedCount = mntCount

            // ── Tooltip ──────────────────────────────────────────────
            if (devList.length === 0) {
                root.tooltipText = "No USB devices"
            } else {
                var lines = []
                for (var t = 0; t < Math.min(devList.length, 6); t++) {
                    var dd = devList[t]
                    var lbl = dd.product || dd.manufacturer || "Unknown"
                    if (dd.isStorage && dd.mounted) {
                        lbl += " -> " + dd.mountpoint
                        if (dd.pct) lbl += " (" + dd.pct + ")"
                    }
                    lines.push(lbl)
                }
                if (devList.length > 6)
                    lines.push("+" + (devList.length - 6) + " more")
                root.tooltipText = "USB . " + devList.length + " devices: " + lines.join(" . ")
            }

            // Reset buffers
            usbProc._devBuf = []
            usbProc._stgBuf = []
        }
    }

    // ── Action process for mount/unmount ────────────────────────────
    readonly property var _actionProc: Process {
        id: actionProc
        running: false
        command: ["echo", "noop"]
        onExited: function() {
            root.refresh()
        }
    }

    // Immediate re-poll after state change
    function refresh() {
        usbProc._devBuf = []
        usbProc._stgBuf = []
        usbProc.running = true
    }

    function mountDevice(blockDev) {
        actionProc.command = ["udisksctl", "mount", "-b", "/dev/" + blockDev]
        actionProc.running = true
    }

    function unmountDevice(blockDev) {
        actionProc.command = ["udisksctl", "unmount", "-b", "/dev/" + blockDev]
        actionProc.running = true
    }

    // ── Poll timer ──────────────────────────────────────────────────
    readonly property var _ticker: Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { usbProc.running = true }
    }
}
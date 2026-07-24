pragma Singleton
import QtQuick
import Quickshell.Io

// USB device monitor — full bus enumeration via sysfs + storage via lsblk.
// Polls every 5s. Immediate refresh after mount/unmount actions.
// Exposes two filtered arrays: storageDevices (USB block devices with
// mount/unmount support) and otherDevices (everything else on the bus).
QtObject {
    id: root

    // ── Storage-specific properties ─────────────────────────────────
    property var storageDevices: []      // [{sysfsName, manufacturer, product, vid, pid, speed, power, type, isStorage, blockDev, size, label, mountpoint, used, total, pct, mounted}]
    property int storageDeviceCount: 0
    property int mountedCount: 0
    property string storageTooltipText: ""
    readonly property bool hasStorage: storageDeviceCount > 0

    // ── Other (non-storage) device properties ───────────────────────
    property var otherDevices: []
    property int otherDeviceCount: 0
    property string otherTooltipText: ""
    readonly property bool hasOtherDevices: otherDeviceCount > 0

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
# Partitions don't carry TRAN="usb" (only parent disks do), so we also
# include partitions and check their parent disk's TRAN via PKNAME.
while IFS= read -r line; do
  is_usb=false
  if echo "$line" | grep -q 'TRAN="usb"'; then
    is_usb=true
  elif echo "$line" | grep -q 'TYPE="part"'; then
    pk=$(echo "$line" | grep -oP 'PKNAME="\K[^"]*')
    if [ -n "$pk" ] && lsblk -ln -o TRAN "/dev/$pk" 2>/dev/null | grep -q "usb"; then
      is_usb=true
    fi
  fi
  [ "$is_usb" = false ] && continue
  name=$(echo "$line" | grep -oP 'NAME="\K[^"]*' | head -1)
  size=$(echo "$line" | grep -oP 'SIZE="\K[^"]*' | head -1)
  label=$(echo "$line" | grep -oP 'LABEL="\K[^"]*' | head -1)
  mount=$(echo "$line" | grep -oP 'MOUNTPOINT="\K[^"]*' | head -1)
  type=$(echo "$line" | grep -oP 'TYPE="\K[^"]*' | head -1)
  # Find USB parent by walking sysfs tree (4 levels up from block device)
  # /sys/block/sdX/device -> ../../../N:M:O:P (SCSI)
  # walk: device/.. = host, /../.. = interface (N-M:1.0), /../../.. = USB device (N-M)
  # For partitions (sdXN), use the parent disk (sdX) instead.
  usbparent=""
  blkbase="$name"
  # Strip partition suffix: sdc1 -> sdc, mmcblk0p1 -> mmcblk0
  blkbase=$(echo "$name" | sed 's/[0-9]*$//; s/p$//')
  if [ -d "/sys/block/$blkbase" ]; then
    usbparent=$(basename "$(readlink -f "/sys/block/$blkbase/device/../../../.." 2>/dev/null)" 2>/dev/null)
  fi
  # Disk usage if mounted
  used=""; total=""; pct=""
  if [ -n "$mount" ]; then
    dfsys=$(df -h --output=used,size,pcent "$mount" 2>/dev/null | tail -1)
    read -r used total pct _ <<< "$dfsys"
  fi
  echo "STG|$name|$usbparent|$size|$label|$mount|$type|$used|$total|$pct"
done < <(lsblk -P -o NAME,SIZE,LABEL,MOUNTPOINT,TYPE,TRAN,PKNAME 2>/dev/null)
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

            // ── Split into storage + other arrays ────────────────────
            var stgList = []
            var othList = []
            for (var j = 0; j < devList.length; j++) {
                if (devList[j].isStorage)
                    stgList.push(devList[j])
                else
                    othList.push(devList[j])
            }

            // ── Sort storage: mounted first, then by label/name ──────
            stgList.sort(function(a, b) {
                if (a.mounted && !b.mounted) return -1
                if (!a.mounted && b.mounted) return 1
                var an = (a.label || a.product || "")
                var bn = (b.label || b.product || "")
                return an.localeCompare(bn)
            })

            // ── Sort other: by type, then by name ────────────────────
            othList.sort(function(a, b) {
                if (a.type < b.type) return -1
                if (a.type > b.type) return 1
                return (a.product || "").localeCompare(b.product || "")
            })

            root.storageDevices    = stgList
            root.storageDeviceCount = stgList.length
            root.mountedCount      = mntCount
            root.otherDevices      = othList
            root.otherDeviceCount  = othList.length

            // ── Storage tooltip ──────────────────────────────────────
            if (stgList.length === 0) {
                root.storageTooltipText = "No USB storage"
            } else {
                var slines = []
                for (var st = 0; st < Math.min(stgList.length, 6); st++) {
                    var sd = stgList[st]
                    var slabel = sd.label || sd.product || "Unknown"
                    if (sd.mounted) {
                        slabel += " -> " + sd.mountpoint
                        if (sd.pct) slabel += " (" + sd.pct + ")"
                    } else {
                        slabel += " . unmounted"
                    }
                    slines.push(slabel)
                }
                if (stgList.length > 6)
                    slines.push("+" + (stgList.length - 6) + " more")
                root.storageTooltipText = "USB Storage . " + stgList.length + " devices: " + slines.join(" . ")
            }

            // ── Other devices tooltip ────────────────────────────────
            if (othList.length === 0) {
                root.otherTooltipText = "No USB devices"
            } else {
                var olines = []
                for (var ot = 0; ot < Math.min(othList.length, 6); ot++) {
                    var od = othList[ot]
                    olines.push(od.product || od.manufacturer || "Unknown")
                }
                if (othList.length > 6)
                    olines.push("+" + (othList.length - 6) + " more")
                root.otherTooltipText = "USB . " + othList.length + " devices: " + olines.join(" . ")
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
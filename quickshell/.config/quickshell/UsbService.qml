pragma Singleton
import QtQuick
import Quickshell.Io

// USB device monitor — full bus enumeration via sysfs + storage via lsblk.
// Polls every 5s. Immediate refresh after mount/unmount actions.
// Exposes two filtered arrays: storageDevices and otherDevices.
//
// Data pipeline (all in one bash script):
//   DEV|name|manuf|prod|vid|pid|speed|power|dtype
//   STG|blkname|usbparent|size|label|model|mount|type|used|total|pct
//
// Label priority: filesystem LABEL (partition) > MODEL (disk) > product (sysfs)
QtObject {
    id: root

    property var storageDevices: []
    property int storageDeviceCount: 0
    property int mountedCount: 0
    property string storageTooltipText: ""
    readonly property bool hasStorage: storageDeviceCount > 0

    property var otherDevices: []
    property int otherDeviceCount: 0
    property string otherTooltipText: ""
    readonly property bool hasOtherDevices: otherDeviceCount > 0

    readonly property var _proc: Process {
        id: usbProc
        running: false
        property var _devBuf: []
        property var _stgBuf: []

        // The bash script avoids ${...} syntax (QML template interpolation)
        // and uses $var and $(...) which are safe in QML backtick templates.
        command: ["bash", "-c", `
# Phase 1: USB devices from sysfs
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
  dtype="other"
  if [[ "$cls" == "08" ]]; then dtype="storage"
  elif [[ "$cls" == "e0" ]]; then dtype="wireless"
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

# Phase 2: USB storage from lsblk
# Use a simple approach: lsblk -ln for USB disks, then for each disk
# get partitions. Output one STG line per disk and per partition.
# Avoid grep -oP and BASH_REMATCH which break in QML templates.

# Get USB disk names
usb_disks=$(lsblk -ln -o NAME,TRAN 2>/dev/null | awk '$2=="usb"{print $1}')

for disk in $usb_disks; do
  # Get disk info (lsblk needs /dev/ prefix with -ln)
  d_size=$(lsblk -ln -o SIZE "/dev/$disk" 2>/dev/null | head -1)
  d_model=$(lsblk -ln -o MODEL "/dev/$disk" 2>/dev/null | head -1)
  # Find USB parent via sysfs (4 levels up)
  d_parent=""
  if [ -d "/sys/block/$disk" ]; then
    d_parent=$(basename "$(readlink -f "/sys/block/$disk/device/../../../.." 2>/dev/null)" 2>/dev/null)
  fi
  # Emit disk-level STG (no label, no mount — those come from partitions)
  echo "STG|$disk|$d_parent|$d_size||$d_model||disk|||"

  # Get partitions of this disk
  parts=$(lsblk -ln -o NAME,TYPE "/dev/$disk" 2>/dev/null | awk '$2=="part"{print $1}')
  for part in $parts; do
    p_size=$(lsblk -ln -o SIZE "/dev/$part" 2>/dev/null | head -1)
    p_label=$(lsblk -ln -o LABEL "/dev/$part" 2>/dev/null | head -1)
    p_mount=$(lsblk -ln -o MOUNTPOINT "/dev/$part" 2>/dev/null | head -1)
    # Disk usage if mounted
    p_used=""; p_total=""; p_pct=""
    if [ -n "$p_mount" ]; then
      dfsys=$(df -h --output=used,size,pcent "$p_mount" 2>/dev/null | tail -1)
      read -r p_used p_total p_pct _ <<< "$dfsys"
    fi
    echo "STG|$part|$d_parent|$p_size|$p_label|$d_model|$p_mount|part|$p_used|$p_total|$p_pct"
  done
done
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
            var devList = []
            for (var i = 0; i < usbProc._devBuf.length; i++) {
                var parts = usbProc._devBuf[i].split("|")
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
                    model:        "",
                    mountpoint:   "",
                    used:         "",
                    total:        "",
                    pct:          "",
                    mounted:      false
                })
            }

            var mntCount = 0
            for (var s = 0; s < usbProc._stgBuf.length; s++) {
                var sp = usbProc._stgBuf[s].split("|")
                if (sp.length < 11) continue
                var blkName  = sp[1]
                var usbPar   = sp[2]
                var blkSize  = sp[3]
                var blkLabel = sp[4]
                var blkModel = sp[5]
                var blkMount = sp[6]
                var blkType  = sp[7]
                var blkUsed  = sp[8]
                var blkTotal = sp[9]
                var blkPct   = sp[10]
                var isMounted = blkMount !== ""

                if (!usbPar) continue

                for (var d = 0; d < devList.length; d++) {
                    var dev = devList[d]
                    if (dev.sysfsName !== usbPar) continue

                    if (blkType === "part") {
                        dev.isStorage  = true
                        dev.blockDev   = blkName
                        dev.size       = blkSize
                        dev.label      = blkLabel
                        dev.model      = blkModel || dev.model || ""
                        dev.mountpoint = blkMount
                        dev.used       = blkUsed
                        dev.total      = blkTotal
                        dev.pct        = blkPct
                        dev.mounted    = isMounted
                    } else if (!dev.isStorage) {
                        dev.isStorage  = true
                        dev.blockDev   = blkName
                        dev.size       = blkSize
                        dev.label      = blkLabel
                        dev.model      = blkModel
                        dev.mountpoint = blkMount
                        dev.mounted    = isMounted
                    }
                    break
                }
            }

            var stgList = []
            var othList = []
            for (var j = 0; j < devList.length; j++) {
                if (devList[j].isStorage)
                    stgList.push(devList[j])
                else
                    othList.push(devList[j])
            }

            mntCount = 0
            for (var m = 0; m < stgList.length; m++) {
                if (stgList[m].mounted) mntCount++
            }

            stgList.sort(function(a, b) {
                if (a.mounted && !b.mounted) return -1
                if (!a.mounted && b.mounted) return 1
                var an = (a.label || a.model || a.product || "")
                var bn = (b.label || b.model || b.product || "")
                return an.localeCompare(bn)
            })

            othList.sort(function(a, b) {
                if (a.type < b.type) return -1
                if (a.type > b.type) return 1
                return (a.product || "").localeCompare(b.product || "")
            })

            root.storageDevices     = stgList
            root.storageDeviceCount = stgList.length
            root.mountedCount       = mntCount
            root.otherDevices       = othList
            root.otherDeviceCount   = othList.length

            if (stgList.length === 0) {
                root.storageTooltipText = "No USB storage"
            } else {
                var slines = []
                for (var st = 0; st < Math.min(stgList.length, 6); st++) {
                    var sd = stgList[st]
                    var slabel = sd.label || sd.model || sd.product || "Unknown"
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

            usbProc._devBuf = []
            usbProc._stgBuf = []
        }
    }

    readonly property var _actionProc: Process {
        id: actionProc
        running: false
        command: ["echo", "noop"]
        onExited: function() { root.refresh() }
    }

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

    readonly property var _ticker: Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { usbProc.running = true }
    }
}
pragma Singleton
import QtQuick
import Quickshell.Io

// USB storage device status (udiskie + lsblk).
// Polls lsblk for usb/loop devices with mountpoints.
// Bar chip: count of mounted devices. Tooltip: label + mount + size.
QtObject {
    id: root

    property int    activeCount: 0
    property string tooltipText: ""
    property var    devices: []   // [{label, mount, size}]
    readonly property bool available: activeCount > 0

    readonly property var _proc: Process {
        id: usbProc
        command: [
            "sh", "-c",
            `lsblk -ln -o TRAN,NAME,LABEL,SIZE,MOUNTPOINT,TYPE 2>/dev/null |
             awk '$1=="usb" || $1=="loop" {print}'`
        ]
        running: false
        property var _buf: []

        stdout: SplitParser {
            onRead: function(line) {
                var parts = line.trim().split(/\s+/)
                if (parts.length < 4) return
                var name      = parts[1]
                var label     = parts[2] === "" ? name : parts[2]
                var size      = parts[3]
                var mount     = parts.length > 4 ? parts[4] : ""
                var typeIdx   = mount === "" ? 4 : 5
                var type      = parts.length > typeIdx ? parts[typeIdx] : ""
                // only partitions/loop with real mountpoints
                if (type !== "part" && type !== "loop") return
                if (mount === "" || mount === "/boot" ||
                    mount === "/var/log" || mount === "/" ||
                    mount === "[SWAP]") return

                usbProc._buf.push({ label: label, mount: mount, size: size })
            }
        }

        onExited: {
            root.devices = usbProc._buf.slice()
            usbProc._buf = []
            var n  = root.devices.length
            root.activeCount = n
            var parts = []
            for (var i = 0; i < n; i++) {
                var d = root.devices[i]
                parts.push(d.label + " → " + d.mount + " (" + d.size + ")")
            }
            root.tooltipText = n > 0
                ? "USB: " + parts.join("  ·  ")
                : "No USB storage"
        }
    }

    readonly property var _ticker: Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { usbProc.running = true }
    }
}

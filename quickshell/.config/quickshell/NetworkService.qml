pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property string connectionName: ""
    property string connectionType: "none"  // "wifi" | "ethernet" | "vpn" | "none"
    property string device: ""
    property int    signal: 0       // 0-100 (WiFi only)
    property string ipAddress: ""
    property bool   connected: false

    readonly property string typeIcon: {
        switch (connectionType) {
            case "wifi":     return _wifiIcon(signal)
            case "ethernet": return "󰈀"
            case "vpn":      return "󰒄"
            default:         return "󰲛"
        }
    }

    function _wifiIcon(s) {
        if (s >= 80) return "󰤨"
        if (s >= 60) return "󰤥"
        if (s >= 40) return "󰤢"
        if (s >= 20) return "󰤟"
        return "󰤯"
    }

    readonly property string shortName: {
        if (!connected) return "offline"
        if (connectionName.length > 14) return connectionName.substring(0, 12) + "…"
        return connectionName
    }

    // ── Process 1: active device/connection (one line per network device) ─
    // Format: DEVICE:TYPE:STATE:CONNECTION (connection name last so colons in
    // name are safe — we split only the first 3 fields then rejoin the rest)
    readonly property var _devProc: Process {
        id: devProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "dev"]
        running: false
        property bool found: false

        stdout: SplitParser {
            onRead: function(line) {
                if (devProc.found) return
                const parts = line.split(":")
                if (parts.length < 4) return
                const dev   = parts[0]
                const type  = parts[1]
                const state = parts[2]
                // Rejoin remaining parts in case the connection name has colons
                const name  = parts.slice(3).join(":")

                if (state !== "connected" || !name || name === "--") return
                if (type === "loopback" || type === "dummy" || dev.startsWith("lo")) return

                root.device         = dev
                root.connectionName = name
                root.connected      = true
                devProc.found       = true

                if (type.includes("wireless") || type === "wifi")
                    root.connectionType = "wifi"
                else if (type.includes("vpn") || type.includes("wireguard"))
                    root.connectionType = "vpn"
                else
                    root.connectionType = "ethernet"
            }
        }

        onExited: {
            if (!found) {
                root.connected      = false
                root.connectionName = ""
                root.connectionType = "none"
                root.device         = ""
                root.signal         = 0
            }
            found = false
        }
    }

    // ── Process 2: WiFi signal for the active AP ──────────────────────────
    // Format per line: IN-USE:SIGNAL  — "*" marks the connected AP
    readonly property var _wifiProc: Process {
        id: wifiProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL", "dev", "wifi",
                  "list", "--rescan", "no"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                if (line.startsWith("*:")) {
                    const s = parseInt(line.substring(2))
                    if (!isNaN(s)) root.signal = s
                }
            }
        }
    }

    // ── Process 3: IP of the outgoing default interface ───────────────────
    readonly property var _ipProc: Process {
        id: ipProc
        command: ["bash", "-c",
                  "ip -4 route get 1.1.1.1 2>/dev/null | grep -oP 'src \\K[\\d.]+'"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                const ip = line.trim()
                if (ip) root.ipAddress = ip
            }
        }
    }

    readonly property var _ticker: Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            devProc.running  = true
            wifiProc.running = true
            ipProc.running   = true
        }
    }
}

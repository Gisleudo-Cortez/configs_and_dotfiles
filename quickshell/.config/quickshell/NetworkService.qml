pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property string connectionName: ""
    property string connectionType: "none"  // "wifi" | "ethernet" | "vpn" | "none"
    property string device: ""
    property int signal: 0       // 0-100, WiFi only
    property string ipAddress: ""
    property bool connected: false

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

    // Single bash script: connection name/type/device, then signal (WiFi) and IP
    readonly property var _proc: Process {
        id: netProc
        command: ["bash", "-c", [
            "active=$(nmcli -t -f NAME,TYPE,DEVICE con show --active 2>/dev/null",
            "  | grep -v ':loopback:' | head -1)",
            "[ -z \"$active\" ] && exit 1",
            "name=$(echo \"$active\" | cut -d: -f1)",
            "type=$(echo \"$active\" | cut -d: -f2)",
            "dev=$(echo  \"$active\" | cut -d: -f3)",
            "echo \"conn:$name:$type:$dev\"",
            "if echo \"$type\" | grep -qi wireless; then",
            "  sig=$(nmcli -t -f IN-USE,SIGNAL dev wifi list ifname \"$dev\" --rescan no 2>/dev/null",
            "        | grep '^\\*' | cut -d: -f2 | head -1)",
            "  echo \"signal:${sig:-0}\"",
            "fi",
            "ip=$(ip -4 addr show \"$dev\" 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | head -1)",
            "[ -n \"$ip\" ] && echo \"ip:$ip\""
        ].join("; ")]
        running: false
        property bool gotConn: false

        stdout: SplitParser {
            onRead: function(line) {
                if (line.startsWith("conn:")) {
                    const parts = line.substring(5).split(":")
                    root.connectionName = parts[0] ?? ""
                    const t = (parts[1] ?? "").toLowerCase()
                    if (t.includes("wireless") || t.includes("wifi")) root.connectionType = "wifi"
                    else if (t.includes("vpn") || t.includes("wireguard")) root.connectionType = "vpn"
                    else root.connectionType = "ethernet"
                    root.device = parts[2] ?? ""
                    root.connected = true
                    netProc.gotConn = true
                } else if (line.startsWith("signal:")) {
                    root.signal = parseInt(line.substring(7)) || 0
                } else if (line.startsWith("ip:")) {
                    root.ipAddress = line.substring(3)
                }
            }
        }

        onExited: function(code) {
            if (code !== 0 || !gotConn) {
                root.connected = false
                root.connectionName = ""
                root.connectionType = "none"
                root.signal = 0
                root.ipAddress = ""
            }
            gotConn = false
        }
    }

    readonly property var _ticker: Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netProc.running = true
    }
}

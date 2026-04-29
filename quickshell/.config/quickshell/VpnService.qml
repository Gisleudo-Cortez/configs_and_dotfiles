pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool   connected: false
    property string country:   ""
    property string city:      ""
    property string server:    ""
    property string protocol:  ""
    property string exitIp:    ""
    property string visibleIp: ""  // apparent IP when disconnected

    // "City, Country" when connected; "Brazil, Natal" when disconnected
    readonly property string locationLabel: {
        const loc = city ? city + ", " + country : country
        return loc || "—"
    }

    readonly property var _proc: Process {
        id: mullvadProc
        command: ["mullvad", "status", "--json"]
        running: false
        property string buf: ""

        stdout: SplitParser {
            onRead: function(line) { mullvadProc.buf += line }
        }

        onExited: {
            try {
                const d = JSON.parse(mullvadProc.buf)
                root.connected = d.state === "connected"

                const loc = (d.details && d.details.location) ? d.details.location : {}
                root.country  = loc.country   ?? ""
                root.city     = loc.city      ?? ""
                root.exitIp   = loc.ipv4      ?? ""
                root.server   = loc.hostname  ?? ""

                if (root.connected) {
                    root.visibleIp = ""
                    // tunnel type is nested inside details.tunnel_state or similar
                    const tn = (d.details && d.details.tunnel) ? d.details.tunnel : {}
                    root.protocol = tn.type ?? "WireGuard"
                } else {
                    root.visibleIp = root.exitIp
                    root.protocol  = ""
                }
            } catch (_) {
                root.connected = false
            }
            mullvadProc.buf = ""
        }
    }

    readonly property var _ticker: Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: mullvadProc.running = true
    }
}

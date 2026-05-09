pragma Singleton
import QtQuick
import Quickshell.Io

// Mic status service.
// Polls pactl source-outputs for app names using the mic.
// Bar chip: icon + count (or "…" if >1). Tooltip: full list.
QtObject {
    id: root

    property int    activeCount: 0
    property string tooltipText: ""
    property var    appNames: []     // array of unique names
    readonly property bool inUse: activeCount > 0

    readonly property var _proc: Process {
        id: micProc
        command: [
            "sh", "-c",
            `pactl list source-outputs 2>/dev/null |
             awk '/application.name/ { gsub(/[="[:space:]]+/,""); print }'`
        ]
        running: false
        property var _buf: []

        stdout: SplitParser {
            onRead: function(line) {
                var n = line.trim()
                if (n !== "" && micProc._buf.indexOf(n) === -1)
                    micProc._buf.push(n)
            }
        }

        onExited: {
            root.appNames = micProc._buf.slice()
            micProc._buf = []
            var n = root.appNames.length
            root.activeCount = n
            root.tooltipText = n > 0
                ? "Mic used by: " + root.appNames.join(", ")
                : "Mic inactive"
        }
    }

    readonly property var _ticker: Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { micProc.running = true }
    }
}

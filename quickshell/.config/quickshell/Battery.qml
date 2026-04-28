pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root
    property int percent: 0
    property bool charging: false

    readonly property var _capProc: Process {
        command: ["cat", "/sys/class/power_supply/BAT0/capacity"]
        running: false
        stdout: SplitParser {
            onRead: function(line) { root.percent = parseInt(line.trim()) || 0 }
        }
    }
    readonly property var _statProc: Process {
        command: ["cat", "/sys/class/power_supply/BAT0/status"]
        running: false
        stdout: SplitParser {
            onRead: function(line) { root.charging = line.trim() === "Charging" }
        }
    }
    readonly property var _ticker: Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { root._capProc.running = true; root._statProc.running = true }
    }
}

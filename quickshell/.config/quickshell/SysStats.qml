pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property real cpuPercent: 0
    property real ramPercent: 0
    property real diskPercent: 0
    property real gpuPercent: 0
    property real gpuVramUsed: 0
    property real gpuVramTotal: 0

    // CPU via /proc/stat
    property var _prevCpu: []
    readonly property var _cpuProc: Process {
        command: ["cat", "/proc/stat"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                if (!line.startsWith("cpu ")) return
                const parts = line.trim().split(/\s+/)
                const vals = parts.slice(1).map(Number)
                const idle = vals[3] + (vals[4] || 0)
                const total = vals.reduce((a, b) => a + b, 0)
                if (root._prevCpu.length === 2) {
                    const dTotal = total - root._prevCpu[0]
                    const dIdle  = idle  - root._prevCpu[1]
                    root.cpuPercent = dTotal > 0 ? Math.round((1 - dIdle / dTotal) * 100) : 0
                }
                root._prevCpu = [total, idle]
            }
        }
    }

    // RAM via /proc/meminfo
    readonly property var _ramProc: Process {
        command: ["cat", "/proc/meminfo"]
        running: false
        property real total: 0
        property real avail: 0
        stdout: SplitParser {
            onRead: function(line) {
                const m = line.match(/^(\w+):\s+(\d+)/)
                if (!m) return
                if (m[1] === "MemTotal")     parent.total = Number(m[2])
                if (m[1] === "MemAvailable") parent.avail = Number(m[2])
            }
        }
        onExited: {
            if (total > 0)
                root.ramPercent = Math.round((1 - avail / total) * 100)
        }
    }

    // Disk via df
    readonly property var _diskProc: Process {
        command: ["df", "-P", "/"]
        running: false
        property bool first: true
        stdout: SplitParser {
            onRead: function(line) {
                if (parent.first) { parent.first = false; return }
                const parts = line.trim().split(/\s+/)
                if (parts.length >= 5)
                    root.diskPercent = parseInt(parts[4])
                parent.first = true
            }
        }
    }

    // GPU via nvidia-smi
    readonly property var _gpuProc: Process {
        command: ["nvidia-smi",
                  "--query-gpu=utilization.gpu,memory.used,memory.total",
                  "--format=csv,noheader,nounits"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                const parts = line.split(",").map(s => parseFloat(s.trim()))
                if (parts.length >= 3) {
                    root.gpuPercent   = parts[0]
                    root.gpuVramUsed  = parts[1]
                    root.gpuVramTotal = parts[2]
                }
            }
        }
    }

    readonly property var _ticker: Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root._cpuProc.running  = true
            root._ramProc.running  = true
            root._diskProc.running = true
            root._gpuProc.running  = true
        }
    }
}

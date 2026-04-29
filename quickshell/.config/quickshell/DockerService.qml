pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property var containers: []
    property int runningCount: 0
    property bool available: false

    readonly property var _proc: Process {
        id: dockerProc
        command: ["docker", "ps", "--format", "{{.Names}}\t{{.Status}}\t{{.Image}}"]
        running: false
        property var lines: []

        stdout: SplitParser {
            onRead: function(line) {
                if (line.trim()) dockerProc.lines.push(line)
            }
        }

        onExited: function(code) {
            if (code === 0) {
                root.available = true
                const result = []
                for (let i = 0; i < dockerProc.lines.length; i++) {
                    const parts = dockerProc.lines[i].split("\t")
                    if (parts.length >= 3) {
                        result.push({ name: parts[0], status: parts[1], image: parts[2] })
                    }
                }
                root.containers = result
                root.runningCount = result.length
            } else {
                root.available = false
                root.containers = []
                root.runningCount = 0
            }
            dockerProc.lines = []
        }
    }

    readonly property var _ticker: Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: dockerProc.running = true
    }
}

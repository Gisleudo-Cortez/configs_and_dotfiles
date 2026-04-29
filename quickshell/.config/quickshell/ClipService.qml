pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property var entries: []
    property bool loading: false

    readonly property var _listProc: Process {
        command: ["cliphist", "list"]
        running: false
        property var lines: []

        stdout: SplitParser {
            onRead: function(line) {
                if (line.trim()) parent.lines.push(line)
            }
        }
        onExited: {
            root.entries = lines.slice(0, 30)
            lines = []
            root.loading = false
        }
    }

    function refresh() {
        if (_listProc.running) return
        loading = true
        _listProc.running = true
    }

    // Entry is passed as positional arg $1 to avoid stdin timing races.
    readonly property var _copyProc: Process {
        running: false
    }

    function copy(entry) {
        if (_copyProc.running) return
        _copyProc.command = ["bash", "-c",
            "printf '%s\\n' \"$1\" | cliphist decode | wl-copy", "bash", entry]
        _copyProc.running = true
    }
}

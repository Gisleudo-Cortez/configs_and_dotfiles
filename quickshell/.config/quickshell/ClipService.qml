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
        loading = true
        _listProc.running = true
    }

    readonly property var _copyProc: Process {
        command: ["bash", "-c", "cliphist decode | wl-copy"]
        stdinEnabled: true
        running: false
    }

    function copy(entry) {
        if (_copyProc.running) return
        _copyProc.running = true
        _copyProc.write(entry + "\n")
    }
}

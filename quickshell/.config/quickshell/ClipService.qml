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

    // Entry written to stdin after process starts (onStarted fires when pipe is ready).
    readonly property var _copyProc: Process {
        command: ["bash", "-c", "cliphist decode | wl-copy"]
        stdinEnabled: true
        running: false
        property string _entry: ""

        onStarted: {
            if (_entry !== "") {
                write(_entry + "\n")
                _entry = ""
            }
        }
    }

    function copy(entry) {
        if (_copyProc.running) return
        _copyProc._entry = entry
        _copyProc.running = true
    }
}

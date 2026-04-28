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
        onFinished: {
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
        id: copyProc
        running: false
        property string pending: ""
    }

    function copyEntry(entry) {
        // cliphist decode <entry> | wl-copy
        const proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { command: ["bash", "-c", "cliphist decode | wl-copy"]; running: true }',
            root, "copyProc")
        const inProc = Qt.createQmlObject(
            `import Quickshell.Io; Process { command: ["cliphist", "decode"]; running: true }`,
            root, "decodeProc")
    }

    // Simpler: pipe via shell
    function copy(entry) {
        const escaped = entry.replace(/'/g, "'\\''")
        const proc = Qt.createQmlObject(
            `import Quickshell.Io; Process {
                command: ["bash", "-c", "echo '${escaped}' | cliphist decode | wl-copy"]
                running: true
            }`, root, "dynCopy")
    }
}

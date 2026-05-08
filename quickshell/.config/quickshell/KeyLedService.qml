pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool capsLock: false
    property bool numLock: false

    readonly property var _capsProc: Process {
        command: ["cat", "/sys/class/leds/input15::capslock/brightness"]
        running: false
        stdout: SplitParser {
            onRead: function(line) { root.capsLock = line.trim() === "1" }
        }
    }

    readonly property var _numProc: Process {
        command: ["cat", "/sys/class/leds/input15::numlock/brightness"]
        running: false
        stdout: SplitParser {
            onRead: function(line) { root.numLock = line.trim() === "1" }
        }
    }

    readonly property var _ticker: Timer {
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root._capsProc.running = true
            root._numProc.running  = true
        }
    }
}

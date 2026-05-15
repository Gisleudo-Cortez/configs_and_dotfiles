pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool capsLock: false
    property bool numLock: false

    // Use wildcard shell command to find ANY numlock/capslock LED.
    // input paths are dynamic (input3, input14, input15, …) and
    // can change on reboot or USB replug. Checking all of them
    // prevents the indicator from flickering when one path disappears.
    readonly property var _capsProc: Process {
        command: ["sh", "-c", "for f in /sys/class/leds/*::capslock/brightness; do [ -r \"$f\" ] && [ \"$(cat \"$f\")\" = \"1\" ] && exit 0; done; exit 1"]
        running: false
        onExited: { root.capsLock = (exitCode === 0) }
    }

    readonly property var _numProc: Process {
        command: ["sh", "-c", "for f in /sys/class/leds/*::numlock/brightness; do [ -r \"$f\" ] && [ \"$(cat \"$f\")\" = \"1\" ] && exit 0; done; exit 1"]
        running: false
        onExited: { root.numLock = (exitCode === 0) }
    }

    readonly property var _ticker: Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root._capsProc.running = true
            root._numProc.running  = true
        }
    }
}

pragma Singleton
import QtQuick
import Quickshell.Io

// Camera status service.
// Polls /dev/video* via fuser to find which apps use each camera.
// Requires user in the 'video' group for fuser to report PIDs.
// Run:  sudo usermod -a -G video $USER  then re-login.
// Falls back to showing device count (from ls /dev/video*) when
// fuser reports nothing, so at least device presence is visible.
QtObject {
    id: root

    property int    activeCount: 0     // apps using cameras (0 if no video group)
    property int    deviceCount: 0     // how many /dev/video* nodes exist
    property string tooltipText: ""
    readonly property bool inUse: activeCount > 0
    readonly property bool hasDevices: deviceCount > 0

    readonly property var _proc: Process {
        id: camProc
        command: [
            "sh", "-c",
            `NDEV=$(ls /dev/video* 2>/dev/null | wc -l)
             echo "DEVS=$NDEV"
             for d in /dev/video*; do
               [ -e "$d" ] || continue
               out=$(fuser "$d" 2>/dev/null | tr ' ' '\n' | grep -v '^$')
               cmds=""
               first=1
               for p in $out; do
                 c=$(readlink /proc/$p/exe 2>/dev/null | xargs basename 2>/dev/null)
                 [ -z "$c" ] && continue
                 if [ $first -eq 1 ]; then first=0; else cmds="${cmds},"; fi
                 cmds="${cmds}${c}"
               done
               echo "{\"dev\":\"$d\",\"cmds\":\"$cmds\"}"
             done`
        ]
        running: false

        property var _buf:   []
        property int _count: 0

        stdout: SplitParser {
            onRead: function(line) {
                if (line.startsWith("DEVS=")) {
                    camProc._count = parseInt(line.substring(5))
                    return
                }
                try {
                    var obj = JSON.parse(line)
                    camProc._buf.push(obj)
                } catch (e) {}
            }
        }

        onExited: {
            root.deviceCount = camProc._count
            root.devices     = camProc._buf.slice()
            camProc._buf = []

            var count = 0
            var tip   = ""
            var devs  = root.devices
            for (var i = 0; i < devs.length; i++) {
                var d = devs[i]
                if (!d.cmds || d.cmds === "") continue
                count++
                var short = d.dev.replace(/\/dev\//, "")
                tip += short + ": " + d.cmds.replace(/,/g, ", ")
                if (i < devs.length - 1) tip += "  ·  "
            }
            root.activeCount = count
            if (count > 0)
                root.tooltipText = tip
            else if (root.deviceCount > 0)
                root.tooltipText = root.deviceCount + " camera(s) detected — join 'video' group for per-app info"
            else
                root.tooltipText = "Cameras inactive"
        }
    }

    readonly property var _ticker: Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { camProc.running = true }
    }
}

pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root
    property real rxKbps: 0
    property real txKbps: 0

    function _fmtSpeed(kbps) {
        if (kbps >= 1024) return (kbps / 1024).toFixed(1) + " MB/s"
        return Math.round(kbps) + " KB/s"
    }
    readonly property string rxText: _fmtSpeed(rxKbps)
    readonly property string txText: _fmtSpeed(txKbps)

    readonly property var _proc: Process {
        id: netProc
        command: ["cat", "/proc/net/dev"]
        running: false
        property real sumRx: 0
        property real sumTx: 0
        property int lineCount: 0

        stdout: SplitParser {
            onRead: function(line) {
                if (netProc.lineCount < 2) { netProc.lineCount++; return }
                const parts = line.trim().split(/\s+/)
                if (parts.length < 10) return
                const iface = parts[0].replace(":", "")
                if (iface === "lo") return
                netProc.sumRx += parseFloat(parts[1]) || 0
                netProc.sumTx += parseFloat(parts[9]) || 0
            }
        }
        onExited: {
            const now = Date.now() / 1000
            if (root._prevTime > 0) {
                const dt = now - root._prevTime
                root.rxKbps = Math.max(0, (sumRx - root._prevRxBytes) / dt / 1024)
                root.txKbps = Math.max(0, (sumTx - root._prevTxBytes) / dt / 1024)
            }
            root._prevTime     = now
            root._prevRxBytes  = sumRx
            root._prevTxBytes  = sumTx
            sumRx = 0; sumTx = 0; lineCount = 0
        }
    }

    property real _prevTime: 0
    property real _prevRxBytes: 0
    property real _prevTxBytes: 0

    readonly property var _ticker: Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._proc.running = true
    }
}

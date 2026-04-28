import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Bluetooth

Island {
    id: root
    implicitWidth: row.implicitWidth + Geometry.innerPad * 2

    signal notifClicked
    signal clipClicked

    // ── Volume ────────────────────────────────────────────────────────────
    property int volume: 0
    property bool muted: false

    readonly property var _volProc: Process {
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                const m = line.match(/([\d.]+)/)
                if (m) root.volume = Math.round(parseFloat(m[1]) * 100)
                root.muted = line.includes("MUTED")
            }
        }
    }
    readonly property var _volTicker: Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root._volProc.running = true
    }

    // ── helpers ───────────────────────────────────────────────────────────
    function _statColor(pct, warn, crit) {
        if (pct >= crit) return Colors.alert
        if (pct >= warn) return Colors.warning
        return Colors.text
    }

    function _battIcon(pct, charging) {
        if (charging) return "󰂄"
        if (pct >= 90) return "󰁹"
        if (pct >= 70) return "󰂀"
        if (pct >= 50) return "󰁾"
        if (pct >= 30) return "󰁼"
        if (pct >= 10) return "󰁺"
        return "󰂃"
    }

    function _volIcon(pct, muted) {
        if (muted || pct === 0) return "󰝟"
        if (pct < 40) return "󰕿"
        if (pct < 75) return "󰖀"
        return "󰕾"
    }

    // ── layout ────────────────────────────────────────────────────────────
    RowLayout {
        id: row
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        anchors.leftMargin: Geometry.innerPad
        anchors.rightMargin: Geometry.innerPad
        spacing: 10

        // CPU
        StatChip { icon: ""; value: SysStats.cpuPercent + "%"; color: root._statColor(SysStats.cpuPercent, 70, 90) }

        // RAM
        StatChip { icon: ""; value: SysStats.ramPercent + "%"; color: root._statColor(SysStats.ramPercent, 70, 90) }

        // Disk
        StatChip { icon: "󰋊"; value: SysStats.diskPercent + "%"; color: root._statColor(SysStats.diskPercent, 80, 95) }

        // GPU
        StatChip { icon: "󰢮"; value: SysStats.gpuPercent + "%"; color: root._statColor(SysStats.gpuPercent, 70, 90) }

        BarSep {}

        // Network
        Column {
            spacing: 0
            Text { text: " " + NetMonitor.txText; color: Colors.cyan;  font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }
            Text { text: " " + NetMonitor.rxText; color: Colors.green; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }
        }

        BarSep {}

        // Bluetooth
        Text {
            text: Bluetooth.defaultAdapter.enabled ? "󰂯" : "󰂲"
            color: Bluetooth.defaultAdapter.enabled ? Colors.blue : Colors.textDim
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Geometry.fontSize
        }

        // Volume
        StatChip {
            icon: root._volIcon(root.volume, root.muted)
            value: root.volume + "%"
            color: root.muted ? Colors.textDim : Colors.text
        }

        // Battery
        StatChip {
            icon: root._battIcon(Battery.percent, Battery.charging)
            value: Battery.percent + "%"
            color: root._statColor(100 - Battery.percent, 30, 10)
        }

        BarSep {}

        // Notification bell
        Text {
            text: NotifService.unreadCount > 0 ? "󱅫" : "󰂚"
            color: NotifService.unreadCount > 0 ? Colors.purple : Colors.textDim
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Geometry.fontSize
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.notifClicked()
            }
        }

        // Clipboard
        Text {
            text: "󰅎"
            color: Colors.textDim
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Geometry.fontSize
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { ClipService.refresh(); root.clipClicked() }
            }
        }
    }

    HudCorners { anchors.fill: parent }
}

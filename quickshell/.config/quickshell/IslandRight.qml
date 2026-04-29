import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Mpris

Island {
    id: root
    implicitWidth: row.implicitWidth + Geometry.innerPad * 2

    signal notifClicked
    signal clipClicked
    signal mediaClicked

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

    readonly property var _muteProc: Process {
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        running: false
        onExited: root._volProc.running = true
    }

    readonly property var _volAdjProc: Process {
        running: false
        onExited: root._volProc.running = true
    }

    // ── MPRIS ─────────────────────────────────────────────────────────────
    readonly property var _activePlayer: {
        if (!Mpris.players || Mpris.players.count === 0) return null
        const players = Mpris.players.values
        for (let i = 0; i < players.length; i++) {
            if (players[i].isPlaying) return players[i]
        }
        return players[0]
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
        StatChip { icon: ""; value: SysStats.cpuPercent + "%"; color: root._statColor(SysStats.cpuPercent, 70, 90) }

        // RAM
        StatChip { icon: ""; value: SysStats.ramPercent + "%"; color: root._statColor(SysStats.ramPercent, 70, 90) }

        // Disk
        StatChip { icon: "󰋊"; value: SysStats.diskPercent + "%"; color: root._statColor(SysStats.diskPercent, 80, 95) }

        // GPU
        StatChip { icon: "󰢮"; value: SysStats.gpuPercent + "%"; color: root._statColor(SysStats.gpuPercent, 70, 90) }

        BarSep {}

        // Network
        Column {
            spacing: 0
            Text { text: " " + NetMonitor.txText; color: Colors.cyan;  font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }
            Text { text: " " + NetMonitor.rxText; color: Colors.green; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }
        }

        BarSep {}

        // Bluetooth
        Text {
            text: Bluetooth.defaultAdapter?.enabled ? "󰂯" : "󰂲"
            color: Bluetooth.defaultAdapter?.enabled ? Colors.blue : Colors.textDim
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Geometry.fontSize
            visible: Bluetooth.defaultAdapter !== null
        }

        // Volume — click to mute, scroll to adjust
        Item {
            implicitWidth: volChip.implicitWidth
            implicitHeight: Geometry.barHeight

            StatChip {
                id: volChip
                anchors.centerIn: parent
                icon: root._volIcon(root.volume, root.muted)
                value: root.volume + "%"
                color: root.muted ? Colors.textDim : Colors.text
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root._muteProc.running = true
                onWheel: function(wheel) {
                    if (root._volAdjProc.running) return
                    const step = wheel.angleDelta.y > 0 ? "5%+" : "5%-"
                    root._volAdjProc.command = ["wpctl", "set-volume", "--limit", "1.5",
                                                "@DEFAULT_AUDIO_SINK@", step]
                    root._volAdjProc.running = true
                }
            }
        }

        // Battery
        StatChip {
            icon: root._battIcon(Battery.percent, Battery.charging)
            value: Battery.percent + "%"
            color: root._statColor(100 - Battery.percent, 30, 10)
        }

        BarSep {}

        // Media indicator (only when a player is present)
        Text {
            visible: Mpris.players.count > 0
            text: "󰝚"
            color: root._activePlayer?.isPlaying ? Colors.green : Colors.textDim
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Geometry.fontSize
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.mediaClicked()
            }
        }

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
                onClicked: root.clipClicked()
            }
        }
    }

    HudCorners { anchors.fill: parent }
}

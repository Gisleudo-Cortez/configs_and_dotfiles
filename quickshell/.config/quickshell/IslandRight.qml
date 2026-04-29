import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Bluetooth
import Quickshell.Services.Mpris

Island {
    id: root
    implicitWidth: row.implicitWidth + Geometry.innerPad * 2

    // Screen reference passed from Bar so hover popups know which screen they're on
    property var screen

    signal notifClicked
    signal clipClicked
    signal mediaClicked
    signal audioClicked
    signal dockerClicked
    signal btClicked

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

    readonly property var _activePlayer: {
        if (!Mpris.players || Mpris.players.count === 0) return null
        const players = Mpris.players.values
        for (let i = 0; i < players.length; i++) {
            if (players[i].isPlaying) return players[i]
        }
        return players[0]
    }

    // ── Net + VPN shared hover state ──────────────────────────────────────
    property bool _netHovered: false
    property bool _vpnHovered: false

    Timer {
        id: netHoverTimer
        interval: 400
        onTriggered: PopupState.showHover("network", root.screen)
    }

    function _checkNetHover() {
        if (_netHovered || _vpnHovered) netHoverTimer.start()
        else { netHoverTimer.stop(); PopupState.clearHover("network") }
    }

    // ── layout ────────────────────────────────────────────────────────────
    RowLayout {
        id: row
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        anchors.leftMargin: Geometry.innerPad
        anchors.rightMargin: Geometry.innerPad
        spacing: 10

        // ── System stats ──────────────────────────────────────────────────
        StatChip {
            icon: "󰻠"
            value: SysStats.cpuPercent + "%"
            color: root._statColor(SysStats.cpuPercent, 70, 90)
            tooltip: "CPU  " + SysStats.cpuPercent + "%"
        }

        StatChip {
            icon: "󰍛"
            value: SysStats.ramPercent + "%"
            color: root._statColor(SysStats.ramPercent, 70, 90)
            tooltip: "RAM  " + SysStats.ramPercent + "% used"
        }

        StatChip {
            icon: "󰋊"
            value: SysStats.diskPercent + "%"
            color: root._statColor(SysStats.diskPercent, 80, 95)
            tooltip: "Disk /  " + SysStats.diskPercent + "%"
        }

        StatChip {
            visible: SysStats.gpuVramTotal > 0
            icon: "󰢮"
            value: SysStats.gpuPercent + "%"
            color: root._statColor(SysStats.gpuPercent, 70, 90)
            tooltip: "GPU  " + SysStats.gpuPercent + "% · VRAM " +
                     (SysStats.gpuVramUsed / 1024).toFixed(1) + " / " +
                     (SysStats.gpuVramTotal / 1024).toFixed(1) + " GB"
        }

        BarSep {}

        // ── Network + VPN (shared hover → NetworkPopup) ───────────────────
        Item {
            id: netWidget
            implicitWidth: netRow.implicitWidth
            implicitHeight: Geometry.barHeight

            RowLayout {
                id: netRow
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: NetworkService.typeIcon
                    color: NetworkService.connected ? Colors.cyan : Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSize
                }

                Text {
                    text: NetworkService.shortName
                    color: NetworkService.connected ? Colors.text : Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSizeSm
                }
            }

            HoverHandler {
                onHoveredChanged: { root._netHovered = hovered; root._checkNetHover() }
            }
        }

        // ── VPN (Mullvad) ─────────────────────────────────────────────────
        Item {
            id: vpnWidget
            implicitWidth: vpnText.implicitWidth + 6
            implicitHeight: Geometry.barHeight

            Text {
                id: vpnText
                anchors.centerIn: parent
                text: "󰒄"
                color: VpnService.connected ? Colors.green : Colors.textDim
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: Geometry.fontSize
            }

            HoverHandler {
                onHoveredChanged: { root._vpnHovered = hovered; root._checkNetHover() }
            }

            ToolTip.visible: root._vpnHovered
            ToolTip.delay: 700
            ToolTip.text: VpnService.connected
                          ? "Mullvad · " + VpnService.locationLabel
                          : "Mullvad · disconnected · " + VpnService.locationLabel
        }

        BarSep {}

        // ── Docker ────────────────────────────────────────────────────────
        Item {
            visible: DockerService.available
            implicitWidth: dockerChip.implicitWidth
            implicitHeight: Geometry.barHeight

            StatChip {
                id: dockerChip
                anchors.centerIn: parent
                icon: "󰡨"
                value: DockerService.runningCount + ""
                color: DockerService.runningCount > 0 ? Colors.cyan : Colors.textDim
                tooltip: "Docker · " + DockerService.runningCount + " running"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.dockerClicked()
            }
        }

        // ── Bluetooth ─────────────────────────────────────────────────────
        Item {
            id: btWidget
            visible: Bluetooth.defaultAdapter !== null
            implicitWidth: btText.implicitWidth + 4
            implicitHeight: Geometry.barHeight

            Text {
                id: btText
                anchors.centerIn: parent
                text: Bluetooth.defaultAdapter?.enabled ? "󰂯" : "󰂲"
                color: {
                    if (!(Bluetooth.defaultAdapter?.enabled ?? false)) return Colors.textDim
                    const devs = Bluetooth.defaultAdapter?.devices
                    for (let i = 0; i < (devs?.count ?? 0); i++) {
                        if (devs.values[i].connected) return Colors.blue
                    }
                    return Qt.rgba(0.247, 0.725, 0.976, 0.5)
                }
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: Geometry.fontSize

                ToolTip.visible: btHover.hovered
                ToolTip.delay: 600
                ToolTip.text: {
                    if (!(Bluetooth.defaultAdapter?.enabled ?? false)) return "Bluetooth off"
                    const devs = Bluetooth.defaultAdapter?.devices
                    if (!devs || devs.count === 0) return "Bluetooth on · no devices"
                    let connected = 0
                    for (let i = 0; i < devs.count; i++) {
                        if (devs.values[i].connected) connected++
                    }
                    return "Bluetooth · " + connected + " connected"
                }
            }

            HoverHandler {
                id: btHover
                onHoveredChanged: {
                    if (hovered) btHoverTimer.start()
                    else {
                        btHoverTimer.stop()
                        PopupState.clearHover("bluetooth")
                    }
                }
            }

            Timer {
                id: btHoverTimer
                interval: 500
                onTriggered: PopupState.showHover("bluetooth", root.screen)
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    btHoverTimer.stop()
                    PopupState.clearHover("bluetooth")
                    root.btClicked()
                }
            }
        }

        // ── Audio ─────────────────────────────────────────────────────────
        Item {
            id: audioWidget
            implicitWidth: audioRow.implicitWidth + 4
            implicitHeight: Geometry.barHeight

            RowLayout {
                id: audioRow
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: AudioService.volIcon()
                    color: AudioService.muted ? Colors.textDim : Colors.text
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSize
                }

                Text {
                    text: AudioService.sinkShortName
                    color: Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSizeSm
                    visible: AudioService.sinkShortName !== ""
                }

                Text {
                    text: AudioService.volPct() + "%"
                    color: AudioService.muted ? Colors.textDim : Colors.text
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSizeSm
                }
            }

            HoverHandler { id: audioHover }
            ToolTip.visible: audioHover.hovered
            ToolTip.delay: 600
            ToolTip.text: AudioService.sinkName + "\n" +
                          AudioService.volPct() + "%" +
                          (AudioService.muted ? " (muted)" : "") +
                          "\nLeft-click: open · Scroll: ±5% · Vol icon: mute"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.audioClicked()
                onWheel: function(wheel) {
                    AudioService.adjustVolume(wheel.angleDelta.y > 0 ? 0.05 : -0.05)
                }
            }
        }

        // ── Battery ───────────────────────────────────────────────────────
        StatChip {
            icon: root._battIcon(Battery.percent, Battery.charging)
            value: Battery.percent + "%"
            color: root._statColor(100 - Battery.percent, 30, 10)
            tooltip: "Battery  " + Battery.percent + "% · " +
                     (Battery.charging ? "Charging" : "Discharging")
            visible: Battery.percent > 0
        }

        BarSep {}

        // ── Media ─────────────────────────────────────────────────────────
        Item {
            visible: Mpris.players.count > 0
            implicitWidth: mediaText.implicitWidth + 4
            implicitHeight: Geometry.barHeight

            Text {
                id: mediaText
                anchors.centerIn: parent
                text: "󰝚"
                color: root._activePlayer?.isPlaying ? Colors.green : Colors.textDim
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: Geometry.fontSize
            }

            HoverHandler { id: mediaHover }
            ToolTip.visible: mediaHover.hovered && root._activePlayer !== null
            ToolTip.delay: 600
            ToolTip.text: {
                const p = root._activePlayer
                if (!p) return ""
                const title = p.trackTitle || "Unknown"
                const artist = p.trackArtist || ""
                return (artist ? artist + " — " : "") + title
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.mediaClicked()
            }
        }

        // ── Notification bell ─────────────────────────────────────────────
        Item {
            implicitWidth: bellText.implicitWidth + 4
            implicitHeight: Geometry.barHeight

            Text {
                id: bellText
                anchors.centerIn: parent
                text: NotifService.unreadCount > 0 ? "󱅫" : "󰂚"
                color: NotifService.unreadCount > 0 ? Colors.purple : Colors.textDim
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: Geometry.fontSize
            }

            HoverHandler { id: bellHover }
            ToolTip.visible: bellHover.hovered
            ToolTip.delay: 600
            ToolTip.text: NotifService.unreadCount > 0
                          ? NotifService.unreadCount + " unread notification" +
                            (NotifService.unreadCount > 1 ? "s" : "")
                          : "No notifications"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.notifClicked()
            }
        }

        // ── Clipboard ─────────────────────────────────────────────────────
        Item {
            implicitWidth: clipText.implicitWidth + 4
            implicitHeight: Geometry.barHeight

            Text {
                id: clipText
                anchors.centerIn: parent
                text: "󰅎"
                color: Colors.textDim
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: Geometry.fontSize
            }

            HoverHandler { id: clipHover }
            ToolTip.visible: clipHover.hovered
            ToolTip.delay: 600
            ToolTip.text: "Clipboard history"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clipClicked()
            }
        }
    }

    HudCorners { anchors.fill: parent }
}

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Services.Mpris

Island {
    id: root
    implicitWidth: row.implicitWidth + Geometry.innerPad * 2

    property var screen

    signal notifClicked
    signal clipClicked
    signal mediaClicked
    signal audioClicked
    signal dockerClicked
    signal btClicked

    // ── helpers ───────────────────────────────────────────────────────────
    function _battColor(pct) {
        pct = Math.max(0, Math.min(100, pct))
        if (pct >= 50) {
            const t = (pct - 50) / 50
            return Qt.rgba(0.0 * (1-t) + 0.0 * t, 0.784 * (1-t) + 0.706 * t, 0.667 * (1-t) + 0.533 * t, 1.0)
        }
        const t = pct / 50
        return Qt.rgba(1.0 * (1-t) + 0.0 * t, 0.706 * (1-t) + 0.784 * t, 0.0 * (1-t) + 0.667 * t, 1.0)
    }

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

    // ── layout ────────────────────────────────────────────────────────────
    RowLayout {
        id: row
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        anchors.leftMargin: Geometry.innerPad
        anchors.rightMargin: Geometry.innerPad
        spacing: 10

        // ── System stats ──────────────────────────────────────────────────
        StatChip {
            screen: root.screen
            icon: "󰻠"
            value: SysStats.cpuPercent + "%"
            color: root._statColor(SysStats.cpuPercent, 70, 90)
            tooltip: "CPU  " + SysStats.cpuPercent + "%"
        }

        StatChip {
            screen: root.screen
            icon: "󰍛"
            value: SysStats.ramPercent + "%"
            color: root._statColor(SysStats.ramPercent, 70, 90)
            tooltip: "RAM  " + SysStats.ramPercent + "% used"
        }

        StatChip {
            screen: root.screen
            icon: "󰋊"
            value: SysStats.diskPercent + "%"
            color: root._statColor(SysStats.diskPercent, 80, 95)
            tooltip: "Disk /  " + SysStats.diskPercent + "%"
        }

        StatChip {
            visible: SysStats.gpuVramTotal > 0
            screen: root.screen
            icon: "󰢮"
            value: SysStats.gpuPercent + "%"
            color: root._statColor(SysStats.gpuPercent, 70, 90)
            tooltip: "GPU  " + SysStats.gpuPercent + "% · VRAM " +
                     (SysStats.gpuVramUsed / 1024).toFixed(1) + " / " +
                     (SysStats.gpuVramTotal / 1024).toFixed(1) + " GB"
        }

        BarSep {}

        // ── Extracted widgets ────────────────────────────────────────────
        WidgetNetwork { screen: root.screen }

        BarSep {}

        WidgetDocker { screen: root.screen; onClicked: root.dockerClicked() }
        WidgetBluetooth { screen: root.screen; onClicked: root.btClicked() }
        WidgetAudio     { screen: root.screen; onClicked: root.audioClicked() }
        WidgetKeyLed    { }

        BarSep {}

        WidgetMedia     { screen: root.screen; onClicked: root.mediaClicked() }
        WidgetNotifBell { screen: root.screen; onClicked: root.notifClicked() }
        WidgetClipboard { onClicked: root.clipClicked() }

        // ── Misc services (inline StatChip wrappers) ────────────────────
        Item {
            id: cameraWidget
            visible: true
            implicitWidth: cameraChip.implicitWidth + 4
            implicitHeight: Geometry.barHeight

            StatChip {
                id: cameraChip
                anchors.centerIn: parent
                screen: root.screen
                icon: CameraService.inUse ? "󰄀" : "󰄁"
                value: CameraService.activeCount > 0 ? CameraService.activeCount + "" : ""
                color: CameraService.inUse ? Colors.green : Colors.textDim
                tooltip: CameraService.tooltipText
            }
        }

        Item {
            id: micWidget
            implicitWidth: micChip.implicitWidth + 4
            implicitHeight: Geometry.barHeight

            StatChip {
                id: micChip
                anchors.centerIn: parent
                screen: root.screen
                icon: MicService.inUse ? "󰍬" : "󰍭"
                value: MicService.activeCount > 1 ? "…" : (MicService.activeCount > 0 ? MicService.activeCount + "" : "")
                color: MicService.inUse ? Colors.alert : Colors.textDim
                tooltip: MicService.tooltipText
            }
        }

        Item {
            id: usbWidget
            implicitWidth: usbChip.implicitWidth + 4
            implicitHeight: Geometry.barHeight

            StatChip {
                id: usbChip
                anchors.centerIn: parent
                screen: root.screen
                icon: "󰋊"
                value: UsbService.activeCount > 1 ? "…" : (UsbService.available ? UsbService.activeCount + "" : "")
                color: UsbService.available ? Colors.green : Colors.textDim
                tooltip: UsbService.tooltipText
            }
        }

        // ── Battery ───────────────────────────────────────────────────────
        StatChip {
            screen: root.screen
            icon: root._battIcon(Battery.percent, Battery.charging)
            value: Battery.percent + "%"
            color: root._battColor(Battery.percent)
            tooltip: "Battery  " + Battery.percent + "% · " +
                     (Battery.charging ? "Charging" : "Discharging")
            visible: Battery.percent > 0
        }
    }

    HudCorners { anchors.fill: parent }
}

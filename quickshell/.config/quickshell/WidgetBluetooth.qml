import QtQuick
import Quickshell.Bluetooth

// Bluetooth icon with hover tooltip + click to open popup
Item {
    id: root
    visible: Bluetooth.defaultAdapter !== null
    implicitWidth: btText.implicitWidth + 4
    implicitHeight: Geometry.barHeight

    property var screen: null
    signal clicked

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
        font.pixelSize: Geometry.iconFontSize
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered) {
                btHoverTimer.start()
                const devs = Bluetooth.defaultAdapter?.devices
                let connected = 0
                for (let i = 0; i < (devs?.count ?? 0); i++) {
                    if (devs.values[i].connected) connected++
                }
                const text = (Bluetooth.defaultAdapter?.enabled ?? false)
                    ? "Bluetooth · " + connected + " connected"
                    : "Bluetooth off"
                TooltipService.show(text, root.screen)
            } else {
                btHoverTimer.stop()
                PopupState.clearHover("bluetooth")
                TooltipService.hide()
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
            root.clicked()
        }
    }
}

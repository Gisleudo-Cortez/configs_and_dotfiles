import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    readonly property var _screen: screen

    WlrLayershell.namespace: "quickshell:network"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { top: true; right: true }
    exclusiveZone: -1
    margins.top: Geometry.barHeight + Geometry.outerGap * 2 + 4
    margins.right: Geometry.outerGap

    implicitWidth: Geometry.popupWidth
    implicitHeight: box.implicitHeight + Geometry.innerPad * 2
    color: "transparent"

    visible: PopupState.hoverActive === "network" && PopupState.hoverScreen === _screen

    Rectangle {
        anchors.fill: parent
        color: Colors.bgPopup
        radius: Geometry.islandRadius
        border.color: Colors.border
        border.width: Geometry.borderWidth

        ColumnLayout {
            id: box
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.margins: Geometry.innerPad
            spacing: 6

            // ── Network header ────────────────────────────────────────────
            Text {
                text: NetworkService.typeIcon + "  " +
                      (NetworkService.connected ? "Connected" : "Disconnected")
                color: NetworkService.connected ? Colors.cyan : Colors.textDim
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: Geometry.fontSize
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.textDim; opacity: 0.25 }

            // ── Network detail grid ───────────────────────────────────────
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 4
                columnSpacing: 12

                Text { text: "Network"; color: Colors.textDim; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }
                Text { text: NetworkService.connectionName || "—"; color: Colors.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm; Layout.fillWidth: true; elide: Text.ElideRight }

                Text { text: "Type";   color: Colors.textDim; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }
                Text { text: NetworkService.connectionType === "none" ? "—" : NetworkService.connectionType; color: Colors.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }

                Text { text: "Device"; color: Colors.textDim; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }
                Text { text: NetworkService.device || "—"; color: Colors.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }

                Text { text: "IP";     color: Colors.textDim; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }
                Text { text: NetworkService.ipAddress || "—"; color: Colors.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }

                // WiFi signal
                Text { visible: NetworkService.connectionType === "wifi"; text: "Signal"; color: Colors.textDim; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }
                RowLayout {
                    visible: NetworkService.connectionType === "wifi"
                    spacing: 6
                    Text { text: NetworkService.signal + "%"; color: Colors.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }
                    Row {
                        spacing: 2
                        Repeater {
                            model: 5
                            Rectangle {
                                width: 4; height: 6 + index * 2; radius: 1
                                anchors.bottom: parent?.bottom
                                color: (index / 4 * 100) <= NetworkService.signal ? Colors.cyan : Colors.textDim
                                opacity: (index / 4 * 100) <= NetworkService.signal ? 1 : 0.3
                            }
                        }
                    }
                }

                Text { text: "  ↑"; color: Colors.cyan;  font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }
                Text { text: NetMonitor.txText; color: Colors.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }

                Text { text: "  ↓"; color: Colors.green; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }
                Text { text: NetMonitor.rxText; color: Colors.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }
            }

            // ── VPN section ───────────────────────────────────────────────
            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.textDim; opacity: 0.25 }

            // VPN header
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "󰒄  Mullvad"
                    color: VpnService.connected ? Colors.green : Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSize
                    Layout.fillWidth: true
                }
                Text {
                    text: VpnService.connected ? "connected" : "disconnected"
                    color: VpnService.connected ? Colors.green : Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSizeSm
                }
            }

            // VPN detail grid
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 4
                columnSpacing: 12

                // Connected details
                Text { visible: VpnService.connected; text: "Location"; color: Colors.textDim; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }
                Text { visible: VpnService.connected; text: VpnService.locationLabel; color: Colors.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm; Layout.fillWidth: true; elide: Text.ElideRight }

                Text { visible: VpnService.connected && VpnService.server !== ""; text: "Server"; color: Colors.textDim; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }
                Text { visible: VpnService.connected && VpnService.server !== ""; text: VpnService.server; color: Colors.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm; Layout.fillWidth: true; elide: Text.ElideRight }

                Text { visible: VpnService.connected && VpnService.protocol !== ""; text: "Protocol"; color: Colors.textDim; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }
                Text { visible: VpnService.connected && VpnService.protocol !== ""; text: VpnService.protocol; color: Colors.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }

                Text { visible: VpnService.connected && VpnService.exitIp !== ""; text: "Exit IP"; color: Colors.textDim; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }
                Text { visible: VpnService.connected && VpnService.exitIp !== ""; text: VpnService.exitIp; color: Colors.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }

                // Disconnected: show visible location
                Text { visible: !VpnService.connected; text: "Visible as"; color: Colors.textDim; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }
                Text { visible: !VpnService.connected; text: VpnService.locationLabel; color: Colors.textDim; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm; Layout.fillWidth: true; elide: Text.ElideRight }

                Text { visible: !VpnService.connected && VpnService.visibleIp !== ""; text: "Your IP"; color: Colors.textDim; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }
                Text { visible: !VpnService.connected && VpnService.visibleIp !== ""; text: VpnService.visibleIp; color: Colors.textDim; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Geometry.fontSizeSm }
            }
        }
    }
}

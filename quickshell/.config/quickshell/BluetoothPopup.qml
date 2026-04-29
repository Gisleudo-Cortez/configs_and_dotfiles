import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth

PanelWindow {
    id: root

    WlrLayershell.namespace: "quickshell:bluetooth"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { top: true; right: true }
    exclusiveZone: -1
    margins.top: Geometry.barHeight + Geometry.outerGap * 2 + 4
    margins.right: Geometry.outerGap

    implicitWidth: Geometry.popupWidth
    implicitHeight: Math.min(box.implicitHeight, 440)
    color: "transparent"

    // Show on hover OR on click; clicking also triggers scan (handled below)
    visible: (PopupState.active === "bluetooth" && PopupState.screen === screen)
          || (PopupState.hoverActive === "bluetooth" && PopupState.hoverScreen === screen)

    readonly property var adapter: Bluetooth.defaultAdapter

    // Auto-start discovery when opened via click (not hover)
    onVisibleChanged: {
        if (visible && PopupState.active === "bluetooth" && adapter?.enabled)
            adapter.startDiscovery()
        if (!visible && adapter?.scanning)
            adapter.stopDiscovery()
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.bgPopup
        radius: Geometry.islandRadius
        border.color: Colors.border
        border.width: Geometry.borderWidth

        Flickable {
            id: flick
            anchors.fill: parent
            contentHeight: box.implicitHeight
            clip: true

            ColumnLayout {
                id: box
                width: flick.width
                spacing: 0

                // ── Header ────────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: Geometry.innerPad
                    Layout.bottomMargin: 6
                    spacing: 8

                    Text {
                        text: "󰂯  Bluetooth"
                        color: Colors.blue
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: Geometry.fontSize
                        Layout.fillWidth: true
                    }

                    // Scan status / button (only when on and click-opened)
                    Text {
                        visible: (root.adapter?.enabled ?? false) &&
                                 PopupState.active === "bluetooth"
                        text: root.adapter?.scanning ? "󰑪 scanning" : "󰑺 scan"
                        color: root.adapter?.scanning ? Colors.cyan : Colors.textDim
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: Geometry.fontSizeSm
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.adapter?.scanning) root.adapter.stopDiscovery()
                                else root.adapter?.startDiscovery()
                            }
                        }
                    }

                    // On/off toggle
                    Text {
                        text: (root.adapter?.enabled ?? false) ? "on" : "off"
                        color: (root.adapter?.enabled ?? false) ? Colors.blue : Colors.textDim
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: Geometry.fontSizeSm
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Colors.textDim; opacity: 0.25 }

                // ── No adapter ────────────────────────────────────────────
                Text {
                    visible: !root.adapter
                    text: "No Bluetooth adapter"
                    color: Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSizeSm
                    Layout.alignment: Qt.AlignHCenter
                    Layout.margins: Geometry.innerPad
                }

                // ── BT off ────────────────────────────────────────────────
                Text {
                    visible: root.adapter !== null && !(root.adapter?.enabled ?? false)
                    text: "Bluetooth is off"
                    color: Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSizeSm
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Geometry.innerPad
                    Layout.bottomMargin: Geometry.innerPad
                }

                // ── Device list ───────────────────────────────────────────
                Repeater {
                    id: devRepeater
                    model: root.adapter?.devices

                    delegate: ColumnLayout {
                        visible: root.adapter?.enabled ?? false
                        width: box.width
                        spacing: 0

                        Rectangle {
                            Layout.fillWidth: true
                            height: devRow.implicitHeight + 16
                            color: devHover.containsMouse
                                   ? Qt.rgba(0.247, 0.725, 0.976, 0.09) : "transparent"

                            RowLayout {
                                id: devRow
                                anchors {
                                    left: parent.left; right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: Geometry.innerPad; rightMargin: Geometry.innerPad
                                }
                                spacing: 8

                                // Connection state dot
                                Rectangle {
                                    width: 7; height: 7; radius: 4
                                    color: modelData.connected ? Colors.green
                                         : modelData.state === 2 ? Colors.warning  // connecting
                                         : Colors.textDim
                                    opacity: modelData.connected ? 1.0 : 0.5
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: modelData.name || modelData.address
                                        color: modelData.connected ? Colors.text : Colors.textDim
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: Geometry.fontSizeSm
                                        font.bold: modelData.connected
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    // Battery line (when available)
                                    RowLayout {
                                        visible: modelData.batteryAvailable
                                        spacing: 3
                                        Text {
                                            text: "󰁹"
                                            color: Colors.textDim
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: Geometry.fontSizeSm - 1
                                        }
                                        Text {
                                            text: modelData.battery + "%"
                                            color: Colors.textDim
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: Geometry.fontSizeSm - 1
                                        }
                                    }
                                }

                                // Action button
                                Text {
                                    text: modelData.connected   ? "disconnect"
                                        : modelData.paired      ? "connect"
                                        : "pair"
                                    color: modelData.connected ? Colors.alert : Colors.cyan
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: Geometry.fontSizeSm
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.connected)    modelData.disconnect()
                                            else if (modelData.paired)  modelData.connect()
                                            else                         modelData.pair()
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: devHover
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }
                        }

                        Rectangle {
                            visible: parent.visible && index < devRepeater.count - 1
                            Layout.fillWidth: true; height: 1
                            color: Colors.textDim; opacity: 0.1
                        }
                    }
                }

                // ── Empty state ───────────────────────────────────────────
                Text {
                    visible: (root.adapter?.enabled ?? false) &&
                             (root.adapter?.devices?.count ?? 0) === 0
                    text: root.adapter?.scanning ? "Scanning for devices…" : "No known devices"
                    color: Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSizeSm
                    Layout.alignment: Qt.AlignHCenter
                    Layout.margins: Geometry.innerPad
                }

                Item { height: Geometry.innerPad }
            }
        }
    }
}

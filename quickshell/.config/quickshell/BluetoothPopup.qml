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
    // Use click anchor if set, otherwise hover anchor, otherwise edge
    margins.right: {
        var ax = PopupState.popupAnchorX >= 0 ? PopupState.popupAnchorX
                : PopupState.hoverAnchorX >= 0 ? PopupState.hoverAnchorX
                : -1
        if (ax < 0) return Geometry.outerGap
        return Math.max(Geometry.outerGap,
            Math.min(_screen.width - Geometry.outerGap - implicitWidth,
                _screen.width - ax - implicitWidth / 2))
    }

    implicitWidth: Geometry.popupWidth
    implicitHeight: Math.min(box.implicitHeight, 440)
    color: "transparent"

    // Stable screen copy — avoids binding loop from PanelWindow.screen reacting to visible
    readonly property var _screen: screen
    visible: (PopupState.active === "bluetooth" && PopupState.screen === _screen)
          || (PopupState.hoverActive === "bluetooth" && PopupState.hoverScreen === _screen)

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool _scanning: adapter?.scanning ?? false

    // Start scan when the popup opens (click or hover); stop when it closes.
    // onVisibleChanged triggers a compile error — use a Connections on PopupState instead.
    // Debounced: toggleAt/showHoverAt set several PopupState props in one tick, which
    // would otherwise fire duplicate startDiscovery() DBus calls before `scanning`
    // flips to true on the reply.
    Timer {
        id: discoverySync
        interval: 50
        onTriggered: root._syncDiscovery()
    }

    Connections {
        target: PopupState
        function onActiveChanged() { discoverySync.restart() }
        function onHoverActiveChanged() { discoverySync.restart() }
        function onScreenChanged() { discoverySync.restart() }
        function onHoverScreenChanged() { discoverySync.restart() }
    }

    function _syncDiscovery() {
        const open = (PopupState.active === "bluetooth" && PopupState.screen === root._screen)
                  || (PopupState.hoverActive === "bluetooth" && PopupState.hoverScreen === root._screen)
        if (root.adapter && root.adapter.enabled) {
            if (open && !root.adapter.scanning) root.adapter.startDiscovery()
            else if (!open && root.adapter.scanning) root.adapter.stopDiscovery()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.bgPopup
        radius: Geometry.islandRadius
        border.color: Colors.border
        border.width: Geometry.borderWidth

        // Fade-out animation on close
        Behavior on opacity { NumberAnimation { duration: 150 } }

        // Miku cyan signature accent
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 2
            color: Colors.cyan
            radius: 2
        }

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
                    spacing: Geometry.popupSpacing

                    Text {
                        text: "󰂯  Bluetooth"
                        color: Colors.blue
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: Geometry.fontSize
                        Layout.fillWidth: true
                    }

                    // Scan button — visible whenever the popup is open (click or hover)
                    Text {
                        visible: root.adapter !== null
                              && root.adapter.enabled
                        text: (root.adapter !== null && root.adapter.scanning) ? "󰑪 scanning" : "󰑺 scan"
                        color: (root.adapter !== null && root.adapter.scanning) ? Colors.cyan : Colors.textDim
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: Geometry.fontSizeSm
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.adapter === null) return
                                if (root.adapter.scanning) root.adapter.stopDiscovery()
                                else root.adapter.startDiscovery()
                            }
                        }
                    }

                    // On/off toggle
                    Text {
                        visible: root.adapter !== null
                        text: (root.adapter !== null && root.adapter.enabled) ? "on" : "off"
                        color: (root.adapter !== null && root.adapter.enabled) ? Colors.blue : Colors.textDim
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: Geometry.fontSizeSm
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.adapter !== null)
                                    root.adapter.enabled = !root.adapter.enabled
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Colors.textDim; opacity: 0.25 }

                // ── No adapter ────────────────────────────────────────────
                Text {
                    visible: root.adapter === null
                    text: "No Bluetooth adapter"
                    color: Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSizeSm
                    Layout.alignment: Qt.AlignHCenter
                    Layout.margins: Geometry.innerPad
                }

                // ── BT off ────────────────────────────────────────────────
                Text {
                    visible: root.adapter !== null && !root.adapter.enabled
                    text: "Bluetooth is off"
                    color: Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSizeSm
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Geometry.innerPad
                    Layout.bottomMargin: Geometry.innerPad
                }

                // ── Device list ───────────────────────────────────────────
                // Paired/known devices always show; unpaired entries (ambient scan junk
                // and new devices in pairing mode) only surface while a scan is running.
                Repeater {
                    id: devRepeater
                    model: (root.adapter !== null && root.adapter.enabled)
                           ? root.adapter.devices : null

                    delegate: ColumnLayout {
                        width: box.width
                        spacing: 0
                        visible: modelData.paired || modelData.connected || root._scanning

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
                                spacing: Geometry.popupSpacing

                                Rectangle {
                                    width: 7; height: 7; radius: 4
                                    color: modelData.connected ? Colors.green : Colors.textDim
                                    opacity: modelData.connected ? 1.0 : 0.4
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

                                    RowLayout {
                                        visible: modelData.batteryAvailable
                                        spacing: 3
                                        Text {
                                            text: "󰁹 " + modelData.battery + "%"
                                            color: Colors.textDim
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: Geometry.fontSizeSm - 1
                                        }
                                    }
                                }

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
                                            if (modelData.connected)   modelData.disconnect()
                                            else if (modelData.paired) modelData.connect()
                                            else                        modelData.pair()
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
                            visible: index < devRepeater.count - 1
                            Layout.fillWidth: true; height: 1
                            color: Colors.textDim; opacity: 0.1
                        }
                    }
                }

                // Empty state when BT on but no devices
                Text {
                    visible: root.adapter !== null
                          && root.adapter.enabled
                          && root.adapter.devices.count === 0
                    text: (root.adapter !== null && root.adapter.scanning)
                          ? "Scanning for devices…" : "No known devices"
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

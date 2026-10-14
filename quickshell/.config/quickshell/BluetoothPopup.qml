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

    // ── Pair/connect action feedback ─────────────────────────────
    // The C++ layer only logs DBus errors (qCWarning) — QML never sees
    // them. Outcomes are inferred from property transitions instead:
    // pairing true→false while still unpaired = failed; state
    // Connecting→Disconnected while not connected = failed.
    property string actionFeedback: ""
    property bool actionFailed: false
    property bool cancelExpected: false
    Timer { id: feedbackClear; interval: 4000; onTriggered: root.actionFeedback = "" }
    function setFeedback(msg, failed) {
        actionFeedback = msg
        actionFailed = failed
        feedbackClear.restart()
    }

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

                // Action outcome line (pair/connect success/failure)
                Text {
                    visible: root.actionFeedback !== ""
                    text: root.actionFeedback
                    color: root.actionFailed ? Colors.alert : Colors.cyan
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSizeSm
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    Layout.margins: Geometry.innerPad
                    Layout.topMargin: 6
                    Layout.bottomMargin: 2
                }

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
                        // Unpaired rows surface while scanning; keep rows for
                        // in-flight pair/connect attempts visible too — stopping
                        // discovery on pair-click would otherwise hide the row.
                        visible: modelData.paired || modelData.connected || root._scanning
                              || modelData.pairing
                              || modelData.state === BluetoothDeviceState.Connecting

                        readonly property bool pairingNow: modelData.pairing
                        readonly property bool connectingNow: modelData.state === BluetoothDeviceState.Connecting
                        readonly property string devName: modelData.name || modelData.deviceName || modelData.address
                        property string recheckKind: ""

                        onPairingNowChanged: {
                            if (!pairingNow) {
                                if (modelData.paired) root.setFeedback("󰗡  paired: " + devName, false)
                                else if (root.cancelExpected) {
                                    root.cancelExpected = false
                                    root.setFeedback("pairing canceled", false)
                                } else recheckKind = "pair"
                            }
                        }
                        onConnectingNowChanged: {
                            if (!connectingNow) {
                                if (modelData.connected) root.setFeedback("connected: " + devName, false)
                                else recheckKind = "connect"
                            }
                        }
                        // Re-check outcome after property updates settle — guards
                        // against the reply-arrives-before-DBus-property race.
                        onRecheckKindChanged: if (recheckKind !== "") outcomeRecheck.restart()

                        Timer {
                            id: outcomeRecheck
                            interval: 600
                            onTriggered: {
                                if (recheckKind === "pair" && !modelData.paired)
                                    root.setFeedback("󰝥  pair failed: " + devName, true)
                                else if (recheckKind === "connect" && !modelData.connected)
                                    root.setFeedback("󰝥  connect failed: " + devName, true)
                                recheckKind = ""
                            }
                        }

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
                                        text: modelData.name || modelData.deviceName || modelData.address
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
                                    text: modelData.connected ? "disconnect"
                                        : modelData.pairing   ? "cancel"
                                        : connectingNow       ? "connecting…"
                                        : modelData.paired    ? "connect"
                                        :                       "pair"
                                    color: modelData.connected ? Colors.alert : Colors.cyan
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: Geometry.fontSizeSm
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.connected) {
                                                modelData.disconnect()
                                            } else if (modelData.pairing) {
                                                root.cancelExpected = true
                                                modelData.cancelPair()
                                            } else if (connectingNow) {
                                                // connect in flight — no cancel API
                                            } else if (modelData.paired) {
                                                modelData.connect()
                                            } else {
                                                // Stop inquiry before pairing — many
                                                // peripherals reject pairing while being
                                                // scanned for (blueman/GNOME do the same).
                                                // Row stays visible via the `pairing` flag.
                                                if (root.adapter !== null && root.adapter.scanning)
                                                    root.adapter.stopDiscovery()
                                                root.setFeedback("pairing " + devName + "…", false)
                                                modelData.pair()
                                            }
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
                          && root.adapter.devices.values.length === 0
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

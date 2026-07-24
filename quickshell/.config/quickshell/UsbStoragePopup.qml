import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// USB storage popup — external storage devices with mount/unmount + disk usage.
PanelWindow {
    id: root
    readonly property var _screen: screen

    WlrLayershell.namespace: "quickshell:usbstorage"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { top: true; right: true }
    exclusiveZone: -1
    margins.top: Geometry.barHeight + Geometry.outerGap * 2 + 4
    margins.right: PopupState.popupAnchorX >= 0
        ? Math.max(Geometry.outerGap,
              Math.min(_screen.width - Geometry.outerGap - implicitWidth,
                  _screen.width - PopupState.popupAnchorX - implicitWidth / 2))
        : Geometry.outerGap

    implicitWidth: Geometry.popupWidth
    implicitHeight: Math.min(box.implicitHeight, 440)
    color: "transparent"

    visible: PopupState.active === "usbstorage" && PopupState.screen === _screen

    Rectangle {
        anchors.fill: parent
        color: Colors.bgPopup
        radius: Geometry.islandRadius
        border.color: Colors.border
        border.width: Geometry.borderWidth

        Behavior on opacity { NumberAnimation { duration: 150 } }

        // Miku green accent — storage = mounted/active signal
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 2
            color: Colors.green
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

                // ── Header ────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: Geometry.innerPad
                    Layout.bottomMargin: 6
                    spacing: Geometry.popupSpacing

                    Text {
                        // nf-md-usb_flash_drive + label
                        text: "\uF0A5B  USB Storage"
                        color: Colors.green
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: Geometry.fontSize
                        Layout.fillWidth: true
                    }

                    Text {
                        text: UsbService.mountedCount + "/" + UsbService.storageDeviceCount + " mounted"
                        color: Colors.textDim
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: Geometry.fontSizeSm
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Colors.textDim; opacity: 0.25 }

                // ── Empty state ───────────────────────────────────────
                Text {
                    visible: UsbService.storageDevices.length === 0
                    text: "No USB storage devices"
                    color: Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSizeSm
                    Layout.alignment: Qt.AlignHCenter
                    Layout.margins: Geometry.innerPad
                }

                // ── Storage device list ───────────────────────────────
                Repeater {
                    id: stgRepeater
                    model: UsbService.storageDevices

                    delegate: ColumnLayout {
                        width: box.width
                        spacing: 0

                        Rectangle {
                            Layout.fillWidth: true
                            height: stgContent.implicitHeight + 14
                            color: stgHover.containsMouse
                                   ? Qt.rgba(0.0, 0.784, 0.667, 0.07) : "transparent"

                            ColumnLayout {
                                id: stgContent
                                anchors {
                                    left: parent.left; right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: Geometry.innerPad; rightMargin: Geometry.innerPad
                                }
                                spacing: 2

                                // ── Row 1: label + block device ──────────
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    // Mount status dot
                                    Rectangle {
                                        width: 7; height: 7; radius: 4
                                        color: modelData.mounted ? Colors.green : Colors.textDim
                                        opacity: modelData.mounted ? 1.0 : 0.4
                                    }

                                    Text {
                                        // Prefer filesystem label, then product
                                        text: {
                                            if (modelData.label)
                                                return modelData.label
                                            return modelData.product || modelData.manufacturer || "Unknown"
                                        }
                                        color: Colors.text
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: Geometry.fontSizeSm
                                        font.bold: true
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: "/dev/" + modelData.blockDev
                                        color: Colors.textDim
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: Geometry.fontSizeSm - 1
                                    }
                                }

                                // ── Row 2: manufacturer + size ───────────
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        text: modelData.manufacturer || ""
                                        color: Colors.textDim
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: Geometry.fontSizeSm - 1
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        visible: modelData.manufacturer !== ""
                                    }

                                    Text {
                                        text: modelData.size
                                        color: Colors.textDim
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: Geometry.fontSizeSm - 1
                                    }
                                }

                                // ── Row 3: mount info (mounted) ──────────
                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: modelData.mounted
                                    spacing: 6

                                    Text {
                                        // nf-md-folder + mountpoint
                                        text: "\uF02AB " + modelData.mountpoint
                                        color: Colors.green
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: Geometry.fontSizeSm - 1
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: modelData.used + "/" + modelData.total
                                        color: Colors.textDim
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: Geometry.fontSizeSm - 1
                                    }

                                    Text {
                                        text: modelData.pct
                                        color: {
                                            var p = parseInt(modelData.pct)
                                            if (isNaN(p)) return Colors.textDim
                                            if (p >= 90) return Colors.alert
                                            if (p >= 75) return Colors.warning
                                            return Colors.green
                                        }
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: Geometry.fontSizeSm - 1
                                    }
                                }

                                // ── Row 3b: unmounted status ─────────────
                                Text {
                                    visible: !modelData.mounted
                                    text: "unmounted"
                                    color: Colors.textDim
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: Geometry.fontSizeSm - 1
                                }

                                // ── Row 4: disk usage bar ────────────────
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: Geometry.innerPad + 2
                                    Layout.rightMargin: Geometry.innerPad + 2
                                    visible: modelData.mounted
                                    height: 3
                                    radius: 1
                                    color: Qt.rgba(0.5, 0.5, 0.5, 0.2)

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: parent.height
                                        radius: parent.radius
                                        width: {
                                            var p = parseInt(modelData.pct)
                                            if (isNaN(p)) return 0
                                            return parent.width * Math.min(p, 100) / 100
                                        }
                                        color: {
                                            var p = parseInt(modelData.pct)
                                            if (isNaN(p)) return Colors.textDim
                                            if (p >= 90) return Colors.alert
                                            if (p >= 75) return Colors.warning
                                            return Colors.green
                                        }
                                    }
                                }

                                // ── Row 5: mount/unmount button ──────────
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: modelData.mounted ? "\uF0A60 unmount" : "\uF02AB mount"
                                        color: modelData.mounted ? Colors.alert : Colors.cyan
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: Geometry.fontSizeSm - 1

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData.mounted)
                                                    UsbService.unmountDevice(modelData.blockDev)
                                                else
                                                    UsbService.mountDevice(modelData.blockDev)
                                            }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: stgHover
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }
                        }

                        Rectangle {
                            visible: index < stgRepeater.count - 1
                            Layout.fillWidth: true; height: 1
                            color: Colors.textDim; opacity: 0.1
                        }
                    }
                }

                Item { height: Geometry.innerPad }
            }
        }
    }
}
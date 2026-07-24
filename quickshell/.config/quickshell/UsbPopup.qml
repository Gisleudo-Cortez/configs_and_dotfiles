import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// USB bus popup — non-storage devices (input, audio, video, network, etc).
// Shows type icon, name, manufacturer, speed, power, VID:PID per device.
PanelWindow {
    id: root
    readonly property var _screen: screen

    WlrLayershell.namespace: "quickshell:usb"
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
    implicitHeight: Math.min(box.implicitHeight, 520)
    color: "transparent"

    visible: PopupState.active === "usb" && PopupState.screen === _screen

    // ── Helpers ─────────────────────────────────────────────────────
    function _typeIcon(t) {
        switch (t) {
            case "audio":    return "\uF0957"  // nf-md-volume_high
            case "input":    return "\uF0B6D"  // nf-md-keyboard
            case "video":    return "\uF0AA0"  // nf-md-webcam
            case "image":    return "\uF0934"  // nf-md-camera
            case "printer":  return "\uF0D2C"  // nf-md-printer
            case "network":  return "\uF0A1F"  // nf-md-ethernet
            case "wireless": return "\uF0CC0"  // nf-md-router_wireless
            default:         return "\uF06CF"  // nf-md-usb
        }
    }

    function _typeLabel(t) {
        switch (t) {
            case "audio":    return "audio"
            case "input":    return "input"
            case "video":    return "video"
            case "image":    return "image"
            case "printer":  return "printer"
            case "network":  return "network"
            case "wireless": return "wireless"
            default:         return "device"
        }
    }

    function _fmtSpeed(s) {
        var n = parseInt(s)
        if (isNaN(n) || n === 0) return "?"
        if (n >= 1000) return (n / 1000).toFixed(0) + "G"
        return n + "M"
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.bgPopup
        radius: Geometry.islandRadius
        border.color: Colors.border
        border.width: Geometry.borderWidth

        Behavior on opacity { NumberAnimation { duration: 150 } }

        // Miku cyan accent — bus devices
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

                // ── Header ────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: Geometry.innerPad
                    Layout.bottomMargin: 6
                    spacing: Geometry.popupSpacing

                    Text {
                        text: "\uF287  USB"
                        color: Colors.cyan
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: Geometry.fontSize
                        Layout.fillWidth: true
                    }

                    Text {
                        text: UsbService.otherDeviceCount + " devices"
                        color: Colors.textDim
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: Geometry.fontSizeSm
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Colors.textDim; opacity: 0.25 }

                // ── Empty state ───────────────────────────────────────
                Text {
                    visible: UsbService.otherDevices.length === 0
                    text: "No USB devices"
                    color: Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSizeSm
                    Layout.alignment: Qt.AlignHCenter
                    Layout.margins: Geometry.innerPad
                }

                // ── Device list ───────────────────────────────────────
                Repeater {
                    id: devRepeater
                    model: UsbService.otherDevices

                    delegate: ColumnLayout {
                        width: box.width
                        spacing: 0

                        Rectangle {
                            Layout.fillWidth: true
                            height: devContent.implicitHeight + 14
                            color: devHover.containsMouse
                                   ? Qt.rgba(0.0, 0.784, 0.667, 0.07) : "transparent"

                            ColumnLayout {
                                id: devContent
                                anchors {
                                    left: parent.left; right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: Geometry.innerPad; rightMargin: Geometry.innerPad
                                }
                                spacing: 2

                                // ── Row 1: icon + name + type ────────────
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        text: root._typeIcon(modelData.type)
                                        color: Colors.textDim
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: Geometry.fontSizeSm
                                    }

                                    Text {
                                        text: modelData.product || modelData.manufacturer || "Unknown"
                                        color: Colors.text
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: Geometry.fontSizeSm
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: root._typeLabel(modelData.type)
                                        color: Colors.textDim
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: Geometry.fontSizeSm - 1
                                    }
                                }

                                // ── Row 2: manufacturer + speed/power/VID:PID
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
                                        text: root._fmtSpeed(modelData.speed) + "  .  "
                                              + modelData.power + "  .  "
                                              + modelData.vid + ":" + modelData.pid
                                        color: Colors.textDim
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: Geometry.fontSizeSm - 1
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

                Item { height: Geometry.innerPad }
            }
        }
    }
}
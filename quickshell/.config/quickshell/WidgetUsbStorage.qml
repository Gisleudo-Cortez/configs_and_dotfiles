import QtQuick

// USB storage indicator — shows external storage device count.
// Click opens storage popup with mount/unmount. Hover shows tooltip.
// Only visible when USB storage devices are present.
Item {
    id: root
    visible: UsbService.hasStorage
    implicitWidth: stgChip.implicitWidth + 4
    implicitHeight: Geometry.barHeight

    property var screen: null
    signal clicked

    // nf-md-usb_flash_drive = U+F129E (supplementary plane, needs fromCodePoint)
    readonly property string flashDriveIcon: String.fromCodePoint(0xF129E)

    function _globalX(): real {
        var p = root
        var x = 0
        while (p) {
            x += p.x
            p = p.parent
        }
        return x
    }

    StatChip {
        id: stgChip
        anchors.centerIn: parent
        screen: root.screen
        icon: root.flashDriveIcon
        value: UsbService.storageDeviceCount > 0 ? UsbService.storageDeviceCount + "" : ""
        color: UsbService.mountedCount > 0 ? Colors.green
              : UsbService.hasStorage ? Colors.cyan
              : Colors.textDim
        tooltip: UsbService.storageTooltipText
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            PopupState.toggleAt("usbstorage", root.screen, root._globalX() + root.width / 2)
        }
    }
}
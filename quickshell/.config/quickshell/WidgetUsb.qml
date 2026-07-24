import QtQuick

// USB device count indicator — click opens popup, hover shows tooltip
Item {
    id: root
    visible: true
    implicitWidth: usbChip.implicitWidth + 4
    implicitHeight: Geometry.barHeight

    property var screen: null
    signal clicked

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
        id: usbChip
        anchors.centerIn: parent
        screen: root.screen
        // nf-fa-usb = U+F287 (Font Awesome USB trident)
        icon: "\uF287"
        value: UsbService.deviceCount > 0 ? UsbService.deviceCount + "" : ""
        color: UsbService.hasDevices ? Colors.cyan : Colors.textDim
        tooltip: UsbService.tooltipText
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            PopupState.toggleAt("usb", root.screen, root._globalX() + root.width / 2)
        }
    }
}
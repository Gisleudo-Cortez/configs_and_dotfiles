import QtQuick
// Clipboard history indicator
Item {
    id: root
    implicitWidth: clipText.implicitWidth + 4
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

    Text {
        id: clipText
        anchors.centerIn: parent
        text: "󰅎"
        color: Colors.textDim
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: Geometry.iconFontSize
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered) TooltipService.show("Clipboard history", root.screen, root._globalX() + root.width / 2)
            else         TooltipService.hide()
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            ClipService.refresh()
            PopupState.toggleAt("clip", root.screen, root._globalX() + root.width / 2)
        }
    }
}

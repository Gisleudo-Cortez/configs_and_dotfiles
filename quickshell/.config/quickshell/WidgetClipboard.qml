import QtQuick
// Clipboard history indicator
Item {
    id: root
    implicitWidth: clipText.implicitWidth + 4
    implicitHeight: Geometry.barHeight

    property var screen: null
    signal clicked

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
            if (hovered) TooltipService.show("Clipboard history", root.screen)
            else         TooltipService.hide()
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

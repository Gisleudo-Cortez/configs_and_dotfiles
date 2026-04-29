import QtQuick
import QtQuick.Layouts

RowLayout {
    property string icon:    ""
    property string value:   ""
    property color  color:   Colors.text
    property string tooltip: ""
    property var    screen:  null   // pass root.screen from IslandRight
    spacing: 3

    Text {
        text: icon
        color: parent.color
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: Geometry.fontSize
        visible: icon !== ""
    }
    Text {
        text: value
        color: parent.color
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: Geometry.fontSizeSm
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered && tooltip !== "")
                TooltipService.show(tooltip, screen)
            else
                TooltipService.hide()
        }
    }
}

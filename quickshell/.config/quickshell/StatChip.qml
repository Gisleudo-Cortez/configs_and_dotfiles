import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    property string icon:    ""
    property string value:   ""
    property color  color:   Colors.text
    property string tooltip: ""
    property var    screen:  null   // pass root.screen from IslandRight
    spacing: 3

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
        text: icon
        color: parent.color
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: Geometry.iconFontSize
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
                TooltipService.showAt(tooltip, screen, root._globalX() + root.width / 2)
            else
                TooltipService.hide()
        }
    }
}

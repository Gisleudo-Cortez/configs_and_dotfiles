import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

RowLayout {
    property string icon: ""
    property string value: ""
    property color color: Colors.text
    property string tooltip: ""
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

    HoverHandler { id: chipHover }

    ToolTip.visible: chipHover.hovered && tooltip !== ""
    ToolTip.text: tooltip
    ToolTip.delay: 700
}

import QtQuick
// Widget notification bell — amber when unread, teal-grey when empty
Item {
    id: root
    implicitWidth: bellText.implicitWidth + 4
    implicitHeight: Geometry.barHeight

    property var screen: null
    signal clicked

    Text {
        id: bellText
        anchors.centerIn: parent
        text: NotifService.unreadCount > 0 ? "󱅫" : "󰂚"
        color: NotifService.unreadCount > 0 ? Colors.alert : Colors.textDim
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: Geometry.iconFontSize
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered)
                TooltipService.show(
                    NotifService.unreadCount > 0
                    ? NotifService.unreadCount + " unread notification" +
                      (NotifService.unreadCount > 1 ? "s" : "")
                    : "No notifications",
                    root.screen)
            else
                TooltipService.hide()
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

import QtQuick

Item {
    id: root

    // "shutdown" | "reboot" | "suspend"
    property string action: "shutdown"
    property color  glyphColor:  "#e0e0f0"
    property color  hoverColor:  "#03edf9"
    property real   baseOpacity: 0.4

    width: 36
    height: 36

    readonly property string glyph: {
        if (action === "reboot")  return "↻"   // ↻
        if (action === "suspend") return "⏾"   // ⏾
        return "⏻"                             // ⏻  shutdown
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(root.hoverColor, ma.containsMouse ? 0.55 : 0.0)
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        font.pixelSize: 18
        color: ma.containsMouse ? root.hoverColor : root.glyphColor
        opacity: ma.containsMouse ? 1.0 : root.baseOpacity
        Behavior on color   { ColorAnimation  { duration: 150 } }
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if      (root.action === "reboot")  sddm.reboot()
            else if (root.action === "suspend") sddm.suspend()
            else                                sddm.powerOff()
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Island {
    id: root
    implicitWidth: row.implicitWidth + Geometry.innerPad * 2

    RowLayout {
        id: row
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        anchors.leftMargin: Geometry.innerPad
        anchors.rightMargin: Geometry.innerPad
        spacing: 4

        // Workspace chips
        Repeater {
            model: Hyprland.workspaces
            delegate: Rectangle {
                readonly property bool active: modelData.focused
                implicitWidth: wsLabel.implicitWidth + 10
                implicitHeight: 18
                radius: 4
                color: active ? Colors.purple : "transparent"
                border.color: active ? "transparent" : Colors.textDim
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    id: wsLabel
                    anchors.centerIn: parent
                    text: modelData.id
                    color: active ? Colors.bg : Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSizeSm
                    font.bold: active
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.activate()
                }
            }
        }

        // Separator
        Rectangle {
            width: 1; height: 16
            color: Colors.textDim
            opacity: 0.4
        }

        // Window title
        Text {
            id: titleText
            text: Hyprland.activeToplevel?.title ?? ""
            color: Colors.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Geometry.fontSize
            elide: Text.ElideRight
            Layout.maximumWidth: 240
        }
    }

    HudCorners { anchors.fill: parent }
}

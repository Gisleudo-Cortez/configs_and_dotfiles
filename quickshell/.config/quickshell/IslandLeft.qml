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

        // Workspace dots
        Repeater {
            model: Hyprland.workspaces.values
            delegate: Rectangle {
                readonly property bool active: modelData.id === Hyprland.focusedWorkspace?.id
                width: active ? 18 : 8
                height: 8
                radius: 4
                color: active ? Colors.purple : Colors.textDim
                Behavior on width { NumberAnimation { duration: 150 } }
                Behavior on color { ColorAnimation { duration: 150 } }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Hyprland.dispatch("workspace " + modelData.id)
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
            text: Hyprland.focusedClient?.title ?? ""
            color: Colors.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Geometry.fontSize
            elide: Text.ElideRight
            Layout.maximumWidth: 240
        }
    }

    HudCorners { anchors.fill: parent }
}

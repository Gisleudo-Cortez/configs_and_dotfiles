import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    required property var screen
    WlrLayershell.namespace: "quickshell:bar"
    WlrLayershell.layer: WlrLayer.Top

    anchors { top: true; left: true; right: true }
    height: Geometry.barHeight + Geometry.outerGap * 2
    color: "transparent"
    exclusiveZone: height

    Item {
        anchors.fill: parent

        RowLayout {
            anchors {
                top: parent.top; left: parent.left; right: parent.right
                margins: Geometry.outerGap
            }
            height: Geometry.barHeight
            spacing: 0

            IslandLeft {
                Layout.fillHeight: true
                Layout.preferredWidth: implicitWidth
            }

            Item { Layout.fillWidth: true }

            IslandCenter {
                Layout.fillHeight: true
                Layout.preferredWidth: implicitWidth
                onClockClicked: PopupState.toggle("calendar", root.screen)
            }

            Item { Layout.fillWidth: true }

            IslandRight {
                Layout.fillHeight: true
                Layout.fillWidth: true
                onNotifClicked: PopupState.toggle("notif", root.screen)
                onClipClicked:  { ClipService.refresh(); PopupState.toggle("clip", root.screen) }
            }
        }
    }
}

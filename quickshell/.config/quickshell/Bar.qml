import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    WlrLayershell.namespace: "quickshell:bar"
    WlrLayershell.layer: WlrLayer.Top

    anchors { top: true; left: true; right: true }
    implicitHeight: Geometry.barHeight + Geometry.outerGap * 2
    color: "transparent"
    exclusiveZone: Geometry.barHeight + Geometry.outerGap * 2

    Item {
        anchors.fill: parent

        // Miku signal trace — teal line across bar top, dim edges, bright center
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.2; color: Colors.hudGlow }
                GradientStop { position: 0.5; color: Colors.cyan }
                GradientStop { position: 0.8; color: Colors.hudGlow }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

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
                id: rightIsland
                Layout.fillHeight: true
                Layout.fillWidth: true
                screen: root.screen

                onNotifClicked:  PopupState.toggle("notif",     root.screen)
                onClipClicked:   { ClipService.refresh(); PopupState.toggle("clip", root.screen) }
                onMediaClicked:  PopupState.toggle("media",     root.screen)
                onAudioClicked:  PopupState.toggle("audio",     root.screen)
                onDockerClicked: PopupState.toggle("docker",    root.screen)
                onBtClicked:     PopupState.toggle("bluetooth", root.screen)
            }
        }
    }
}

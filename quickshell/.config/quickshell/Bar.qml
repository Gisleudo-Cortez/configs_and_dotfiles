import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris

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

        // Miku signal trace — breathing teal line, dim edges, bright center
        // Pulse is event-driven: breathes only while media plays (WidgetMedia
        // pattern). No infinite timer — an idle desktop costs zero frames.
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 1

            property real _pulse: 0.75
            opacity: _pulse

            // Any active player breathing = bright line; paused/none = dim rest
            readonly property bool _mediaActive: {
                if (!Mpris.players || Mpris.players.count === 0) return false
                const players = Mpris.players.values
                for (let i = 0; i < players.length; i++) {
                    if (players[i].isPlaying) return true
                }
                return false
            }

            NumberAnimation on _pulse {
                from: 0.6; to: 0.85
                duration: 6000
                running: parent._mediaActive
                easing.type: Easing.InOutSine
            }

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
                screen: root.screen
            }

            Item { Layout.fillWidth: true }

            IslandCenter {
                id: centerIsland
                Layout.fillHeight: true
                Layout.preferredWidth: implicitWidth
                onClockClicked: PopupState.toggleAt("calendar", root.screen, centerIsland._globalX() + centerIsland.width / 2)
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
                // ── ronema launcher — one-shot on network click ──
            onNetClicked: {
                const p = new Process()
                p.command = ["ronema"]
                p.start()
            }
            }
        }
    }
}

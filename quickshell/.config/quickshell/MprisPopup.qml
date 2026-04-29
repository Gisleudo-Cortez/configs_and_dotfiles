import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris

PanelWindow {
    id: root
    required property var screen

    WlrLayershell.namespace: "quickshell:media"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { top: true; right: true }
    exclusiveZone: -1
    margins.top: Geometry.barHeight + Geometry.outerGap * 2 + 4
    margins.right: Geometry.outerGap

    implicitWidth: Geometry.popupWidth
    implicitHeight: box.implicitHeight + Geometry.innerPad * 2
    color: "transparent"

    visible: PopupState.active === "media" && PopupState.screen === screen

    // Prefer the currently playing player; fall back to first.
    readonly property var player: {
        if (!Mpris.players || Mpris.players.count === 0) return null
        const players = Mpris.players.values
        for (let i = 0; i < players.length; i++) {
            if (players[i].isPlaying) return players[i]
        }
        return players[0]
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.bgPopup
        radius: Geometry.islandRadius
        border.color: Colors.border
        border.width: Geometry.borderWidth

        ColumnLayout {
            id: box
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.margins: Geometry.innerPad
            spacing: 8

            // Header
            Text {
                text: "󰝚  Media"
                color: Colors.purple
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: Geometry.fontSize
                Layout.fillWidth: true
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.textDim; opacity: 0.25 }

            // Empty state
            Text {
                visible: root.player === null
                text: "No media player"
                color: Colors.textDim
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: Geometry.fontSize
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                Layout.bottomMargin: 4
            }

            // Track info
            ColumnLayout {
                visible: root.player !== null
                Layout.fillWidth: true
                spacing: 3

                Text {
                    text: root.player?.trackTitle ?? ""
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSize
                    font.bold: true
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    visible: text !== ""
                }
                Text {
                    text: root.player?.trackArtist ?? ""
                    color: Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSizeSm
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    visible: text !== ""
                }
            }

            // Playback controls
            RowLayout {
                visible: root.player !== null
                Layout.alignment: Qt.AlignHCenter
                spacing: 24

                Text {
                    text: "󰒮"
                    color: Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 20
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.player?.previous()
                    }
                }

                Text {
                    text: root.player?.isPlaying ? "󰏤" : "󰐊"
                    color: Colors.purple
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 24
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.player?.togglePlaying()
                    }
                }

                Text {
                    text: "󰒭"
                    color: Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 20
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.player?.next()
                    }
                }
            }

            // Player app name
            Text {
                text: root.player?.identity ?? ""
                color: Colors.textDim
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: Geometry.fontSizeSm
                Layout.alignment: Qt.AlignHCenter
                opacity: 0.6
                visible: root.player !== null && text !== ""
            }
        }
    }
}

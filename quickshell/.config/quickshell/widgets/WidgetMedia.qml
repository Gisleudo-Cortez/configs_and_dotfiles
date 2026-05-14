import QtQuick
import Quickshell.Services.Mpris

// MPRIS media indicator — teal with opacity pulse on play state
Item {
    id: root
    visible: Mpris.players.count > 0
    implicitWidth: mediaText.implicitWidth + 4
    implicitHeight: Geometry.barHeight

    property var screen: null
    signal clicked

    readonly property var _activePlayer: {
        if (!Mpris.players || Mpris.players.count === 0) return null
        const players = Mpris.players.values
        for (let i = 0; i < players.length; i++) {
            if (players[i].isPlaying) return players[i]
        }
        return players[0]
    }

    Text {
        id: mediaText
        anchors.centerIn: parent
        text: "󰝚"
        color: Colors.cyan
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: Geometry.iconFontSize
        opacity: root._activePlayer?.isPlaying ? 1.0 : 0.4

        Behavior on opacity {
            NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
        }
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered && root._activePlayer !== null) {
                const p = root._activePlayer
                const artist = p.trackArtist || ""
                const title  = p.trackTitle  || "Unknown"
                TooltipService.show(
                    (artist ? artist + " — " : "") + title,
                    root.screen)
            } else {
                TooltipService.hide()
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

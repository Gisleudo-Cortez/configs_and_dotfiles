import QtQuick
import QtQuick.Layouts

// Audio volume icon + sink name + percentage, scroll adjustable
Item {
    id: root
    implicitWidth: audioRow.implicitWidth + 4
    implicitHeight: Geometry.barHeight

    property var screen: null
    signal clicked

    RowLayout {
        id: audioRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: AudioService.volIcon()
            color: AudioService.muted ? Colors.textDim : Colors.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Geometry.iconFontSize
        }

        Text {
            text: AudioService.sinkShortName
            color: Colors.textDim
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Geometry.fontSizeSm
            visible: AudioService.sinkShortName !== ""
        }

        Text {
            text: AudioService.volPct() + "%"
            color: AudioService.muted ? Colors.textDim : Colors.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Geometry.fontSizeSm
        }
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered)
                TooltipService.show(
                    AudioService.sinkName + "  " + AudioService.volPct() + "%" +
                    (AudioService.muted ? " · muted" : "") +
                    "\nscroll ±5%  ·  click to open",
                    root.screen)
            else
                TooltipService.hide()
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onWheel: function(wheel) {
            AudioService.adjustVolume(wheel.angleDelta.y > 0 ? 0.05 : -0.05)
        }
    }
}

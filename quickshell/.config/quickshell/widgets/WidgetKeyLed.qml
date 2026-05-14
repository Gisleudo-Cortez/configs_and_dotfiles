import QtQuick
import QtQuick.Layouts

// Caps Lock + Num Lock indicators
Item {
    id: root
    implicitWidth: keyLedRow.implicitWidth + 4
    implicitHeight: Geometry.barHeight

    property var screen: null

    RowLayout {
        id: keyLedRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "⇪"
            color: KeyLedService.capsLock ? Colors.warning : Colors.textDim
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Geometry.iconFontSize
        }

        Text {
            text: "⇭"
            color: KeyLedService.numLock ? Colors.blue : Colors.textDim
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Geometry.iconFontSize
        }
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered)
                TooltipService.show(
                    "Caps Lock " + (KeyLedService.capsLock ? "ON" : "off") +
                    "  ·  Num Lock " + (KeyLedService.numLock ? "ON" : "off"),
                    root.screen)
            else
                TooltipService.hide()
        }
    }
}

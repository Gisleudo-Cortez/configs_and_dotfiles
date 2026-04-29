import QtQuick
import Quickshell
import Quickshell.Wayland

// Thin tooltip window that appears just below the bar on the correct screen.
// Uses the same top-right anchor + margins.top convention as the other popups.
PanelWindow {
    id: root
    readonly property var _screen: screen

    WlrLayershell.namespace: "quickshell:tooltip"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { top: true; right: true }
    exclusiveZone: -1
    margins.top: Geometry.barHeight + Geometry.outerGap * 2 + 4
    margins.right: Geometry.outerGap

    implicitWidth:  tipText.implicitWidth  + Geometry.innerPad * 2
    implicitHeight: tipText.implicitHeight + 8
    color: "transparent"

    visible: TooltipService.visible
          && TooltipService.text !== ""
          && TooltipService.screen === _screen

    Rectangle {
        anchors.fill: parent
        color: Colors.bgPopup
        radius: Geometry.islandRadius
        border.color: Colors.border
        border.width: Geometry.borderWidth

        Text {
            id: tipText
            anchors.centerIn: parent
            text: TooltipService.text
            color: Colors.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Geometry.fontSizeSm
        }
    }
}

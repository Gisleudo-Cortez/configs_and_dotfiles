import QtQuick
import QtQuick.Effects

// Reusable frosted-glass pill with 1px purple border and subtle glow
Rectangle {
    id: root
    implicitHeight: Geometry.barHeight
    implicitWidth: childrenRect.width + Geometry.innerPad * 2

    radius: Geometry.islandRadius
    color: Colors.bgIsland

    border.color: Colors.border
    border.width: Geometry.borderWidth

    // Faint outer glow — blurred duplicate behind
    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: root.radius + 2
        color: "transparent"
        border.color: Colors.glow
        border.width: 3
        z: -1

        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 0.8
            blurMax: 12
        }
    }
}

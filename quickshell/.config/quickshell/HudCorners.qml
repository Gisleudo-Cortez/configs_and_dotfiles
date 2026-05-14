import QtQuick
import QtQuick.Effects

// Subtle L-shaped corner marks — teal top, purple bottom (Lain gradient)
Item {
    id: root
    anchors.fill: parent

    readonly property int sz: 8   // arm length
    readonly property int th: 1   // arm thickness
    readonly property color cTop: Colors.hudGlow
    readonly property color cBot: Qt.rgba(0.71, 0.0, 1.0, 0.25)

    // Each corner: two perpendicular lines + blurred glow clone
    Repeater {
        model: [
            { x: 0,           y: 0,            hFlip: false, vFlip: false, color: cTop },
            { x: root.width,  y: 0,            hFlip: true,  vFlip: false, color: cTop },
            { x: 0,           y: root.height,  hFlip: false, vFlip: true,  color: cBot },
            { x: root.width,  y: root.height,  hFlip: true,  vFlip: true,  color: cBot }
        ]

        delegate: Item {
            x: modelData.x - (modelData.hFlip ? sz : 0)
            y: modelData.y - (modelData.vFlip ? sz : 0)
            width: sz; height: sz

            // Horizontal arm
            Rectangle {
                x: 0; y: 0
                width: sz; height: th
                color: modelData.color
            }
            // Vertical arm
            Rectangle {
                x: 0; y: 0
                width: th; height: sz
                color: modelData.color
            }

            // Blurred glow behind
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: modelData.color
                border.width: 1
                z: -1
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: 0.7
                    blurMax: 6
                }
            }
        }
    }
}

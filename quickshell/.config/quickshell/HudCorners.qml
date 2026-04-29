import QtQuick
import QtQuick.Effects

// Subtle L-shaped corner marks in cyan, one per corner of the island
Item {
    id: root
    anchors.fill: parent

    readonly property int sz: 8   // arm length
    readonly property int th: 1   // arm thickness
    readonly property color c: Colors.hudGlow

    // Each corner: two perpendicular lines + blurred glow clone
    Repeater {
        model: [
            { x: 0,           y: 0,            hFlip: false, vFlip: false },
            { x: root.width,  y: 0,            hFlip: true,  vFlip: false },
            { x: 0,           y: root.height,  hFlip: false, vFlip: true  },
            { x: root.width,  y: root.height,  hFlip: true,  vFlip: true  }
        ]

        delegate: Item {
            x: modelData.x - (modelData.hFlip ? sz : 0)
            y: modelData.y - (modelData.vFlip ? sz : 0)
            width: sz; height: sz

            // Horizontal arm
            Rectangle {
                x: 0; y: 0
                width: sz; height: th
                color: root.c
            }
            // Vertical arm
            Rectangle {
                x: 0; y: 0
                width: th; height: sz
                color: root.c
            }

            // Blurred glow behind
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: root.c
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

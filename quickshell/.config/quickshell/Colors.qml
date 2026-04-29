pragma Singleton
import QtQuick

QtObject {
    // Backgrounds
    readonly property color bg:          "#091833"
    readonly property color bgIsland:    Qt.rgba(0.035, 0.094, 0.2, 0.88)
    readonly property color bgPopup:     Qt.rgba(0.035, 0.094, 0.2, 0.94)

    // Accents
    readonly property color purple:      "#b589d6"
    readonly property color cyan:        "#03edf9"
    readonly property color blue:        "#65baff"
    readonly property color green:       "#00ff9f"
    readonly property color alert:       "#ff517d"
    readonly property color warning:     "#ffff00"

    // Text
    readonly property color text:        "#d4b8f0"
    readonly property color textDim:     "#7a6a9a"
    readonly property color textActive:  "#ffffff"

    // Border / glow
    readonly property color border:      "#b589d6"
    readonly property color glow:        Qt.rgba(0.71, 0.537, 0.839, 0.4)
    readonly property color hudGlow:     Qt.rgba(0.012, 0.929, 0.976, 0.35)
}

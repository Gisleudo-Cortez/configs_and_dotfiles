pragma Singleton
import QtQuick

QtObject {
    // Backgrounds
    readonly property color bg:          "#091833"
    readonly property color bgIsland:    Qt.rgba(0.035, 0.094, 0.2, 0.88)
    readonly property color bgPopup:     Qt.rgba(0.035, 0.094, 0.2, 0.94)

    // Accents
    readonly property color purple:      "#b589d6"
    readonly property color cyan:        "#00c8aa"
    readonly property color blue:        "#00b4d8"
    readonly property color green:       "#00dca0"
    readonly property color alert:       "#ffb43c"
    readonly property color warning:     "#ff8c1e"

    // Text
    readonly property color text:        "#8cafa5"
    readonly property color textDim:     "#5a7a70"
    readonly property color textActive:  "#00c8aa"

    // Border / glow
    readonly property color border:      "#00c8aa"
    readonly property color glow:        Qt.rgba(0.0, 0.784, 0.667, 0.4)
    readonly property color hudGlow:     Qt.rgba(0.0, 0.706, 0.847, 0.35)
}

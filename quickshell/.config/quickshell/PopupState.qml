pragma Singleton
import QtQuick

QtObject {
    // Click-opened popups
    property string active: ""
    property var screen: null

    // X anchor (screen-global) of the widget that triggered the popup.
    // -1 = no anchor (fall back to edge-aligned positioning).
    property real popupAnchorX: -1

    function toggle(name, scrn) {
        if (active === name && screen === scrn) {
            active = ""; screen = null
            popupAnchorX = -1
        } else {
            active = name; screen = scrn
        }
    }

    function close() { active = ""; screen = null; popupAnchorX = -1 }

    // Toggle with screen-global X position for popup anchoring.
    function toggleAt(name, scrn, globalX) {
        if (active === name && screen === scrn) {
            active = ""; screen = null; popupAnchorX = -1
        } else {
            active = name; screen = scrn; popupAnchorX = globalX
        }
    }

    // Hover-triggered popups (auto-show on hover, auto-hide on mouse leave)
    property string hoverActive: ""
    property var hoverScreen: null
    property real hoverAnchorX: -1

    function showHover(name, scrn) {
        hoverActive = name
        hoverScreen = scrn
    }

    function showHoverAt(name, scrn, globalX) {
        hoverActive = name
        hoverScreen = scrn
        hoverAnchorX = globalX
    }

    function clearHover(name) {
        if (hoverActive === name) {
            hoverActive = ""
            hoverScreen = null
            hoverAnchorX = -1
        }
    }
}

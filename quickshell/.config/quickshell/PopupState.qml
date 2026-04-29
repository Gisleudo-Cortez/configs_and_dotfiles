pragma Singleton
import QtQuick

QtObject {
    // Click-opened popups
    property string active: ""
    property var screen: null

    function toggle(name, scrn) {
        if (active === name && screen === scrn) {
            active = ""; screen = null
        } else {
            active = name; screen = scrn
        }
    }

    function close() { active = ""; screen = null }

    // Hover-triggered popups (auto-show on hover, auto-hide on mouse leave)
    property string hoverActive: ""
    property var hoverScreen: null

    function showHover(name, scrn) {
        hoverActive = name
        hoverScreen = scrn
    }

    function clearHover(name) {
        if (hoverActive === name) {
            hoverActive = ""
            hoverScreen = null
        }
    }
}

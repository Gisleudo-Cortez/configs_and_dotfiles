pragma Singleton
import QtQuick

QtObject {
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
}

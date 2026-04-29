pragma Singleton
import QtQuick

// Coordinates tooltip display across all bar widgets.
// show() starts a 600ms delay (cancelled by hide()). If already visible,
// text/screen update immediately so moving between chips feels instant.
QtObject {
    id: root

    property string text:   ""
    property bool   visible: false
    property var    screen:  null

    property string _pending: ""
    property var    _pScreen: null

    function show(t, scrn) {
        _pending = t
        _pScreen = scrn
        _hideTimer.stop()
        if (visible) {
            // Already visible — update text immediately, no re-delay
            text   = t
            screen = scrn
        } else {
            _showTimer.restart()
        }
    }

    function hide() {
        _showTimer.stop()
        _hideTimer.restart()
    }

    readonly property var _showTimer: Timer {
        interval: 600
        onTriggered: {
            root.text    = root._pending
            root.screen  = root._pScreen
            root.visible = true
        }
    }

    // Small hide delay prevents flicker when moving between chips
    readonly property var _hideTimer: Timer {
        interval: 150
        onTriggered: { root.visible = false; root.screen = null }
    }
}

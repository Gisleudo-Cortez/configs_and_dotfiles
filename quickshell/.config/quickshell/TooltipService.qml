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
    property real   anchorX: -1   // screen-global X for positioning

    property string _pending: ""
    property var    _pScreen: null
    property real   _pAnchorX: -1

    function show(t, scrn) {
        _pending = t
        _pScreen = scrn
        _pAnchorX = -1
        _hideTimer.stop()
        if (visible) {
            text    = t
            screen  = scrn
            anchorX = -1
        } else {
            _showTimer.restart()
        }
    }

    // Overload: show with screen-global X for positioning under the widget
    function showAt(t, scrn, globalX) {
        _pending = t
        _pScreen = scrn
        _pAnchorX = globalX
        _hideTimer.stop()
        if (visible) {
            text    = t
            screen  = scrn
            anchorX = globalX
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
            root.anchorX = root._pAnchorX
            root.visible = true
        }
    }

    // Small hide delay prevents flicker when moving between chips
    readonly property var _hideTimer: Timer {
        interval: 150
        onTriggered: { root.visible = false; root.screen = null; root.anchorX = -1 }
    }
}

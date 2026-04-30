import QtQuick

Row {
    id: powerBar

    property color glyphColor:  "#e0e0f0"
    property color hoverColor:  "#03edf9"
    property real  baseOpacity: 0.4

    spacing: 4

    PowerBtn {
        action: "suspend"
        visible: sddm.canSuspend
        glyphColor:  powerBar.glyphColor
        hoverColor:  powerBar.hoverColor
        baseOpacity: powerBar.baseOpacity
    }
    PowerBtn {
        action: "reboot"
        glyphColor:  powerBar.glyphColor
        hoverColor:  powerBar.hoverColor
        baseOpacity: powerBar.baseOpacity
    }
    PowerBtn {
        action: "shutdown"
        glyphColor:  powerBar.glyphColor
        hoverColor:  powerBar.hoverColor
        baseOpacity: powerBar.baseOpacity
    }
}

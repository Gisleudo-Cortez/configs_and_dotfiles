import QtQuick
import QtQuick.Layouts

Island {
    id: root
    implicitWidth: row.implicitWidth + Geometry.innerPad * 2

    signal clockClicked

    readonly property var _now: Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._tick()
    }

    property string timeText: ""
    property string dateText: ""
    property string _hh: ""
    property string _mm: ""
    property string _ss: ""
    property real _colonBlink: 1.0

    // Colon blink — slow sine-wave fade
    Timer {
        interval: 800
        running: true
        repeat: true
        onTriggered: root._colonBlink = (root._colonBlink > 0.5) ? 0.4 : 1.0
    }

    function _tick() {
        const d = new Date()
        _hh = String(d.getHours()).padStart(2, "0")
        _mm = String(d.getMinutes()).padStart(2, "0")
        _ss = String(d.getSeconds()).padStart(2, "0")

        const days   = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
        const months = ["Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"]
        dateText = `${days[d.getDay()]} ${d.getDate()} ${months[d.getMonth()]}`
    }

    RowLayout {
        id: row
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        anchors.leftMargin: Geometry.innerPad
        anchors.rightMargin: Geometry.innerPad
        spacing: 0

        Text {
            text: root._hh
            color: Colors.cyan
            font.family: "DSEG7 Classic Bold"
            font.pixelSize: 18
        }
        Text {
            text: ":"
            color: Colors.cyan
            font.family: "DSEG7 Classic Bold"
            font.pixelSize: 18
            opacity: root._colonBlink

            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.InOutSine } }
        }
        Text {
            text: root._mm
            color: Colors.cyan
            font.family: "DSEG7 Classic Bold"
            font.pixelSize: 18
        }
        Text {
            text: ":"
            color: Colors.cyan
            font.family: "DSEG7 Classic Bold"
            font.pixelSize: 18
            opacity: root._colonBlink

            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.InOutSine } }
        }
        Text {
            text: root._ss
            color: Colors.cyan
            font.family: "DSEG7 Classic Bold"
            font.pixelSize: 18
        }

        Text {
            id: dateText
            text: root.dateText
            color: Colors.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14

            transform: Scale {
                id: dateScale
                origin.x: dateText.width / 2
                origin.y: dateText.height / 2
            }

            Behavior on text {
                SequentialAnimation {
                    NumberAnimation { target: dateScale; property: "xScale"; to: 0.85; duration: 80; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: dateScale; property: "yScale"; to: 0.85; duration: 80; easing.type: Easing.InOutQuad }
                    PropertyAction {}
                    NumberAnimation { target: dateScale; property: "xScale"; to: 1.0; duration: 120; easing.type: Easing.OutBack }
                    NumberAnimation { target: dateScale; property: "yScale"; to: 1.0; duration: 120; easing.type: Easing.OutBack }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clockClicked()
    }

    HudCorners { anchors.fill: parent }
}

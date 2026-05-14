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

    function _tick() {
        const d = new Date()
        const hh = String(d.getHours()).padStart(2, "0")
        const mm = String(d.getMinutes()).padStart(2, "0")
        const ss = String(d.getSeconds()).padStart(2, "0")
        timeText = `${hh}:${mm}:${ss}`

        const days   = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
        const months = ["Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"]
        dateText = `${days[d.getDay()]} ${d.getDate()} ${months[d.getMonth()]}`
    }

    RowLayout {
        id: row
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        anchors.leftMargin: Geometry.innerPad
        anchors.rightMargin: Geometry.innerPad
        spacing: 8

        Column {
            spacing: 0
            Text {
                text: root.timeText
                color: Colors.cyan
                font.family: "DSEG7 Classic Bold"
                font.pixelSize: 18
            }
            Text {
                text: root.dateText
                color: Colors.textDim
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: Geometry.fontSizeSm
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

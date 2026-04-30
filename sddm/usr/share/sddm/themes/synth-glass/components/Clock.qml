import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: clock

    property color accentColor: "#03edf9"
    property color secondaryAccent: "#72f1b8"
    property string fontFamily: "Noto Sans"
    property int fontSize: 72
    property date currentTime: new Date()

    width: childrenRect.width
    height: childrenRect.height

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock.currentTime = new Date()
    }

    Column {
        anchors.centerIn: parent
        spacing: -8

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: currentTime.toLocaleTimeString(Qt.locale(), "hh")
            font.family: clock.fontFamily
            font.pixelSize: clock.fontSize
            font.weight: Font.Bold
            color: clock.accentColor
            layer.enabled: true
            layer.effect: DropShadow {
                radius: 12
                samples: 25
                color: clock.accentColor
                spread: 0.3
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: currentTime.toLocaleTimeString(Qt.locale(), "mm")
            font.family: clock.fontFamily
            font.pixelSize: clock.fontSize
            font.weight: Font.Light
            color: clock.secondaryAccent
            layer.enabled: true
            layer.effect: DropShadow {
                radius: 8
                samples: 17
                color: clock.secondaryAccent
                spread: 0.2
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    required property var screen

    WlrLayershell.namespace: "quickshell:toast"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { top: true; right: true }
    exclusiveZone: -1
    margins.top: Geometry.barHeight + Geometry.outerGap * 2 + 4
    margins.right: Geometry.outerGap

    implicitWidth: Geometry.popupWidth
    implicitHeight: toast.implicitHeight
    color: "transparent"

    visible: toast.opacity > 0

    Connections {
        target: NotifService
        function onNotificationReceived(notif) {
            toastSummary.text = notif.summary !== "" ? notif.summary : notif.appName
            toastBody.text    = notif.body
            toastApp.text     = notif.appName
            dismissTimer.restart()
        }
    }

    Timer {
        id: dismissTimer
        interval: 5000
        onTriggered: fadeOut.start()
    }

    Connections {
        target: dismissTimer
        function onRunningChanged() { if (dismissTimer.running) fadeIn.start() }
    }

    Item {
        id: toast
        anchors.fill: parent
        implicitHeight: toastBox.implicitHeight + Geometry.innerPad * 2
        opacity: 0

        NumberAnimation on opacity {
            id: fadeIn
            to: 1; duration: 180; easing.type: Easing.OutCubic
        }
        NumberAnimation on opacity {
            id: fadeOut
            to: 0; duration: 300; easing.type: Easing.InCubic
        }

        Rectangle {
            anchors.fill: parent
            color: Colors.bgPopup
            radius: Geometry.islandRadius
            border.color: Colors.purple
            border.width: Geometry.borderWidth

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { fadeOut.start(); dismissTimer.stop() }
            }

            ColumnLayout {
                id: toastBox
                anchors { left: parent.left; right: parent.right; top: parent.top }
                anchors.margins: Geometry.innerPad
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        id: toastApp
                        text: ""
                        color: Colors.purple
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: Geometry.fontSizeSm
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: "󰂚"
                        color: Colors.textDim
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: Geometry.fontSizeSm
                    }
                }

                Text {
                    id: toastSummary
                    text: ""
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSize
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    visible: text !== ""
                }

                Text {
                    id: toastBody
                    text: ""
                    color: Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSizeSm
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    visible: text !== ""
                }
            }
        }
    }
}

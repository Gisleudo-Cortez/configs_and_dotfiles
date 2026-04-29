import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    readonly property var _screen: screen
    WlrLayershell.namespace: "quickshell:notif"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { top: true; right: true }
    exclusiveZone: -1
    margins.top: Geometry.barHeight + Geometry.outerGap * 2 + 4
    margins.right: Geometry.outerGap

    implicitWidth: Geometry.popupWidth
    implicitHeight: Math.min(box.implicitHeight, 420)
    color: "transparent"

    visible: PopupState.active === "notif" && PopupState.screen === _screen

    Rectangle {
        anchors.fill: parent
        color: Colors.bgPopup
        radius: Geometry.islandRadius
        border.color: Colors.border
        border.width: Geometry.borderWidth

        Flickable {
            id: flick
            anchors.fill: parent
            contentHeight: box.implicitHeight
            clip: true

            ColumnLayout {
                id: box
                width: flick.width
                spacing: 0

                // Header row
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: Geometry.innerPad
                    Layout.bottomMargin: 6

                    Text {
                        text: "󰂚  Notifications"
                        color: Colors.purple
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: Geometry.fontSize
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "clear all"
                        color: Colors.textDim
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: Geometry.fontSizeSm
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { NotifService.dismissAll(); PopupState.close() }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Colors.textDim; opacity: 0.25 }

                // Empty state
                Text {
                    visible: notifRepeater.count === 0
                    text: "No notifications"
                    color: Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSize
                    Layout.alignment: Qt.AlignHCenter
                    Layout.margins: Geometry.innerPad
                }

                // Notification items
                Repeater {
                    id: notifRepeater
                    model: NotifService.notifications
                    delegate: ColumnLayout {
                        width: box.width
                        spacing: 0

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.margins: Geometry.innerPad
                            Layout.topMargin: 8
                            Layout.bottomMargin: 8
                            spacing: 3

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: modelData.appName
                                    color: Colors.cyan
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: Geometry.fontSizeSm
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: "✕"
                                    color: Colors.textDim
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: Geometry.fontSizeSm
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: NotifService.dismiss(modelData)
                                    }
                                }
                            }
                            Text {
                                visible: modelData.summary !== ""
                                text: modelData.summary
                                color: Colors.text
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: Geometry.fontSize
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }
                            Text {
                                visible: modelData.body !== ""
                                text: modelData.body
                                color: Colors.textDim
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: Geometry.fontSizeSm
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            visible: index < notifRepeater.count - 1
                            Layout.fillWidth: true
                            height: 1
                            color: Colors.textDim
                            opacity: 0.15
                        }
                    }
                }

                Item { height: Geometry.innerPad }
            }
        }
    }
}

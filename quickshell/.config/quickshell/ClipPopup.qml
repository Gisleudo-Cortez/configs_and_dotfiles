import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    WlrLayershell.namespace: "quickshell:clip"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { top: true; right: true }
    exclusiveZone: -1
    margins.top: Geometry.barHeight + Geometry.outerGap * 2 + 4
    margins.right: Geometry.outerGap

    implicitWidth: Geometry.popupWidth
    implicitHeight: Math.min(box.implicitHeight, 400)
    color: "transparent"

    visible: PopupState.active === "clip" && PopupState.screen === screen

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

                // Header
                Text {
                    text: "󰅎  Clipboard"
                    color: Colors.purple
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSize
                    Layout.margins: Geometry.innerPad
                    Layout.bottomMargin: 6
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Colors.textDim; opacity: 0.25 }

                // Loading indicator
                Text {
                    visible: ClipService.loading
                    text: "Loading…"
                    color: Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSize
                    Layout.alignment: Qt.AlignHCenter
                    Layout.margins: Geometry.innerPad
                }

                // Empty state
                Text {
                    visible: !ClipService.loading && ClipService.entries.length === 0
                    text: "Clipboard is empty"
                    color: Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSize
                    Layout.alignment: Qt.AlignHCenter
                    Layout.margins: Geometry.innerPad
                }

                Repeater {
                    id: clipRepeater
                    model: ClipService.entries
                    delegate: ColumnLayout {
                        width: box.width
                        spacing: 0

                        Rectangle {
                            Layout.fillWidth: true
                            height: entryText.implicitHeight + 12
                            color: clipArea.containsMouse ? Qt.rgba(0.71, 0.537, 0.839, 0.1) : "transparent"

                            Text {
                                id: entryText
                                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                                anchors.leftMargin: Geometry.innerPad
                                anchors.rightMargin: Geometry.innerPad
                                // strip the cliphist ID prefix (tab-separated)
                                text: modelData.indexOf("\t") >= 0 ? modelData.substring(modelData.indexOf("\t") + 1) : modelData
                                color: Colors.text
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: Geometry.fontSizeSm
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.WordWrap
                            }

                            MouseArea {
                                id: clipArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: { ClipService.copy(modelData); PopupState.close() }
                            }
                        }

                        Rectangle {
                            visible: index < clipRepeater.count - 1
                            Layout.fillWidth: true
                            height: 1
                            color: Colors.textDim
                            opacity: 0.12
                        }
                    }
                }

                Item { height: Geometry.innerPad }
            }
        }
    }
}

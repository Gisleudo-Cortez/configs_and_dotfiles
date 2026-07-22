import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

PanelWindow {
    id: root
    readonly property var _screen: screen

    WlrLayershell.namespace: "quickshell:audio"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { top: true; right: true }
    exclusiveZone: -1
    margins.top: Geometry.barHeight + Geometry.outerGap * 2 + 4
    // Right margin anchors popup under the clicked widget.
    // Falls back to outerGap when no anchor X is set.
    margins.right: PopupState.popupAnchorX >= 0
        ? Math.max(Geometry.outerGap,
              Math.min(_screen.width - Geometry.outerGap - implicitWidth,
                  _screen.width - PopupState.popupAnchorX - implicitWidth / 2))
        : Geometry.outerGap

    implicitWidth: Geometry.popupWidth
    implicitHeight: Math.min(box.implicitHeight, 560)
    color: "transparent"

    visible: PopupState.active === "audio" && PopupState.screen === _screen

    Rectangle {
        anchors.fill: parent
        color: Colors.bgPopup
        radius: Geometry.islandRadius
        border.color: Colors.border
        border.width: Geometry.borderWidth

        // Fade-out animation on close
        Behavior on opacity { NumberAnimation { duration: 150 } }

        // Miku teal top accent
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 2
            color: Colors.cyan
            radius: 2
        }

        Flickable {
            id: flick
            anchors.fill: parent
            contentHeight: box.implicitHeight
            clip: true

            ColumnLayout {
                id: box
                width: flick.width
                spacing: 0

                // ── Header + current device ───────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.margins: Geometry.innerPad
                    Layout.bottomMargin: 8
                    spacing: 4

                    Text {
                        text: "󰕾  Audio Output"
                        color: Colors.cyan
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: Geometry.fontSize
                    }

                    Text {
                        text: AudioService.sinkName
                        color: Colors.textDim
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: Geometry.fontSizeSm
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    // ── Volume slider row ─────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Geometry.popupSpacing

                        Text {
                            text: AudioService.volIcon()
                            color: AudioService.muted ? Colors.textDim : Colors.cyan
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: Geometry.fontSize
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: AudioService.toggleMute()
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            height: 20

                            // Track background
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 4
                                radius: 2
                                color: Colors.textDim
                                opacity: 0.25
                            }
                            // Fill
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * Math.min(AudioService.volume / 1.5, 1)
                                height: 4
                                radius: 2
                                color: AudioService.muted ? Colors.textDim : Colors.cyan
                            }
                            // Click to set volume
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.SizeHorCursor
                                onClicked: function(m) {
                                    AudioService.setVolume((m.x / width) * 1.5)
                                }
                                onPositionChanged: function(m) {
                                    if (pressed) AudioService.setVolume((m.x / width) * 1.5)
                                }
                            }
                        }

                        Text {
                            text: AudioService.volPct() + "%"
                            color: AudioService.muted ? Colors.textDim : Colors.text
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: Geometry.fontSizeSm
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Colors.textDim; opacity: 0.25 }

                // ── Sink list ─────────────────────────────────────────────
                Text {
                    visible: Pipewire.nodes.count === 0
                    text: "No audio outputs found"
                    color: Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSize
                    Layout.alignment: Qt.AlignHCenter
                    Layout.margins: Geometry.innerPad
                }

                Repeater {
                    id: sinkRepeater
                    model: Pipewire.nodes

                    delegate: ColumnLayout {
                        visible: modelData.isSink && !modelData.isStream && modelData.audio !== null
                        width: box.width
                        spacing: 0

                        Rectangle {
                            visible: parent.visible
                            Layout.fillWidth: true
                            height: visible ? sinkLabel.implicitHeight + 16 : 0
                            color: {
                                if (sinkArea.containsMouse) return Qt.rgba(0.71, 0.537, 0.839, 0.12)
                                if (modelData === AudioService.sink) return Qt.rgba(0.71, 0.537, 0.839, 0.06)
                                return "transparent"
                            }

                            RowLayout {
                                anchors {
                                    left: parent.left; right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: Geometry.innerPad; rightMargin: Geometry.innerPad
                                }
                                spacing: Geometry.popupSpacing

                                // Active indicator
                                Text {
                                    text: modelData === AudioService.sink ? "󰓃" : "  "
                                    color: Colors.purple
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: Geometry.fontSizeSm
                                }

                                Text {
                                    id: sinkLabel
                                    text: modelData.description || modelData.name
                                    color: modelData === AudioService.sink ? Colors.text : Colors.textDim
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: Geometry.fontSizeSm
                                    font.bold: modelData === AudioService.sink
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: sinkArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: {
                                    AudioService.setDefaultSink(modelData)
                                    PopupState.close()
                                }
                            }
                        }

                        Rectangle {
                            visible: parent.visible && index < sinkRepeater.count - 1
                            Layout.fillWidth: true
                            height: 1
                            color: Colors.textDim
                            opacity: 0.1
                        }
                    }
                }

                // ── Per-app volume ────────────────────────────────────────
                // Bind all nodes so stream audio.volume / audio.muted are valid
                PwObjectTracker {
                    objects: Pipewire.nodes.values
                }

                // Count audio-out streams (reactive on nodes list change)
                property int streamCount: {
                    var c = 0
                    var vals = Pipewire.nodes.values
                    for (var i = 0; i < vals.length; i++) {
                        var n = vals[i]
                        if (n.isStream && n.audio !== null && !n.isSink) c++
                    }
                    return c
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colors.textDim
                    opacity: 0.25
                    visible: box.streamCount > 0
                }

                Text {
                    visible: box.streamCount > 0
                    text: "󰎆  Applications"
                    color: Colors.purple
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSize
                    Layout.margins: Geometry.innerPad
                    Layout.bottomMargin: 4
                }

                Repeater {
                    model: Pipewire.nodes

                    delegate: ColumnLayout {
                        visible: modelData.isStream && modelData.audio !== null && !modelData.isSink
                        width: box.width
                        spacing: 0

                        // Guard: null audio on non-audio stream nodes
                        property var au: modelData.audio
                        property bool auMuted: au ? au.muted : false
                        property real auVol: au ? au.volume : 0

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: Geometry.innerPad
                            Layout.rightMargin: Geometry.innerPad
                            Layout.topMargin: 4
                            Layout.bottomMargin: 4
                            spacing: Geometry.popupSpacing

                            // Mute toggle
                            Text {
                                text: auMuted ? "󰝟" : "󰕾"
                                color: auMuted ? Colors.textDim : Colors.cyan
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: Geometry.fontSize
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (au) au.muted = !au.muted
                                }
                            }

                            // App name
                            Text {
                                text: (modelData.properties && modelData.properties["application.name"]) || modelData.description || modelData.name
                                color: Colors.text
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: Geometry.fontSizeSm
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            // Per-app volume slider
                            Item {
                                Layout.preferredWidth: 80
                                height: 20

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width
                                    height: 4
                                    radius: 2
                                    color: Colors.textDim
                                    opacity: 0.25
                                }
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width * Math.min(auVol / 1.5, 1)
                                    height: 4
                                    radius: 2
                                    color: auMuted ? Colors.textDim : Colors.cyan
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.SizeHorCursor
                                    onClicked: function(m) {
                                        if (au) au.volume = (m.x / width) * 1.5
                                    }
                                    onPositionChanged: function(m) {
                                        if (pressed && au) au.volume = (m.x / width) * 1.5
                                    }
                                }
                            }

                            // Volume percentage
                            Text {
                                text: Math.round(auVol * 100) + "%"
                                color: auMuted ? Colors.textDim : Colors.text
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: Geometry.fontSizeSm
                            }
                        }

                        Rectangle {
                            visible: parent.visible
                            Layout.fillWidth: true
                            height: 1
                            color: Colors.textDim
                            opacity: 0.1
                        }
                    }
                }

                Item { height: Geometry.innerPad }
            }
        }
    }
}

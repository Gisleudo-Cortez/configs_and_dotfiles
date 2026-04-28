import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    required property var screen
    WlrLayershell.namespace: "quickshell:bar"
    WlrLayershell.layer: WlrLayer.Top

    anchors { top: true; left: true; right: true }
    height: Geometry.barHeight + Geometry.outerGap * 2
    color: "transparent"
    exclusiveZone: height

    // ── active popup tracker ──────────────────────────────────────────────
    property string activePopup: ""   // "calendar" | "notif" | "clip" | ""
    function togglePopup(name) { activePopup = activePopup === name ? "" : name }

    // ── three floating islands ────────────────────────────────────────────
    Item {
        anchors.fill: parent

        RowLayout {
            anchors {
                top: parent.top; left: parent.left; right: parent.right
                margins: Geometry.outerGap
            }
            height: Geometry.barHeight
            spacing: 0

            // LEFT — workspaces + window title
            IslandLeft {
                Layout.fillHeight: true
                Layout.preferredWidth: implicitWidth
            }

            Item { Layout.fillWidth: true }

            // CENTER — clock
            IslandCenter {
                Layout.fillHeight: true
                Layout.preferredWidth: implicitWidth
                onClockClicked: root.togglePopup("calendar")
            }

            Item { Layout.fillWidth: true }

            // RIGHT — stats + controls
            IslandRight {
                Layout.fillHeight: true
                Layout.fillWidth: true
                bar: root
            }
        }
    }

    // ── popups (positioned below bar) ────────────────────────────────────
    CalendarPopup {
        visible: root.activePopup === "calendar"
        screen: root.screen
        onClose: root.activePopup = ""
    }
    NotifPopup {
        visible: root.activePopup === "notif"
        screen: root.screen
        onClose: root.activePopup = ""
    }
    ClipPopup {
        visible: root.activePopup === "clip"
        screen: root.screen
        onClose: root.activePopup = ""
    }
}

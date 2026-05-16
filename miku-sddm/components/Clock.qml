/**
 * Miku SDDM — Clock Component
 * DSEG7 Classic digits (family="DSEG7 Classic", weight=Bold), teal glow.
 * Colon separator uses JetBrainsMono — DSEG7 butchers non-digit glyphs.
 */
import QtQuick

Item {
    id: clock

    property color digitColor: config.primaryColor
    property string timeStr: Qt.formatTime(new Date(), "HHmm")

    Row {
        anchors.centerIn: parent
        spacing: 0

        // ── Hour digits ────────────────────────────────────────────────
        Text {
            text: clock.timeStr.charAt(0)
            color: clock.digitColor
            font.pixelSize: 220
            font.family: "DSEG7 Classic"
            font.weight: Font.Bold
            width: 140
            horizontalAlignment: Text.AlignRight
        }
        Text {
            text: clock.timeStr.charAt(1)
            color: clock.digitColor
            font.pixelSize: 220
            font.family: "DSEG7 Classic"
            font.weight: Font.Bold
            width: 140
            horizontalAlignment: Text.AlignLeft
        }

        // Gap between hour block and colon
        Item { width: 28; height: 1 }

        // Separator colon — JetBrainsMono, NOT DSEG7 (DSEG7 mangles alphabet glyphs)
        Text {
            text: ":"
            color: Qt.rgba(0, 0.784, 0.667, 0.5)
            font.pixelSize: 160
            font.family: "JetBrainsMono Nerd Font"
            width: 40
            horizontalAlignment: Text.AlignHCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -10
        }

        // Gap between colon and minute block
        Item { width: 28; height: 1 }

        // ── Minute digits ───────────────────────────────────────────────
        Text {
            text: clock.timeStr.charAt(2)
            color: clock.digitColor
            font.pixelSize: 220
            font.family: "DSEG7 Classic"
            font.weight: Font.Bold
            width: 140
            horizontalAlignment: Text.AlignRight
        }
        Text {
            text: clock.timeStr.charAt(3)
            color: clock.digitColor
            font.pixelSize: 220
            font.family: "DSEG7 Classic"
            font.weight: Font.Bold
            width: 140
            horizontalAlignment: Text.AlignLeft
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock.timeStr = Qt.formatTime(new Date(), "HHmm")
    }
}

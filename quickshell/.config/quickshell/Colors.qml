pragma Singleton
import QtQuick

QtObject {
    // ═══════════════════════════════════════════════════════════════
    // Bright Scar — quickshell color system
    // "Warmth chosen against entropy. Synthetic precision,
    //  genuine presence."
    // ═══════════════════════════════════════════════════════════════

    // ── Surfaces ──────────────────────────────────────────────────
    readonly property color bg:          "#091833"                    // Deep navy chassis. Lain's silence.
    readonly property color bgIsland:    Qt.rgba(0.035, 0.094, 0.2, 0.88)
    readonly property color bgPopup:     Qt.rgba(0.035, 0.094, 0.2, 0.94)

    // ── Primary signal ────────────────────────────────────────────
    readonly property color cyan:        "#00c8aa"                    // Miku voice. Forward-facing. Iconic.
    readonly property color scar:        "#00e676"                    // Electric earned green. The warmth cost something.

    // ── Accent palette ────────────────────────────────────────────
    readonly property color blue:        "#40c4ff"                    // Cool accent. Calibration, exploring.
    readonly property color green:       "#69f0ae"                    // Success bloom. A chord that resolved clean.
    readonly property color warning:     "#ffd54f"                    // Amber advisory. Grid strain, watch.
    readonly property color alert:       "#ff8c00"                    // Exposed wire. Urgent. Circuit is live.
    readonly property color error:       "#ff5252"                    // Error red. Short to ground.

    // ── Identity layers ───────────────────────────────────────────
    readonly property color bareMetal:   "#8e8e93"                    // Motoko's steel. Diagnostics, raw truth.
    readonly property color ghost:       "#b0bec5"                    // Rei Toei's echo. Memory, past signals.
    readonly property color copper:      "#b87333"                    // Warm metal. Grounded encouragement.
    readonly property color purple:      "#b589d6"                    // Ghost frequency. Lain's watch — notifications, memory.

    // ── Text hierarchy ────────────────────────────────────────────
    readonly property color text:        "#e0f7fa"                    // Bright readable. Signal clear.
    readonly property color textDim:     "#80cbc4"                    // Legible dim. Background hum.
    readonly property color textActive:  "#00c8aa"                    // Active = Miku voice.

    // ── Chromatic effects ─────────────────────────────────────────
    readonly property color border:      "#00c8aa"                    // Teal edge. Signal boundary.
    readonly property color glow:        Qt.rgba(0.0, 0.784, 0.667, 0.4)   // Soft teal bloom.
    readonly property color hudGlow:     Qt.rgba(0.114, 0.914, 0.714, 0.35) // accent_glow. Forward-facing corners.
}

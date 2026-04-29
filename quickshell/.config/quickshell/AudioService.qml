pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire

QtObject {
    id: root

    // ── Device name: from PipeWire (reactive, no polling) ─────────────────
    // PipeWire.defaultAudioSink.description gives the human-readable name.
    // The node's SPA_PROP_volume is always 1.0 — WirePlumber stores the
    // actual soft volume separately, so we must use wpctl for volume/mute.
    readonly property var sink: Pipewire.defaultAudioSink

    readonly property string sinkName: sink?.description ?? sink?.name ?? "No output"

    readonly property string sinkShortName: {
        const n = sinkName
        const c = n.replace(/ \(.*\)$/, "")
                   .replace(/ Analog Stereo$/, "")
                   .replace(/ Digital Stereo$/, "")
                   .replace(/ \+ HDMI.*$/, "")
        return c.length > 18 ? c.substring(0, 16) + "…" : c
    }

    // ── Volume/mute: via wpctl (reads WirePlumber soft volume) ────────────
    property real volume: 0    // 0.0 – 1.5 (wpctl scale, 1.0 = 100%)
    property bool muted:  false

    readonly property var _volProc: Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                const m = line.match(/([\d.]+)/)
                if (m) root.volume = parseFloat(m[1])
                root.muted = line.includes("MUTED")
            }
        }
    }

    readonly property var _ticker: Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: volProc.running = true
    }

    // ── Helpers ───────────────────────────────────────────────────────────
    function volIcon() {
        if (muted || volume === 0) return "󰝟"
        if (volume < 0.4)          return "󰕿"
        if (volume < 0.75)         return "󰖀"
        return "󰕾"
    }

    function volPct() { return Math.round(volume * 100) }

    // ── Controls: via wpctl ───────────────────────────────────────────────
    readonly property var _setVolProc: Process {
        id: setVolProc
        command: ["true"]
        running: false
        onExited: volProc.running = true
    }

    readonly property var _muteProc: Process {
        id: muteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        running: false
        onExited: volProc.running = true
    }

    function setVolume(v) {
        if (setVolProc.running) return
        const pct = Math.round(Math.max(0, Math.min(150, v * 100)))
        setVolProc.command = ["wpctl", "set-volume", "--limit", "1.5",
                              "@DEFAULT_AUDIO_SINK@", pct + "%"]
        setVolProc.running = true
    }

    function adjustVolume(delta) { setVolume(volume + delta) }

    function toggleMute() {
        if (muteProc.running) return
        muteProc.running = true
    }

    // Switch default output — Pipewire API writes WirePlumber's preferred sink
    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node
    }
}

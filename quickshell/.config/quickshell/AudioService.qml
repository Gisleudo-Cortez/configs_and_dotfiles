pragma Singleton
import QtQuick
import Quickshell.Services.Pipewire

QtObject {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    readonly property string sinkName: {
        const d = sink?.description ?? ""
        if (d) return d
        return sink?.name ?? "No output"
    }

    // Truncated name for bar display
    readonly property string sinkShortName: {
        const n = sinkName
        // Strip common suffixes like "Analog Stereo", "Digital Stereo (IEC958)"
        const cleaned = n.replace(/ \(.*\)$/, "").replace(/ Analog Stereo$/, "")
                         .replace(/ Digital Stereo$/, "")
        if (cleaned.length > 18) return cleaned.substring(0, 16) + "…"
        return cleaned
    }

    function volIcon() {
        if (muted || volume === 0) return "󰝟"
        if (volume < 0.4) return "󰕿"
        if (volume < 0.75) return "󰖀"
        return "󰕾"
    }

    function volPct() { return Math.round(volume * 100) }

    function setVolume(v) {
        if (sink?.audio) sink.audio.volume = Math.max(0, Math.min(1.5, v))
    }

    function adjustVolume(delta) { setVolume(volume + delta) }

    function toggleMute() {
        if (sink?.audio) sink.audio.muted = !sink.audio.muted
    }

    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node
    }
}

import QtQuick
import Quickshell

ShellRoot {
    // Spawn one Bar per connected monitor
    Variants {
        model: Quickshell.screens
        Bar { required property var modelData; screen: modelData }
    }

    // Notification toast windows (one per monitor)
    Variants {
        model: Quickshell.screens
        NotifToast { required property var modelData; screen: modelData }
    }
}

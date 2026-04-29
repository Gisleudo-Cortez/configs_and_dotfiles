import QtQuick
import Quickshell
import "."

ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens
        CalendarPopup { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens
        NotifPopup { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens
        ClipPopup { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens
        NotifToast { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens
        MprisPopup { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens
        AudioPopup { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens
        BluetoothPopup { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens
        NetworkPopup { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens
        DockerPopup { required property var modelData; screen: modelData }
    }
}

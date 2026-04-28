import QtQuick
import Quickshell

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
}

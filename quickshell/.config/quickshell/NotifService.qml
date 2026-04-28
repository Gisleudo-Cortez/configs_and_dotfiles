pragma Singleton
import QtQuick
import Quickshell.Services.Notifications

QtObject {
    id: root

    property int unreadCount: 0

    readonly property var _server: NotificationServer {
        keepOnReload: true
        onNotification: function(notif) {
            notif.tracked = true
            root.unreadCount++
        }
    }

    readonly property var notifications: _server.trackedNotifications

    function dismiss(notif) {
        notif.dismiss()
        unreadCount = Math.max(0, unreadCount - 1)
    }

    function dismissAll() {
        const list = _server.trackedNotifications.values.slice()
        for (const n of list) n.dismiss()
        unreadCount = 0
    }
}

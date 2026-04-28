pragma Singleton
import QtQuick
import Quickshell.Services.Notifications

QtObject {
    id: root

    property int unreadCount: 0
    property var notifications: []

    readonly property var _server: NotificationServer {
        keepOnReload: true

        onNotification: function(notif) {
            notif.tracked = true
            root.notifications = root.notifications.concat([notif])
            root.unreadCount++
        }
    }

    function dismiss(notif) {
        notif.dismiss()
        notifications = notifications.filter(n => n !== notif)
        unreadCount = Math.max(0, unreadCount - 1)
    }

    function dismissAll() {
        for (const n of notifications) n.dismiss()
        notifications = []
        unreadCount = 0
    }
}

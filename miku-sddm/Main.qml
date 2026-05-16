/**
 * Miku SDDM — Main Greeter
 * Teal chassis (#091833), DSEG7 clock, amber destructive actions.
 * Minimalist lock screen with Miku palette.
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

Rectangle {
    id: container
    width: 1920
    height: 1080
    color: config.backgroundColor
    focus: !loginState.visible

    // ── State ──────────────────────────────────────────────────────────
    property int userIndex: 0
    property int sessionIndex: 0
    property bool isLoggingIn: false

    Component.onCompleted: {
        if (typeof userModel !== "undefined" && userModel.lastIndex >= 0)
            userIndex = userModel.lastIndex
        if (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0)
            sessionIndex = sessionModel.lastIndex
    }

    // ── Session name cleanup ───────────────────────────────────────────
    function cleanName(name) {
        if (!name) return ""
        var s = name.toString()
        if (s.indexOf(".desktop") !== -1) s = s.substring(0, s.indexOf(".desktop"))
        s = s.replace(/[-_]/g, " ")
        return s.charAt(0).toUpperCase() + s.slice(1)
    }

    // ── Login logic ────────────────────────────────────────────────────
    function doLogin() {
        if (!loginState.visible || isLoggingIn) return

        var user = ""
        if (typeof userModel !== "undefined" && userModel.count > 0) {
            var idx = Math.max(0, Math.min(userIndex, userModel.count - 1))
            var display = userModel.data(userModel.index(idx, 0), Qt.DisplayRole)
            var edit = userModel.data(userModel.index(idx, 0), Qt.EditRole)
            var nr = userModel.data(userModel.index(idx, 0), Qt.UserRole + 1)
            user = edit ? edit.toString() : (nr ? nr.toString() : (display ? display.toString() : ""))
        }
        if (!user) user = sddm.lastUser
        if (!user && typeof userModel !== "undefined" && userModel.count > 0) {
            var first = userModel.data(userModel.index(0, 0), Qt.EditRole)
            user = first ? first.toString() : ""
        }
        if (!user) return

        isLoggingIn = true
        var pass = passwordField.text
        var sess = Math.max(0, Math.min(sessionIndex,
            typeof sessionModel !== "undefined" ? sessionModel.count - 1 : 0))
        sddm.login(user.trim(), pass, sess)
        loginTimeout.start()
    }

    Timer {
        id: loginTimeout
        interval: 5000
        onTriggered: container.isLoggingIn = false
    }

    // ── SDDM callbacks ─────────────────────────────────────────────────
    Connections {
        target: sddm
        function onLoginFailed() {
            container.isLoggingIn = false
            loginTimeout.stop()
            loginState.isError = true
            shakeAnim.start()
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
        function onLoginSucceeded() {
            loginTimeout.stop()
        }
    }

    // ── Background ─────────────────────────────────────────────────────
    Image {
        id: bgImage
        source: config.background
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
    }

    // ── Dark overlay ───────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: config.backgroundColor
        opacity: loginState.visible ? 0.55 : 0.35
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }

    // ── Power bar (top-right) ──────────────────────────────────────────
    PowerBar {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 30
            rightMargin: 40
        }
        textColor: config.primaryColor
        z: 100
    }

    // ── Keyboard shortcuts ─────────────────────────────────────────────
    Shortcut {
        sequence: "Escape"
        enabled: loginState.visible
        onActivated: {
            loginState.visible = false
            loginState.isError = false
            passwordField.text = ""
            container.focus = true
        }
    }
    Shortcut {
        sequences: ["Return", "Enter"]
        enabled: loginState.visible
        onActivated: container.doLogin()
    }

    // ── Date (top-left) ────────────────────────────────────────────────
    Text {
        id: dateText
        text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
        color: config.textColor
        font.pixelSize: 20
        font.family: config.fontFamily
        anchors {
            top: parent.top
            left: parent.left
            topMargin: 50
            leftMargin: 60
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //  LOCK STATE  (idle)
    // ═══════════════════════════════════════════════════════════════════
    Item {
        id: lockState
        anchors.fill: parent
        visible: !loginState.visible
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }

        Clock {
            id: mainClock
            anchors.centerIn: parent
            digitColor: config.primaryColor
        }

        Text {
            text: "Press any key to unlock  ·  <i>mesh operational</i>"
            color: config.textColor
            font.pixelSize: 15
            font.family: config.fontFamily
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin: 80
            }
            opacity: 0.5
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                loginState.visible = true
                passwordField.forceActiveFocus()
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //  LOGIN STATE
    // ═══════════════════════════════════════════════════════════════════
    Item {
        id: loginState
        anchors.fill: parent
        visible: false
        opacity: visible ? 1 : 0
        z: 10
        Behavior on opacity { NumberAnimation { duration: 400 } }

        onVisibleChanged: {
            if (visible) passwordField.forceActiveFocus()
        }

        property bool isError: false

        SequentialAnimation {
            id: shakeAnim
            loops: 2
            PropertyAnimation { target: loginCard; property: "x";
                from: (container.width - loginCard.width) / 2;
                to: (container.width - loginCard.width) / 2 - 10;
                duration: 50; easing.type: Easing.InOutQuad }
            PropertyAnimation { target: loginCard; property: "x";
                from: (container.width - loginCard.width) / 2 - 10;
                to: (container.width - loginCard.width) / 2 + 10;
                duration: 50; easing.type: Easing.InOutQuad }
            PropertyAnimation { target: loginCard; property: "x";
                from: (container.width - loginCard.width) / 2 + 10;
                to: (container.width - loginCard.width) / 2;
                duration: 50; easing.type: Easing.InOutQuad }
        }

        // ── Login card ─────────────────────────────────────────────────
        Rectangle {
            id: loginCard
            width: 380
            height: 480
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            color: loginState.isError
                ? Qt.rgba(0.267, 0.086, 0.086, 0.95)    // dark red on error
                : Qt.rgba(0.035, 0.094, 0.2, 0.92)       // navy chassis
            radius: 28
            border.width: 1
            border.color: Qt.rgba(0, 0.784, 0.667, 0.2)  // teal border glow

            Behavior on color { ColorAnimation { duration: 200 } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 36
                spacing: 14

                // ── Avatar ─────────────────────────────────────────────
                Item {
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 100
                    Layout.alignment: Qt.AlignHCenter

                    // Fallback — first letter of username
                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(0, 0.784, 0.667, 0.15)
                        radius: width / 2
                        visible: avatarImg.status !== Image.Ready

                        Text {
                            anchors.centerIn: parent
                            text: {
                                if (typeof userModel !== "undefined" && userModel.count > 0) {
                                    var d = userModel.data(userModel.index(container.userIndex, 0), Qt.DisplayRole)
                                    var nr = userModel.data(userModel.index(container.userIndex, 0), Qt.UserRole + 1)
                                    var n = d ? d.toString() : (nr ? nr.toString() : "U")
                                    return n.charAt(0).toUpperCase()
                                }
                                return sddm.lastUser ? sddm.lastUser.charAt(0).toUpperCase() : "U"
                            }
                            color: config.primaryColor
                            font.pixelSize: 42
                            font.family: config.fontFamily
                            font.weight: Font.Bold
                        }
                    }

                    // Avatar image in circular clip (Qt6-native, no OpacityMask)
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        radius: width / 2
                        clip: true
                        visible: avatarImg.status === Image.Ready

                        Image {
                            id: avatarImg
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            source: {
                                if (typeof userModel !== "undefined" && userModel.count > 0) {
                                    var icon = userModel.data(userModel.index(container.userIndex, 0), Qt.UserRole + 3)
                                    if (icon && icon.toString().match(/\.(jpg|jpeg|png|bmp|webp|svg)$/i))
                                        return icon.toString()
                                }
                                return ""
                            }
                        }
                    }

                    // Ring
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        radius: width / 2
                        border.width: 2
                        border.color: config.primaryColor
                        opacity: 0.35
                    }
                }

                // ── Username ────────────────────────────────────────────
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: userName.width + 30
                    Layout.preferredHeight: userName.height + 14
                    Layout.topMargin: 6

                    Rectangle {
                        anchors.fill: parent
                        color: "white"
                        opacity: userClickArea.pressed ? 0.15 : 0
                        radius: 10
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }

                    Text {
                        id: userName
                        anchors.centerIn: parent
                        text: {
                            if (typeof userModel !== "undefined" && userModel.count > 0) {
                                var idx = container.userIndex
                                var mIdx = userModel.index(idx, 0)
                                var display = userModel.data(mIdx, Qt.DisplayRole)
                                var realName = userModel.data(mIdx, Qt.UserRole + 2)
                                var nr = userModel.data(mIdx, Qt.UserRole + 1)
                                var edit = userModel.data(mIdx, Qt.EditRole)
                                var n = display ? display.toString()
                                    : (realName ? realName.toString()
                                    : (nr ? nr.toString()
                                    : (edit ? edit.toString() : "User")))
                                return cleanName(n) + (userModel.count > 1 ? " ▾" : "")
                            }
                            return cleanName(sddm.lastUser || "User")
                        }
                        color: "white"
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        font.family: config.fontFamily
                    }

                    MouseArea {
                        id: userClickArea
                        anchors.fill: parent
                        onClicked: userPopup.open()
                    }
                    scale: userClickArea.pressed ? 0.95 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                // ── Session selector ────────────────────────────────────
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 160
                    Layout.preferredHeight: 34
                    color: sessionClickArea.pressed
                        ? Qt.rgba(0, 0.784, 0.667, 0.12)
                        : Qt.rgba(0, 0.784, 0.667, 0.06)
                    radius: 17
                    border.width: 1
                    border.color: Qt.rgba(0, 0.784, 0.667, 0.2)

                    scale: sessionClickArea.pressed ? 0.95 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (typeof sessionModel !== "undefined" && sessionModel.count > 0) {
                                var idx = container.sessionIndex
                                var mIdx = sessionModel.index(idx, 0)
                                var n = sessionModel.data(mIdx, Qt.UserRole + 4)
                                var f = sessionModel.data(mIdx, Qt.UserRole + 2)
                                var d = sessionModel.data(mIdx, Qt.DisplayRole)
                                var name = n ? n.toString() : (f ? f.toString() : (d ? d.toString() : "Session"))
                                return cleanName(name) + (sessionModel.count > 1 ? " ▾" : "")
                            }
                            return "Hyprland"
                        }
                        color: config.textColor
                        font.pixelSize: 12
                        font.family: config.fontFamily
                    }

                    MouseArea {
                        id: sessionClickArea
                        anchors.fill: parent
                        onClicked: sessionPopup.open()
                    }
                }

                // ── Error label ─────────────────────────────────────────
                Text {
                    id: errorLabel
                    text: loginState.isError ? "Wrong password — try again." : ""
                    color: config.alertColor
                    font.pixelSize: 13
                    font.family: config.fontFamily
                    Layout.alignment: Qt.AlignHCenter
                    visible: loginState.isError
                    opacity: visible ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                Item { Layout.fillHeight: true }

                // ── Password field ──────────────────────────────────────
                TextField {
                    id: passwordField
                    echoMode: TextInput.Password
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 17
                    font.family: config.fontFamily
                    color: "white"
                    enabled: !container.isLoggingIn

                    background: Rectangle {
                        color: Qt.rgba(0, 0.784, 0.667, 0.08)
                        radius: 14
                        border.width: parent.activeFocus ? 2 : 1
                        border.color: parent.activeFocus
                            ? config.primaryColor
                            : Qt.rgba(0, 0.784, 0.667, 0.15)
                        opacity: parent.enabled ? 1.0 : 0.5
                    }

                    Text {
                        text: "Password"
                        color: config.textDimColor
                        font.pixelSize: 15
                        font.family: config.fontFamily
                        visible: !parent.text
                        anchors.centerIn: parent
                        opacity: 0.5
                    }

                    onAccepted: container.doLogin()
                }

                // ── Num Lock indicator ──────────────────────────────────
                Text {
                    text: "Num Lock on"
                    color: config.primaryColor
                    font.pixelSize: 13
                    font.family: config.fontFamily
                    Layout.alignment: Qt.AlignHCenter
                    visible: typeof keyboard !== "undefined" && keyboard.numLock === true
                }

                Item { Layout.fillHeight: true }

                // ── Login button ────────────────────────────────────────
                RoundButton {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 56
                    Layout.preferredHeight: 56
                    focusPolicy: Qt.NoFocus
                    enabled: !container.isLoggingIn

                    contentItem: Text {
                        text: container.isLoggingIn ? "···" : "→"
                        color: config.backgroundColor
                        font.pixelSize: 28
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: container.isLoggingIn
                            ? Qt.rgba(0, 0.784, 0.667, 0.3)
                            : config.primaryColor
                        radius: 28
                        opacity: container.isLoggingIn ? 0.5 : 1.0
                    }

                    onClicked: container.doLogin()
                }
            }
        }
    }

    // ── Any key → login state ──────────────────────────────────────────
    Keys.onPressed: function(event) {
        if (!loginState.visible) {
            loginState.visible = true
            passwordField.forceActiveFocus()
            event.accepted = true
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //  USER POPUP
    // ═══════════════════════════════════════════════════════════════════
    Popup {
        id: userPopup
        width: 260
        height: typeof userModel !== "undefined"
            ? Math.min(300, userModel.count * 50 + 20) : 100
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 - 50
        modal: true; focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: userList.forceActiveFocus()

        background: Rectangle {
            color: config.backgroundColor
            radius: 24; opacity: 0.97
            border.color: Qt.rgba(0, 0.784, 0.667, 0.2)
            border.width: 1
        }
        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
        exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 200 } }

        ListView {
            id: userList
            anchors.fill: parent; anchors.margins: 10
            model: typeof userModel !== "undefined" ? userModel : null
            spacing: 5; clip: true; focus: true
            currentIndex: container.userIndex
            highlightFollowsCurrentItem: true

            delegate: ItemDelegate {
                width: parent.width; height: 40
                property bool isCurrent: index === userList.currentIndex

                background: Rectangle {
                    color: isCurrent
                        ? Qt.rgba(0, 0.784, 0.667, 0.12)
                        : (hovered ? Qt.rgba(0, 0.784, 0.667, 0.05) : "transparent")
                    radius: 12
                    Rectangle {
                        anchors.left: parent.left; anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 4
                        height: isCurrent ? 16 : 0
                        color: config.primaryColor; radius: 2
                        Behavior on height { NumberAnimation { duration: 150 } }
                    }
                }
                contentItem: RowLayout {
                    anchors.fill: parent; spacing: 0
                    Item { Layout.preferredWidth: 20 }
                    Rectangle {
                        Layout.preferredWidth: 28; Layout.preferredHeight: 28
                        Layout.alignment: Qt.AlignVCenter
                        color: isCurrent
                            ? Qt.rgba(0, 0.784, 0.667, 0.2)
                            : Qt.rgba(0, 0.784, 0.667, 0.08)
                        radius: 14
                        Text {
                            anchors.centerIn: parent
                            text: {
                                var mIdx = userModel.index(index, 0)
                                var d = userModel.data(mIdx, Qt.DisplayRole)
                                var nr = userModel.data(mIdx, Qt.UserRole + 1)
                                return (d ? d.toString() : (nr ? nr.toString() : "U")).charAt(0).toUpperCase()
                            }
                            color: config.primaryColor
                            font.pixelSize: 12; font.family: config.fontFamily; font.weight: Font.Bold
                        }
                    }
                    Item { Layout.preferredWidth: 12 }
                    Text {
                        Layout.fillWidth: true
                        text: {
                            var mIdx = userModel.index(index, 0)
                            var d = userModel.data(mIdx, Qt.DisplayRole)
                            var r = userModel.data(mIdx, Qt.UserRole + 2)
                            var nr = userModel.data(mIdx, Qt.UserRole + 1)
                            var e = userModel.data(mIdx, Qt.EditRole)
                            return cleanName(d ? d : (r ? r : (nr ? nr : e)))
                        }
                        color: isCurrent ? "white" : (hovered ? "#ccc" : config.textColor)
                        font.pixelSize: 14; font.family: config.fontFamily
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        rightPadding: 60; elide: Text.ElideRight
                    }
                }
                onClicked: { container.userIndex = index; userPopup.close() }
            }
            Keys.onDownPressed: incrementCurrentIndex()
            Keys.onUpPressed: decrementCurrentIndex()
            Keys.onReturnPressed: { container.userIndex = currentIndex; userPopup.close() }
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //  SESSION POPUP
    // ═══════════════════════════════════════════════════════════════════
    Popup {
        id: sessionPopup
        width: 260
        height: typeof sessionModel !== "undefined"
            ? Math.min(250, sessionModel.count * 50 + 20) : 100
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 + 80
        modal: true; focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: sessionList.forceActiveFocus()

        background: Rectangle {
            color: config.backgroundColor
            radius: 24; opacity: 0.97
            border.color: Qt.rgba(0, 0.784, 0.667, 0.2)
            border.width: 1
        }
        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
        exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 200 } }

        ListView {
            id: sessionList
            anchors.fill: parent; anchors.margins: 10
            model: typeof sessionModel !== "undefined" ? sessionModel : null
            spacing: 5; clip: true; focus: true
            currentIndex: container.sessionIndex
            highlightFollowsCurrentItem: true

            delegate: ItemDelegate {
                width: parent.width; height: 40
                property bool isCurrent: index === sessionList.currentIndex

                background: Rectangle {
                    color: isCurrent
                        ? Qt.rgba(0, 0.784, 0.667, 0.12)
                        : (hovered ? Qt.rgba(0, 0.784, 0.667, 0.05) : "transparent")
                    radius: 12
                    Rectangle {
                        anchors.left: parent.left; anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 4
                        height: isCurrent ? 16 : 0
                        color: config.primaryColor; radius: 2
                        Behavior on height { NumberAnimation { duration: 150 } }
                    }
                }
                contentItem: RowLayout {
                    anchors.fill: parent; spacing: 0
                    Item { Layout.preferredWidth: 20 }
                    Text {
                        Layout.preferredWidth: 40
                        text: "\uf111"
                        color: isCurrent ? config.primaryColor : config.textDimColor
                        font.pixelSize: 14; font.family: config.fontFamily
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    Text {
                        Layout.fillWidth: true
                        text: {
                            var mIdx = sessionModel.index(index, 0)
                            var n = sessionModel.data(mIdx, Qt.UserRole + 4)
                            var f = sessionModel.data(mIdx, Qt.UserRole + 2)
                            return cleanName(n ? n : f)
                        }
                        color: isCurrent ? "white" : config.textColor
                        font.pixelSize: 14; font.family: config.fontFamily
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        rightPadding: 60; elide: Text.ElideRight
                    }
                }
                onClicked: { container.sessionIndex = index; sessionPopup.close() }
            }
            Keys.onDownPressed: incrementCurrentIndex()
            Keys.onUpPressed: decrementCurrentIndex()
            Keys.onReturnPressed: { container.sessionIndex = currentIndex; sessionPopup.close() }
        }
    }
}

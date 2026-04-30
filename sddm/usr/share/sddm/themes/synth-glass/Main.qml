import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import SddmComponents
import "components"

Rectangle {
    id: root

    // Screen fills
    width: Screen.width
    height: Screen.height

    // ── colors from theme.conf ──────────────────────────────────
    readonly property color bgColor:          config.backgroundColor    || "#0a0a1a"
    readonly property color accent:           config.accentColor        || "#03edf9"
    readonly property color secondaryAccent:  config.secondaryAccent    || "#72f1b8"
    readonly property color surfaceColor:     config.surfaceColor       || "#141430"
    readonly property color surfaceVariant:   config.surfaceVariantColor|| "#1e1e40"
    readonly property color txtColor:         config.textColor          || "#e0e0f0"
    readonly property color errColor:         config.errorColor         || "#ff7edb"
    readonly property string fontName:        config.font               || "Noto Sans"

    color: bgColor

    // ── wallpaper ───────────────────────────────────────────────
    Image {
        id: wallpaper
        anchors.fill: parent
        source: config.background || ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    // ── frosted glass blur (Qt6 MultiEffect) ────────────────────
    MultiEffect {
        id: glassBlur
        anchors.fill: wallpaper
        source: wallpaper
        blurEnabled: true
        blur: loginPanel.visible ? 1.0 : 0.0
        blurMax: 64
        opacity: loginPanel.visible ? 1.0 : 0.0
        autoPaddingEnabled: false

        Behavior on blur { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
    }

    // ── dim overlay ─────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: loginPanel.visible ? 0.55 : 0.35

        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
    }

    // ── top-right power bar ─────────────────────────────────────
    Item {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 24
        width: powerBarRow.width
        height: powerBarRow.height
        z: 10

        Row {
            id: powerBarRow
            spacing: 6

            PowerBtn {
                action: "suspend"
                visible: sddm.canSuspend
                glyphColor: txtColor
                hoverColor: accent
            }
            PowerBtn {
                action: "reboot"
                glyphColor: txtColor
                hoverColor: accent
            }
            PowerBtn {
                action: "shutdown"
                glyphColor: txtColor
                hoverColor: accent
            }
        }
    }

    // ── top-left date ───────────────────────────────────────────
    Text {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 24
        z: 10
        text: Qt.formatDate(new Date(), "dddd, MMM d")
        color: txtColor
        opacity: 0.65
        font.family: fontName
        font.pixelSize: 14
    }

    // ── idle screen: clock + hint ───────────────────────────────
    Item {
        id: lockScreen
        anchors.fill: parent
        visible: !loginPanel.visible
        z: 5

        Item {
            anchors.centerIn: parent

            Column {
                anchors.centerIn: parent
                spacing: -8

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: new Date().toLocaleTimeString(Qt.locale(), "hh")
                    font.family: fontName
                    font.pixelSize: parseInt(config.clockFontSize) || 72
                    font.weight: Font.Bold
                    color: accent
                    layer.enabled: true
                    layer.effect: DropShadow {
                        radius: 14; samples: 29; color: accent; spread: 0.3
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: new Date().toLocaleTimeString(Qt.locale(), "mm")
                    font.family: fontName
                    font.pixelSize: parseInt(config.clockFontSize) || 72
                    font.weight: Font.Light
                    color: secondaryAccent
                    layer.enabled: true
                    layer.effect: DropShadow {
                        radius: 10; samples: 21; color: secondaryAccent; spread: 0.2
                    }
                }

                Timer {
                    interval: 1000; running: true; repeat: true
                    onTriggered: {
                        // force re-evaluation by touching parent
                        parent.visible = parent.visible
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 60
            text: "Press Enter or click to unlock"
            color: txtColor
            opacity: 0.45
            font.family: fontName
            font.pixelSize: parseInt(config.fontSize) || 14
        }

        MouseArea {
            anchors.fill: parent
            onClicked: showLogin()
        }
    }

    // ── login panel ─────────────────────────────────────────────
    Item {
        id: loginPanel
        anchors.fill: parent
        visible: false
        z: 10

        property bool isError: false
        property bool isLoggingIn: false

        // card
        Rectangle {
            id: card
            anchors.centerIn: parent
            width: 380
            height: 480
            radius: 20
            color: surfaceColor
            opacity: 0.72
            border.width: 1
            border.color: Qt.alpha(accent, 0.2)

            layer.enabled: true
            layer.effect: DropShadow {
                radius: 24; samples: 49; color: "#000000"; spread: 0.15
            }

            // ── error state tint ────────────────────────────────
            Rectangle {
                anchors.fill: parent
                radius: card.radius
                color: errColor
                opacity: loginPanel.isError ? 0.12 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // ── avatar ──────────────────────────────────────────
            Rectangle {
                id: avatarFrame
                anchors.top: parent.top
                anchors.topMargin: 32
                anchors.horizontalCenter: parent.horizontalCenter
                width: 96; height: 96
                radius: 48
                color: surfaceVariant
                border.width: 2
                border.color: accent

                Image {
                    id: avatarImg
                    anchors.fill: parent
                    anchors.margins: 2
                    source: ""
                    fillMode: Image.PreserveAspectCrop
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: avatarImg.width; height: avatarImg.height; radius: 48
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: userInitials
                    color: accent
                    font.family: fontName
                    font.pixelSize: 36
                    font.weight: Font.Bold
                    visible: avatarImg.status !== Image.Ready
                }
            }

            // ── user name ────────────────────────────────────────
            Text {
                id: userNameText
                anchors.top: avatarFrame.bottom
                anchors.topMargin: 12
                anchors.horizontalCenter: parent.horizontalCenter
                text: sddm.lastUser || "User"
                color: txtColor
                font.family: fontName
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }

            // ── session selector ─────────────────────────────────
            ComboBox {
                id: sessionBox
                anchors.top: userNameText.bottom
                anchors.topMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                width: 200; height: 34
                color: "transparent"
                borderColor: Qt.alpha(secondaryAccent, 0.35)
                focusColor: accent
                hoverColor: Qt.alpha(accent, 0.3)
                menuColor: surfaceVariant
                textColor: txtColor
                font.pixelSize: 13
                font.family: fontName
                arrowColor: secondaryAccent
                model: sessionModel
                index: sessionModel.lastIndex
            }

            // ── password field ───────────────────────────────────
            Rectangle {
                id: pwFieldBg
                anchors.top: sessionBox.bottom
                anchors.topMargin: 18
                anchors.horizontalCenter: parent.horizontalCenter
                width: 260; height: 42
                radius: 16
                color: surfaceVariant
                border.width: pwInput.activeFocus ? 1.5 : 1
                border.color: pwInput.activeFocus ? accent : Qt.alpha(txtColor, 0.15)

                Behavior on border.color { ColorAnimation { duration: 150 } }

                TextInput {
                    id: pwInput
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    verticalAlignment: TextInput.AlignVCenter
                    color: txtColor
                    font.family: fontName
                    font.pixelSize: 15
                    echoMode: TextInput.Password
                    focus: loginPanel.visible
                    passwordCharacter: "•"
                    passwordMaskDelay: 600

                    onAccepted: doLogin()

                    Keys.onEscapePressed: hideLogin()
                }

                Text {
                    anchors.centerIn: parent
                    text: "Enter Password"
                    color: txtColor
                    opacity: 0.25
                    font.family: fontName
                    font.pixelSize: 15
                    visible: pwInput.text === "" && !pwInput.activeFocus
                }
            }

            // ── error label ──────────────────────────────────────
            Text {
                id: errorLabel
                anchors.top: pwFieldBg.bottom
                anchors.topMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                text: loginPanel.isError ? "Wrong password — try again" : ""
                color: errColor
                font.family: fontName
                font.pixelSize: 12
                opacity: loginPanel.isError ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // ── login button ─────────────────────────────────────
            Rectangle {
                id: loginBtn
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 28
                anchors.horizontalCenter: parent.horizontalCenter
                width: 56; height: 56
                radius: 28
                color: loginPanel.isLoggingIn ? Qt.darker(accent, 1.6) : accent

                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: loginPanel.isLoggingIn ? "..." : "→"
                    color: bgColor
                    font.family: fontName
                    font.pixelSize: 22
                    font.weight: Font.Bold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: doLogin()
                }
            }
        }

        // ── login card shake animation ──────────────────────────
        SequentialAnimation {
            id: shakeAnim
            running: false
            loops: 2
            property int dx: 6
            NumberAnimation { target: card; property: "x"; to: card.x + shakeAnim.dx; duration: 45 }
            NumberAnimation { target: card; property: "x"; to: card.x - shakeAnim.dx; duration: 45 }
            NumberAnimation { target: card; property: "x"; to: card.x + shakeAnim.dx; duration: 45 }
            NumberAnimation { target: card; property: "x"; to: card.x; duration: 45 }
        }

        // ── login timeout ───────────────────────────────────────
        Timer {
            id: loginTimeout
            interval: 5000
            onTriggered: loginPanel.isLoggingIn = false
        }

        // ── functions ───────────────────────────────────────────
        function doLogin() {
            if (pwInput.text === "") return
            loginPanel.isError = false
            loginPanel.isLoggingIn = true
            loginTimeout.restart()
            sddm.login(sddm.lastUser || "", pwInput.text, sessionBox.index)
        }

        function showError() {
            loginPanel.isError = true
            shakeAnim.restart()
            pwInput.text = ""
            pwInput.focus = true
        }

        // ── keyboard escape ─────────────────────────────────────
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: hideLogin()
        }
    }

    // ── root key handling ───────────────────────────────────────
    Keys.onPressed: (event) => {
        if (!loginPanel.visible) {
            showLogin()
        } else if (event.key === Qt.Key_Escape) {
            hideLogin()
        }
    }

    focus: true

    // ── user initials helper ─────────────────────────────────────
    readonly property string userInitials: {
        var name = sddm.lastUser || "User"
        return name.charAt(0).toUpperCase()
    }

    // ── login state transition helpers ──────────────────────────
    function showLogin() {
        loginPanel.visible = true
        loginPanel.isError = false
        loginPanel.isLoggingIn = false
        pwInput.text = ""
        pwInput.focus = true
    }

    function hideLogin() {
        loginPanel.visible = false
        loginPanel.isError = false
        loginPanel.isLoggingIn = false
        pwInput.text = ""
    }

    // ── SDDM signals ────────────────────────────────────────────
    Connections {
        target: sddm
        function onLoginFailed() {
            loginPanel.isLoggingIn = false
            loginPanel.showError()
        }
        function onLoginSucceeded() {
            // SDDM handles the transition
        }
        function onInformationMessage(msg) {
            errorLabel.text = msg
        }
    }
}

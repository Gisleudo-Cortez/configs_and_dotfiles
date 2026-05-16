/**
 * Miku SDDM — PowerBar Component
 * Teal accent, amber destructive, Nerd Font icons
 */
import QtQuick

Row {
    id: powerBarRoot
    spacing: 22
    height: 30

    property color textColor: config.primaryColor   // teal #00c8aa
    property color dangerColor: config.alertColor    // amber #ffb43c

    // Battery
    Row {
        spacing: 5
        visible: typeof battery !== "undefined" && battery.percent !== undefined
        anchors.verticalCenter: parent.verticalCenter

        Text {
            text: typeof battery !== "undefined" ? battery.percent + "%" : "\u2014"
            color: powerBarRoot.textColor
            font.pixelSize: 14
            font.weight: Font.Medium
            font.family: "JetBrainsMono Nerd Font"
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: (typeof battery !== "undefined" && battery.charging) ? "\uf0e7" : "\uf240"
            color: powerBarRoot.textColor
            font.pixelSize: 18
            font.family: "JetBrainsMono Nerd Font"
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Keyboard Layout
    Text {
        text: (typeof keyboard !== "undefined" && keyboard.layouts[keyboard.currentLayout])
              ? keyboard.layouts[keyboard.currentLayout].shortName : "US"
        color: powerBarRoot.textColor
        font.pixelSize: 14
        font.capitalization: Font.AllUppercase
        font.family: "JetBrainsMono Nerd Font"
        visible: typeof keyboard !== "undefined" && keyboard.layouts.length > 1
        anchors.verticalCenter: parent.verticalCenter

        MouseArea {
            anchors.fill: parent
            onClicked: keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
        }
    }

    // Suspend
    Text {
        text: "\uf186"
        color: powerBarRoot.textColor
        font.pixelSize: 20
        font.family: "JetBrainsMono Nerd Font"
        anchors.verticalCenter: parent.verticalCenter
        MouseArea {
            anchors.fill: parent
            onClicked: sddm.suspend()
        }
    }

    // Restart
    Text {
        text: "\uf01e"
        color: powerBarRoot.textColor
        font.pixelSize: 20
        font.family: "JetBrainsMono Nerd Font"
        anchors.verticalCenter: parent.verticalCenter
        MouseArea {
            anchors.fill: parent
            onClicked: sddm.reboot()
        }
    }

    // Shutdown — amber for destructive
    Text {
        text: "\uf011"
        color: powerBarRoot.dangerColor
        font.pixelSize: 20
        font.family: "JetBrainsMono Nerd Font"
        anchors.verticalCenter: parent.verticalCenter
        MouseArea {
            anchors.fill: parent
            onClicked: sddm.powerOff()
        }
    }
}

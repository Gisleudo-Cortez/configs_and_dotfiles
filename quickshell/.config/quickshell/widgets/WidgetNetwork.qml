import QtQuick
import QtQuick.Layouts

// Network icon + name + VPN indicator, shared hover → NetworkPopup
Item {
    id: root
    implicitWidth: netRow.implicitWidth + vpnWidget.implicitWidth + 10
    implicitHeight: Geometry.barHeight

    property var screen: null
    property bool _netHovered: false
    property bool _vpnHovered: false

    Timer {
        id: netHoverTimer
        interval: 400
        onTriggered: PopupState.showHover("network", root.screen)
    }

    function _checkNetHover() {
        if (_netHovered || _vpnHovered) netHoverTimer.start()
        else { netHoverTimer.stop(); PopupState.clearHover("network") }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 6

        // ── Network ────────────────────────────────────────────────────
        RowLayout {
            id: netRow
            spacing: 4

            Text {
                text: NetworkService.typeIcon
                color: NetworkService.connected ? Colors.cyan : Colors.textDim
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: Geometry.iconFontSize
            }

            Text {
                text: NetworkService.shortName
                color: NetworkService.connected ? Colors.text : Colors.textDim
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: Geometry.fontSizeSm
            }
        }

        HoverHandler {
            onHoveredChanged: { root._netHovered = hovered; root._checkNetHover() }
        }

        // ── VPN ────────────────────────────────────────────────────────
        Item {
            id: vpnWidget
            implicitWidth: vpnText.implicitWidth + 6
            implicitHeight: Geometry.barHeight

            Text {
                id: vpnText
                anchors.centerIn: parent
                text: "󰒄"
                color: VpnService.connected ? Colors.green : Colors.textDim
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: Geometry.iconFontSize
            }

            HoverHandler {
                onHoveredChanged: {
                    root._vpnHovered = hovered
                    root._checkNetHover()
                    if (hovered)
                        TooltipService.show(
                            VpnService.connected
                            ? "Mullvad · " + VpnService.locationLabel
                            : "Mullvad · disconnected · " + VpnService.locationLabel,
                            root.screen)
                    else
                        TooltipService.hide()
                }
            }
        }
    }
}

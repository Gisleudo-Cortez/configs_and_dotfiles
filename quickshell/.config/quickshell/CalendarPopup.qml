import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    required property var screen

    WlrLayershell.namespace: "quickshell:calendar"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { top: true; right: true }
    exclusiveZone: -1
    margins.top: Geometry.barHeight + Geometry.outerGap * 2 + 4
    margins.right: Geometry.outerGap

    width: Geometry.calWidth
    height: calBox.implicitHeight + Geometry.innerPad * 2
    color: "transparent"

    visible: PopupState.active === "calendar" && PopupState.screen === screen
    onVisibleChanged: if (visible) { cal.year = new Date().getFullYear(); cal.month = new Date().getMonth(); Holidays.loadYear(cal.year) }

    Rectangle {
        anchors.fill: parent
        color: Colors.bgPopup
        radius: Geometry.islandRadius
        border.color: Colors.border
        border.width: Geometry.borderWidth

        ColumnLayout {
            id: calBox
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.margins: Geometry.innerPad
            spacing: 8

            // Month navigation header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "‹"
                    color: Colors.textDim
                    font.pixelSize: 18
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (cal.month === 0) { cal.month = 11; cal.year-- }
                            else cal.month--
                            Holidays.loadYear(cal.year)
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    id: monthLabel
                    text: cal.monthNames[cal.month] + " " + cal.year
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Geometry.fontSize
                    font.bold: true
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { cal.year = new Date().getFullYear(); cal.month = new Date().getMonth() }
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "›"
                    color: Colors.textDim
                    font.pixelSize: 18
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (cal.month === 11) { cal.month = 0; cal.year++ }
                            else cal.month++
                            Holidays.loadYear(cal.year)
                        }
                    }
                }
            }

            // Day-of-week headers + day grid
            Grid {
                id: cal
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 2
                columnSpacing: 0

                property int year: new Date().getFullYear()
                property int month: new Date().getMonth()
                property int todayYear: new Date().getFullYear()
                property int todayMonth: new Date().getMonth()
                property int todayDay: new Date().getDate()

                readonly property var monthNames: ["Janeiro","Fevereiro","Março","Abril","Maio","Junho","Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"]
                readonly property var dayNames: ["Dom","Seg","Ter","Qua","Qui","Sex","Sáb"]

                // fixed cell width avoids circular reference on cal.width
                readonly property real cellW: (Geometry.calWidth - Geometry.innerPad * 2) / 7

                readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()
                readonly property int firstWeekday: new Date(year, month, 1).getDay()

                readonly property int totalCells: {
                    const total = firstWeekday + daysInMonth
                    return total % 7 === 0 ? total : total + (7 - total % 7)
                }

                readonly property var cells: {
                    const arr = []
                    for (let i = 0; i < totalCells; i++) {
                        const dayNum = i - firstWeekday + 1
                        arr.push(dayNum >= 1 && dayNum <= daysInMonth ? dayNum : 0)
                    }
                    return arr
                }

                Repeater {
                    model: cal.dayNames
                    delegate: Item {
                        width: cal.cellW
                        height: 18
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: index === 0 ? Colors.alert : Colors.textDim
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: Geometry.fontSizeSm
                        }
                    }
                }

                // Day cells
                Repeater {
                    model: cal.cells
                    delegate: Item {
                        width: cal.cellW
                        height: 26
                        visible: modelData > 0

                        readonly property string isoDate: modelData > 0
                            ? cal.year + "-" + String(cal.month + 1).padStart(2, "0") + "-" + String(modelData).padStart(2, "0")
                            : ""
                        readonly property string holiday: modelData > 0 ? (Holidays.data[isoDate] ?? "") : ""
                        readonly property bool isToday: modelData === cal.todayDay && cal.month === cal.todayMonth && cal.year === cal.todayYear
                        readonly property bool isSunday: index % 7 === 0

                        Rectangle {
                            anchors.centerIn: parent
                            width: 22; height: 22
                            radius: 11
                            color: isToday ? Colors.purple : "transparent"
                        }

                        Rectangle {
                            visible: holiday !== ""
                            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                            width: 4; height: 4; radius: 2
                            color: Colors.cyan
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData > 0 ? modelData : ""
                            color: isToday ? Colors.textActive : isSunday ? Colors.alert : holiday !== "" ? Colors.cyan : Colors.text
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: Geometry.fontSizeSm
                            font.bold: isToday
                        }
                    }
                }
            }

            // Holiday legend for visible month
            ColumnLayout {
                id: holidayList
                Layout.fillWidth: true
                spacing: 2
                visible: holidayRepeater.count > 0

                Rectangle { Layout.fillWidth: true; height: 1; color: Colors.textDim; opacity: 0.2 }

                Repeater {
                    id: holidayRepeater
                    model: {
                        const list = []
                        for (let d = 1; d <= cal.daysInMonth; d++) {
                            const iso = cal.year + "-" + String(cal.month + 1).padStart(2, "0") + "-" + String(d).padStart(2, "0")
                            if (Holidays.data[iso]) list.push({ day: d, name: Holidays.data[iso] })
                        }
                        return list
                    }
                    delegate: Text {
                        text: String(modelData.day).padStart(2, " ") + "  " + modelData.name
                        color: Colors.cyan
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: Geometry.fontSizeSm
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}

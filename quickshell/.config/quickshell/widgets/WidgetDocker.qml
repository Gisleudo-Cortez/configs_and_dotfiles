import QtQuick

// Docker container count indicator
Item {
    id: root
    visible: DockerService.available
    implicitWidth: dockerChip.implicitWidth
    implicitHeight: Geometry.barHeight

    property var screen: null
    signal clicked

    StatChip {
        id: dockerChip
        anchors.centerIn: parent
        screen: root.screen
        icon: "󰡨"
        value: DockerService.runningCount + ""
        color: DockerService.runningCount > 0 ? Colors.cyan : Colors.textDim
        tooltip: "Docker · " + DockerService.runningCount + " running"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

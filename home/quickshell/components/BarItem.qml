import QtQuick
import "../theme"

Rectangle {
    id: root

    property alias text: label.text
    property color textColor: Theme.text
    property bool clickable: false
    property alias hovered: mouseArea.containsMouse
    default property alias content: innerRow.data

    signal clicked()
    signal rightClicked()
    signal wheel(var event)

    implicitHeight: Theme.barHeight
    implicitWidth: innerRow.implicitWidth + (Theme.itemPaddingHorizontal * 2)
    color: hovered ? Theme.hoverBackground : "transparent"
    radius: Theme.itemRadius

    Behavior on color {
        ColorAnimation { duration: Theme.animDuration }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: mouse => {
            if (!root.clickable) return;
            if (mouse.button === Qt.RightButton) {
                root.rightClicked();
            } else if (mouse.button === Qt.LeftButton) {
                root.clicked();
            }
        }

        onWheel: wheel => {
            root.wheel(wheel);
        }
    }

    Row {
        id: innerRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            id: label
            visible: text.length > 0
            color: root.textColor
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}

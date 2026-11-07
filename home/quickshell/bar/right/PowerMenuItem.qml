import QtQuick
import "../../theme"

Rectangle {
    id: root

    required property var actionData
    property bool isSelected: false
    property bool isHolding: false
    property real holdProgress: 0.0

    signal itemPressed()
    signal itemReleased()
    signal itemClicked()
    signal hovered()

    implicitHeight: 52
    implicitWidth: parent ? parent.width : 312
    radius: Theme.itemRadius
    color: root.isSelected ? Theme.hoverBackground : "transparent"
    clip: true

    Behavior on color {
        ColorAnimation { duration: Theme.animDuration }
    }

    // Progress bar fill during long-press
    Rectangle {
        id: progressFill
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.isHolding ? parent.width * root.holdProgress : 0
        color: (root.actionData && root.actionData.dangerous) ? Theme.textDanger : Theme.text
        opacity: 0.3
        radius: Theme.itemRadius

        Behavior on width {
            enabled: !root.isHolding
            NumberAnimation { duration: 150 }
        }
    }

    // Selection indicator bar on the left
    Rectangle {
        id: selectionIndicator
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: root.isSelected ? 24 : 0
        radius: 2
        color: (root.actionData && root.actionData.dangerous) ? Theme.textDanger : Theme.text
        visible: root.isSelected

        Behavior on height {
            NumberAnimation { duration: Theme.animDuration }
        }
    }

    Row {
        id: contentRow
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 12

        // Icon container
        Rectangle {
            id: iconBox
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 32
            radius: 8
            color: root.isSelected ? Qt.rgba(1, 1, 1, 0.1) : "transparent"

            Text {
                anchors.centerIn: parent
                font.family: Theme.fontFamily
                font.pixelSize: 18
                color: (root.actionData && root.actionData.dangerous && root.isSelected)
                    ? Theme.textDanger
                    : Theme.text
                text: root.actionData ? root.actionData.icon : ""
            }
        }

        // Texts (Title + Description)
        Column {
            id: textColumn
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            width: contentRow.width - iconBox.width - contentRow.spacing - shortcutBadge.width - contentRow.spacing

            Text {
                id: titleText
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.weight: root.isSelected ? Font.Bold : Font.Normal
                color: (root.actionData && root.actionData.dangerous && root.isSelected)
                    ? Theme.textDanger
                    : Theme.text
                text: root.actionData ? root.actionData.label : ""
                elide: Text.ElideRight
                width: parent.width
            }

            Text {
                id: descText
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.textMuted
                text: root.actionData ? root.actionData.desc : ""
                elide: Text.ElideRight
                width: parent.width
            }
        }

        // Shortcut badge [D]
        Rectangle {
            id: shortcutBadge
            anchors.verticalCenter: parent.verticalCenter
            width: 24
            height: 22
            radius: 6
            color: root.isSelected ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.05)
            border.color: Theme.borderColor
            border.width: 1

            Text {
                anchors.centerIn: parent
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.Bold
                color: root.isSelected ? Theme.text : Theme.textMuted
                text: root.actionData ? root.actionData.key : ""
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: {
            root.hovered();
        }

        onPressed: {
            root.itemPressed();
        }

        onReleased: {
            root.itemReleased();
        }

        onCanceled: {
            root.itemReleased();
        }

        onClicked: {
            root.itemClicked();
        }
    }
}

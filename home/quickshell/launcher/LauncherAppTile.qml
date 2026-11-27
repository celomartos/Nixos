import QtQuick
import Quickshell
import Quickshell.Widgets
import "../theme"

Item {
    id: tileDelegate

    required property var modelData
    required property int index
    required property var launcher
    required property real cellWidth
    required property real cellHeight

    readonly property int sourceIndex: modelData.sourceIndex
    readonly property bool selected: sourceIndex >= 0 && launcher.selectedApplicationIndex === sourceIndex
    readonly property Item cardItem: tile

    width: cellWidth
    height: cellHeight

    Rectangle {
        id: tile
        anchors.fill: parent
        anchors.margins: 16
        visible: !!tileDelegate.modelData.entry
        radius: 16
        color: tileDelegate.selected ? "#20FFFFFF" : "transparent"
        border.width: tileDelegate.selected ? 1 : 0
        border.color: "#80FFFFFF"

        IconImage {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 16
            implicitSize: 64
            asynchronous: true
            source: tileDelegate.modelData.entry ? Quickshell.iconPath(tileDelegate.modelData.entry.icon || "", "application-x-executable") : ""
        }

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            height: 34
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: Theme.text
            text: tileDelegate.modelData.entry ? tileDelegate.modelData.entry.name : ""
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        MouseArea {
            anchors.fill: parent
            enabled: !!tileDelegate.modelData.entry && !tileDelegate.launcher.keyboardNavigationActive
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                if (tileDelegate.launcher.pageTransitionActive)
                    return;
                tileDelegate.launcher.selectApplication(tileDelegate.sourceIndex);
            }
            onClicked: {
                tileDelegate.launcher.selectApplication(tileDelegate.sourceIndex);
                tileDelegate.launcher.launchEntry(tileDelegate.modelData.entry);
            }
        }
    }
}

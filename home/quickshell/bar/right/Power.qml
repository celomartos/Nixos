import QtQuick
import Quickshell
import "../../theme"
import "../../components"

Item {
    id: root

    implicitHeight: Theme.barHeight
    implicitWidth: powerItem.implicitWidth

    BarItem {
        id: powerItem
        anchors.centerIn: parent
        clickable: true
        text: "⏻ "

        onClicked: {
            powerMenu.toggle();
        }
    }

    PowerMenu {
        id: powerMenu
        anchorItem: powerItem
    }
}

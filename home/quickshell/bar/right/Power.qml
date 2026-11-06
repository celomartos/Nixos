import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../components"

Item {
    id: root

    implicitHeight: Theme.barHeight
    implicitWidth: powerItem.implicitWidth

    Process {
        id: proc
        command: ["bash", (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/rofi/powermenu.sh"]
    }

    BarItem {
        id: powerItem
        anchors.centerIn: parent
        clickable: true
        text: "⏻ "

        onClicked: {
            if (proc.running) {
                proc.running = false;
            } else {
                proc.running = true;
            }
        }
    }
}

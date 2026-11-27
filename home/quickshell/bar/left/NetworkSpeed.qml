import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../components"

Item {
    id: root

    implicitHeight: Theme.barHeight
    implicitWidth: barItem.implicitWidth

    property bool online: false

    // ------------------------------------------------------------
    // Network status process
    // ------------------------------------------------------------

    Process {
        id: proc

        command: ["bash", (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/quickshell/scripts/network-speed.sh"]

        running: false

        stdout: StdioCollector {
            onTextChanged: {
                const result = text.trim();

                if (result === "Online")
                    root.online = true;
                else if (result === "Offline")
                    root.online = false;
            }
        }

        onExited: {
            pollTimer.start();
        }
    }

    // ------------------------------------------------------------
    // Status refresh
    // ------------------------------------------------------------

    Timer {
        id: pollTimer

        interval: 15000
        repeat: false

        onTriggered: {
            if (!proc.running)
                proc.running = true;
        }
    }

    Component.onCompleted: {
        proc.running = true;
    }

    Component.onDestruction: {
        pollTimer.stop();
        proc.running = false;
    }

    // ------------------------------------------------------------
    // Display
    // ------------------------------------------------------------

    BarItem {
        id: barItem

        anchors.centerIn: parent

        clickable: false

        text: root.online ? "󰖩" : "󰖪"

        textColor: root.online ? Theme.textMuted : Theme.textDanger

        onHoveredChanged: {
            if (hovered) {
                closePopupTimer.stop();
                popup.visible = true;
            } else {
                closePopupTimer.start();
            }
        }
    }

    NetworkPopup {
        id: popup
        anchorItem: barItem
        online: root.online
    }

    Timer {
        id: closePopupTimer
        interval: 120
        onTriggered: {
            if (!barItem.hovered && !popup.pointerInside)
                popup.visible = false;
        }
    }
}

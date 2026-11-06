import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../components"

Item {
    id: root

    implicitHeight: Theme.barHeight
    implicitWidth: barItem.implicitWidth

    property string temperature: "--°C"

    Process {
        id: proc
        command: ["bash", (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/waybar/scripts/tempinfo.sh"]
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    root.temperature = text.trim();
                }
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: {
            if (!proc.running) {
                proc.running = true;
            }
        }
    }

    Component.onCompleted: {
        proc.running = true;
    }

    Component.onDestruction: {
        proc.running = false;
    }

    BarItem {
        id: barItem
        anchors.centerIn: parent
        clickable: false
        text: " " + root.temperature
    }
}

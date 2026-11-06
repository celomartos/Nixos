import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../components"

Item {
    id: root

    implicitHeight: Theme.barHeight
    // 16 caracteres em JetBrainsMono 16px ocupam ~154px; fixamos largura para zero relayout
    readonly property int fixedCavaWidth: 160
    implicitWidth: fixedCavaWidth + (Theme.itemPaddingHorizontal * 2)

    Process {
        id: proc
        command: ["bash", (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/quickshell/scripts/cava.sh"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (data.length > 0) {
                    cavaLabel.text = data;
                }
            }
        }
    }

    Component.onDestruction: {
        proc.running = false;
    }

    BarItem {
        id: barItem
        anchors.fill: parent
        clickable: false

        Text {
            id: cavaLabel
            width: root.fixedCavaWidth
            height: Theme.barHeight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
            color: Theme.text
            text: "▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁"
            clip: true
        }
    }
}

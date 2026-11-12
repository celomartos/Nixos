import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../components"

Item {
    id: root

    implicitHeight: Theme.barHeight
    implicitWidth: barItem.implicitWidth

    property string speedText: "↓ 0 B/s  ↑ 0 B/s"
    property string statusClass: "online"
    property string tooltipText: ""

    Process {
        id: proc
        command: ["bash", (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/quickshell/scripts/network-speed.sh"]
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    try {
                        var data = JSON.parse(text.trim());
                        if (data.text) root.speedText = data.text;
                        if (data.class) root.statusClass = data.class;
                        if (data.tooltip) root.tooltipText = data.tooltip;
                    } catch (e) {
                        // Resposta não JSON (fallback texto)
                        root.speedText = text.trim();
                    }
                }
            }
        }
        onExited: {
            pollTimer.start();
        }
    }

    Timer {
        id: pollTimer
        interval: 2000
        repeat: false
        running: false
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
        text: root.speedText
        textColor: (root.statusClass === "offline") ? Theme.textDanger : Theme.textMuted
    }

    PopupWindow {
        id: tooltipPopup

        anchor.window: barItem.QsWindow.window
        anchor.edges: Edges.Top | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
        anchor.adjustment: PopupAdjustment.SlideX

        anchor.onAnchoring: {
            const pos = barItem.mapToItem(
                barItem.QsWindow.window.contentItem,
                0,
                0
            );

            anchor.rect.x = pos.x + (barItem.width - width) / 2;
            anchor.rect.y = pos.y + barItem.height;
            anchor.rect.width = 1;
            anchor.rect.height = 1;
        }

        visible: barItem.hovered && root.tooltipText.length > 0
        color: "transparent"
        width: tipBox.implicitWidth
        height: tipBox.implicitHeight

        Rectangle {
            id: tipBox
            anchors.fill: parent
            color: Theme.background
            border.color: Theme.borderColor
            border.width: 1
            radius: 8
            
            // Padding mais compacto (estilo Waybar)
            implicitWidth: tipText.implicitWidth + 16 
            implicitHeight: tipText.implicitHeight + 12

            Text {
                id: tipText
                anchors.centerIn: parent
                
                // Correções de renderização aplicadas ao Tooltip
                renderType: Theme.textRenderType
                renderTypeQuality: Theme.textRenderQuality
                font.hintingPreference: Theme.fontHinting
                
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall // Tamanho padronizado
                color: Theme.text
                text: root.tooltipText
            }
        }
    }
}

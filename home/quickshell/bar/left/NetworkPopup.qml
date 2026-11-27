import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"

PopupWindow {
    id: root

    property Item anchorItem: null
    property bool pointerInside: false
    property string connectionState: "Offline"
    property string connectionType: "—"
    property string interfaceName: "—"
    property string ipv4: "—"
    property string gateway: "—"
    property string downloadSpeed: "0 B/s"
    property string uploadSpeed: "0 B/s"

    visible: false
    color: "transparent"
    implicitWidth: 280
    implicitHeight: panel.implicitHeight

    anchor.window: anchorItem ? anchorItem.QsWindow.window : null
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.SlideX
    anchor.onAnchoring: {
        if (!root.anchorItem || !root.anchorItem.QsWindow || !root.anchorItem.QsWindow.window)
            return;
        const window = root.anchorItem.QsWindow.window;
        const pos = root.anchorItem.mapToItem(window.contentItem, 0, 0);
        anchor.rect.x = pos.x + root.anchorItem.width - root.width;
        anchor.rect.y = pos.y + root.anchorItem.height;
        anchor.rect.width = 1;
        anchor.rect.height = 1;
    }

    function updateInfo() {
        if (!infoProcess.running)
            infoProcess.running = true;
    }

    onVisibleChanged: {
        if (visible) {
            updateInfo();
            refreshTimer.start();
        } else {
            refreshTimer.stop();
            infoProcess.running = false;
        }
    }

    Timer {
        id: refreshTimer
        interval: 1000
        repeat: true
        onTriggered: root.updateInfo()
    }

    Process {
        id: infoProcess
        command: ["bash", (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/quickshell/scripts/network-info.sh"]
        running: false
        stdout: StdioCollector {
            onTextChanged: {
                try {
                    const info = JSON.parse(text.trim());
                    root.connectionState = info.state || "Offline";
                    root.connectionType = info.type || "—";
                    root.interfaceName = info.interface || "—";
                    root.ipv4 = info.ipv4 || "—";
                    root.gateway = info.gateway || "—";
                    root.downloadSpeed = info.download || "0 B/s";
                    root.uploadSpeed = info.upload || "0 B/s";
                } catch (error) {
                    // Ignore partial output until the script finishes.
                }
            }
        }
        onExited: {
            if (root.visible && !refreshTimer.running)
                refreshTimer.start();
        }
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        implicitHeight: content.implicitHeight + 28
        color: Theme.background
        border.color: Theme.borderColor
        border.width: 1
        radius: Theme.radiusLg

        HoverHandler {
            onHoveredChanged: {
                root.pointerInside = hovered;
                if (hovered)
                    closePopupTimer.stop();
                else
                    closePopupTimer.start();
            }
        }

        Timer {
            id: closePopupTimer
            interval: 120
            onTriggered: {
                if (!root.pointerInside && root.anchorItem && !root.anchorItem.hovered)
                    root.visible = false;
            }
        }

        Column {
            id: content
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Text {
                text: "Network"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Theme.fontWeightBold
                color: Theme.text
            }

            Rectangle { width: parent.width; height: 1; color: Theme.progressTrack }

            Repeater {
                model: [
                    ["Status", root.connectionState],
                    ["Type", root.connectionType],
                    ["Interface", root.interfaceName],
                    ["IPv4", root.ipv4],
                    ["Gateway", root.gateway],
                    ["Download", root.downloadSpeed],
                    ["Upload", root.uploadSpeed]
                ]
                delegate: Row {
                    required property var modelData
                    width: content.width
                    spacing: 8
                    Text {
                        width: 86
                        text: modelData[0]
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textMuted
                    }
                    Text {
                        width: parent.width - 94
                        text: modelData[1]
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        color: modelData[0] === "Status" && modelData[1] === "Offline" ? Theme.textDanger : Theme.text
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}

import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../components"

Item {
    id: root

    implicitHeight: Theme.barHeight
    implicitWidth: barItem.implicitWidth

    property int percent: 0
    property string tooltipInfo: ""

    FileView {
        id: memView
        path: "/proc/meminfo"
        onLoaded: {
            root.calculateMemory();
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: {
            memView.reload();
        }
    }

    function calculateMemory() {
        var lines = memView.text().split("\n");
        var totalKB = 0;
        var availableKB = 0;

        for (var i = 0; i < lines.length; i++) {
            if (lines[i].startsWith("MemTotal:")) {
                totalKB = parseInt(lines[i].replace(/[^0-9]/g, "")) || 0;
            } else if (lines[i].startsWith("MemAvailable:")) {
                availableKB = parseInt(lines[i].replace(/[^0-9]/g, "")) || 0;
            }
        }

        if (totalKB > 0) {
            var usedKB = totalKB - availableKB;
            root.percent = Math.max(0, Math.min(100, Math.round((usedKB / totalKB) * 100)));
            var usedGB = (usedKB / (1024 * 1024)).toFixed(1);
            var totalGB = (totalKB / (1024 * 1024)).toFixed(1);
            root.tooltipInfo = usedGB + "GB / " + totalGB + "GB (" + root.percent + "%)";
        }
    }

    Component.onCompleted: {
        root.calculateMemory();
    }

    BarItem {
        id: barItem
        anchors.centerIn: parent
        clickable: false
        text: " " + root.percent + "%"
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

        visible: barItem.hovered && root.tooltipInfo.length > 0

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

            implicitWidth: tipText.implicitWidth + 24
            implicitHeight: tipText.implicitHeight + 16

            Text {
                id: tipText
                anchors.centerIn: parent
                font.family: Theme.fontFamily
                font.pixelSize: 13
                color: Theme.text
                text: root.tooltipInfo
            }
        }
    }

}

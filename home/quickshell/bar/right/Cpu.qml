import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../components"

Item {
    id: root

    implicitHeight: Theme.barHeight
    implicitWidth: barItem.implicitWidth

    property real lastTotalTime: 0
    property real lastIdleTime: 0
    property int usage: 0

    FileView {
        id: statView
        path: "/proc/stat"
        onLoaded: {
            root.calculateUsage();
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: {
            statView.reload();
        }
    }

    function calculateUsage() {
        var lines = statView.text().split("\n");
        if (lines.length > 0 && lines[0].startsWith("cpu ")) {
            var parts = lines[0].trim().split(/\s+/);
            var user = parseInt(parts[1]) || 0;
            var nice = parseInt(parts[2]) || 0;
            var system = parseInt(parts[3]) || 0;
            var idle = parseInt(parts[4]) || 0;
            var iowait = parseInt(parts[5]) || 0;
            var irq = parseInt(parts[6]) || 0;
            var softirq = parseInt(parts[7]) || 0;
            var steal = parseInt(parts[8]) || 0;

            var currentIdle = idle + iowait;
            var currentTotal = user + nice + system + idle + iowait + irq + softirq + steal;

            var totalDelta = currentTotal - root.lastTotalTime;
            var idleDelta = currentIdle - root.lastIdleTime;

            if (root.lastTotalTime > 0 && totalDelta > 0) {
                root.usage = Math.max(0, Math.min(100, Math.round(100 * (totalDelta - idleDelta) / totalDelta)));
            }

            root.lastTotalTime = currentTotal;
            root.lastIdleTime = currentIdle;
        }
    }

    Component.onCompleted: {
        root.calculateUsage();
    }

    BarItem {
        id: barItem
        anchors.centerIn: parent
        clickable: false
        text: "  " + root.usage + "%"
    }
}

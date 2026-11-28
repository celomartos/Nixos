import QtQuick
import Quickshell
import "../../theme"
import "../../components"

Item {
    id: root

    signal dashboardToggleRequested
    signal dashboardScrollRequested(int direction)
    property alias clockItem: clockItem

    implicitHeight: Theme.barHeight
    implicitWidth: clockItem.implicitWidth

    property var currentTime: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentTime = new Date()
    }

    function formatClock(date) {
        var enLocale = Qt.locale("en_US");
        var datePart = date.toLocaleDateString(enLocale, "ddd, dd, MMM | ");
        var timePart = Qt.formatTime(date, "hh:mm");
        return "  " + datePart + "  " + timePart;
    }

    BarItem {
        id: clockItem

        anchors.centerIn: parent
        clickable: true
        text: root.formatClock(root.currentTime)

        onClicked: root.dashboardToggleRequested()

        onWheel: wheel => {
            if (wheel.angleDelta.y > 0)
                root.dashboardScrollRequested(-1);
            else
                root.dashboardScrollRequested(1);
        }
    }
}

import QtQuick
import "../../theme"
import "../../components"

Item {
    id: root

    implicitHeight: Theme.barHeight
    implicitWidth: clockItem.implicitWidth

    signal dashboardToggleRequested
    signal dashboardTabStepRequested(int direction)

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
            root.dashboardTabStepRequested(wheel.angleDelta.y > 0 ? -1 : 1);
        }
    }
}

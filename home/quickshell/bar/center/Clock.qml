import QtQuick
import Quickshell
import "../../theme"
import "../../components"
import "./dashboard"

Item {
    id: root

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
        var datePart = date.toLocaleDateString(enLocale, "ddd dd MMM");
        var timePart = Qt.formatTime(date, "hh:mm");
        return " : " + datePart + " 󰥔 : " + timePart;
    }

    BarItem {
        id: clockItem

        anchors.centerIn: parent
        clickable: true
        text: root.formatClock(root.currentTime)

        onClicked: dashboard.toggle()

        onWheel: wheel => {
            if (wheel.angleDelta.y > 0)
                dashboard.currentTab = Math.max(0, dashboard.currentTab - 1);
            else
                dashboard.currentTab = Math.min(2, dashboard.currentTab + 1);
        }
    }

    DashboardWindow {
        id: dashboard
        anchorItem: clockItem
    }
}


import QtQuick
import Quickshell
import "../../theme"
import "../../components"

Item {
    id: root

    implicitHeight: Theme.barHeight
    implicitWidth: clockItem.implicitWidth

    property var currentTime: new Date()
    property bool calendarVisible: false

    readonly property alias calendarPopup: calendarPopup

    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            root.currentTime = new Date();
        }
    }

    function formatClock(date) {
        var enLocale = Qt.locale("en_US");
        var datePart = date.toLocaleDateString(enLocale, "ddd dd MMM");
        var timePart = Qt.formatTime(date, "hh:mm");

        return " " + datePart + " 󰥔 " + timePart;
    }

    BarItem {
        id: clockItem

        anchors.centerIn: parent
        clickable: true
        text: root.formatClock(root.currentTime)

        onClicked: {
          if (calendarPopup.visible) {
          calendarPopup.visible = false;
            } else {
                calendarPopup.resetToCurrentMonth();
                calendarPopup.visible = true;
            }
          }

        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) {
                calendarPopup.shiftUp();
            } else {
                calendarPopup.shiftDown();
            }
        }
    }

    CalendarPopup {
        id: calendarPopup

        anchorItem: clockItem
        visible: root.calendarVisible
    }
}


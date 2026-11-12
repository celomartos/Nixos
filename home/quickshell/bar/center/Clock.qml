import QtQuick
import Quickshell
import "../../theme"
import "../../components"

Item {
    id: root

    implicitHeight: Theme.barHeight
    implicitWidth: clockItem.implicitWidth

    property var currentTime: new Date()

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

        // Reduzido para um espaço entre a data e o ícone do relógio
        return " " + datePart + " 󰥔 " + timePart;
    }

    BarItem {
        id: clockItem

        anchors.centerIn: parent
        clickable: true
        text: root.formatClock(root.currentTime)
        // Opcional: Se quiser que o relógio fique branco puro e não cinza
        // textColor: Theme.text 

        onClicked: {
            if (!calendarPopup.visible) {
                calendarPopup.resetToCurrentMonth();
            }

            calendarPopup.toggle();
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
    }
}

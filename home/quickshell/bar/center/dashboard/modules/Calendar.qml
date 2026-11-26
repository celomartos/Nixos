import QtQuick
import "../../../../theme"

Item {
    id: root

    // ------------------------------------------------------------
    // Calendar state
    // ------------------------------------------------------------

    property bool dashboardVisible: false

    property int monthOffset: 0
    property var currentDate: new Date()

    readonly property var today: currentDate

    readonly property var displayedDate: new Date(currentDate.getFullYear(), currentDate.getMonth() + monthOffset, 1)

    // ------------------------------------------------------------
    // Date helpers
    // ------------------------------------------------------------

    function isSameDay(dateA, dateB) {
        return dateA.getFullYear() === dateB.getFullYear() && dateA.getMonth() === dateB.getMonth() && dateA.getDate() === dateB.getDate();
    }

    function shiftMonth(amount) {
        monthOffset += amount;
    }

    function resetToCurrentMonth() {
        monthOffset = 0;
        currentDate = new Date();
    }

    // ------------------------------------------------------------
    // Date refresh
    // ------------------------------------------------------------

    onDashboardVisibleChanged: {
        if (dashboardVisible)
            resetToCurrentMonth();
    }

    Component.onCompleted: {
        if (dashboardVisible)
            resetToCurrentMonth();
    }

    Timer {
        interval: 60000
        repeat: true
        running: root.dashboardVisible

        onTriggered: root.currentDate = new Date()
    }

    // ------------------------------------------------------------
    // Calendar layout
    // ------------------------------------------------------------

    Column {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 12

        // --------------------------------------------------------
        // Month header
        // --------------------------------------------------------

        Row {
            width: parent.width
            height: 36

            Text {
                width: parent.width - 84
                height: parent.height

                verticalAlignment: Text.AlignVCenter

                renderType: Theme.textRenderType
                renderTypeQuality: Theme.textRenderQuality
                font.hintingPreference: Theme.fontHinting

                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Bold

                color: Theme.text

                text: root.displayedDate.toLocaleDateString(Qt.locale("en_US"), "MMMM yyyy")
            }

            Row {
                spacing: 8

                Repeater {
                    model: ["‹", "›"]

                    delegate: Rectangle {
                        required property int index
                        required property string modelData

                        width: 34
                        height: 34
                        radius: 9

                        color: monthButtonMouse.containsMouse ? Theme.hoverBackground : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        Text {
                            anchors.centerIn: parent

                            text: modelData
                            color: Theme.text

                            font.family: Theme.fontFamily
                            font.pixelSize: 25
                        }

                        MouseArea {
                            id: monthButtonMouse

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                root.shiftMonth(index === 0 ? -1 : 1);
                            }
                        }
                    }
                }
            }
        }

        // --------------------------------------------------------
        // Weekdays
        // --------------------------------------------------------

        Row {
            id: weekdaysRow

            width: parent.width
            height: 20
            spacing: 4

            Repeater {
                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

                delegate: Text {
                    required property string modelData

                    width: (weekdaysRow.width - 24) / 7
                    height: weekdaysRow.height

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    renderType: Theme.textRenderType
                    renderTypeQuality: Theme.textRenderQuality
                    font.hintingPreference: Theme.fontHinting

                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: Font.Bold

                    color: Theme.textMuted
                    text: modelData
                }
            }
        }

        // --------------------------------------------------------
        // Calendar grid
        // --------------------------------------------------------

        Grid {
            id: calendarGrid

            width: parent.width
            columns: 7
            spacing: 4

            readonly property int firstDayOfWeek: root.displayedDate.getDay()

            readonly property int daysInMonth: new Date(root.displayedDate.getFullYear(), root.displayedDate.getMonth() + 1, 0).getDate()

            readonly property int totalCells: Math.max(35, Math.ceil((firstDayOfWeek + daysInMonth) / 7) * 7)

            Repeater {
                model: calendarGrid.totalCells

                delegate: Item {
                    required property int index

                    readonly property int dayNumber: index - calendarGrid.firstDayOfWeek + 1

                    readonly property var cellDate: new Date(root.displayedDate.getFullYear(), root.displayedDate.getMonth(), dayNumber)

                    readonly property bool isCurrentMonthDay: dayNumber >= 1 && dayNumber <= calendarGrid.daysInMonth

                    readonly property bool isToday: root.isSameDay(cellDate, root.today)

                    width: (calendarGrid.width - calendarGrid.spacing * 6) / 7

                    height: 28

                    // Hover background
                    Rectangle {
                        anchors.centerIn: parent

                        width: 26
                        height: 26
                        radius: 9

                        visible: dayMouse.containsMouse && !parent.isToday

                        color: Theme.hoverBackground

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                    }

                    // Today's permanent highlight
                    Rectangle {
                        anchors.centerIn: parent

                        width: 26
                        height: 26
                        radius: 9

                        visible: parent.isToday

                        color: Theme.todayBackground
                    }

                    // Day number
                    Text {
                        anchors.centerIn: parent

                        renderType: Theme.textRenderType
                        renderTypeQuality: Theme.textRenderQuality
                        font.hintingPreference: Theme.fontHinting

                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize

                        font.weight: parent.isToday ? Font.DemiBold : Font.Normal

                        color: {
                            if (parent.isToday)
                                return Theme.todayText;

                            if (parent.isCurrentMonthDay)
                                return Theme.text;

                            return Theme.textMuted;
                        }

                        text: parent.cellDate.getDate()
                    }

                    // Hover only — no click or selection state
                    MouseArea {
                        id: dayMouse

                        anchors.fill: parent

                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                        cursorShape: Qt.ArrowCursor
                    }
                }
            }
        }
    }
}

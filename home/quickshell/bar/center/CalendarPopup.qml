
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../theme"

PopupWindow {
    id: root

    required property Item anchorItem

    visible: false
    color: "transparent"

    implicitWidth: 320
    implicitHeight: col.implicitHeight + 48

    // Position relative to the clock module.
    anchor.window: anchorItem ? anchorItem.QsWindow.window : null
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.SlideX

    anchor.onAnchoring: {
        if (!root.anchorItem ||
            !root.anchorItem.QsWindow ||
            !root.anchorItem.QsWindow.window) {
            return;
        }

        const window = root.anchorItem.QsWindow.window;
        const pos = root.anchorItem.mapToItem(
            window.contentItem,
            0,
            0
        );

        anchor.rect.x = pos.x + (root.anchorItem.width - root.width) / 2;
        anchor.rect.y = pos.y + root.anchorItem.height;
        anchor.rect.width = 1;
        anchor.rect.height = 1;
    }

    // Calendar state
    property int monthOffset: 0
    property var currentDate: new Date()

    readonly property var today: currentDate

    readonly property var displayedDate: new Date(
        currentDate.getFullYear(),
        currentDate.getMonth() + monthOffset,
        1
    )

    readonly property alias hovered: popupMouseArea.containsMouse

    // Animation state
    property real popupYOffset: -28
    property real popupOpacity: 0.0

    // Opening animation - same as PowerMenu
    ParallelAnimation {
        id: openAnim

        NumberAnimation {
            target: root
            property: "popupYOffset"
            from: -28
            to: 0
            duration: 180
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "popupOpacity"
            from: 0.0
            to: 1.0
            duration: 180
            easing.type: Easing.OutQuad
        }
    }

    // Closing animation - same as PowerMenu
    ParallelAnimation {
        id: closeAnim

        NumberAnimation {
            target: root
            property: "popupYOffset"
            from: 0
            to: -20
            duration: 120
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: root
            property: "popupOpacity"
            from: 1.0
            to: 0.0
            duration: 120
            easing.type: Easing.InQuad
        }

        onFinished: {
            root.visible = false;
        }
    }

    // Wait until the popup window is visible before grabbing focus.
    Timer {
        id: grabDelay

        interval: 60
        repeat: false

        onTriggered: {
          if (root.visible && !closeAnim.running) {
                bg.forceActiveFocus();
                outsideGrab.active = true;
            }
        }
    }

    // Detect clicks outside the calendar.
    HyprlandFocusGrab {
        id: outsideGrab

        active: false
        windows: [root]

        onCleared: {
            root.closePopup();
        }
    }

    // Open calendar
    function openPopup() {
        grabDelay.stop();

        openAnim.stop();
        closeAnim.stop();

        currentDate = new Date();

        popupYOffset = -28;
        popupOpacity = 0.0;

        root.visible = true;

        openAnim.restart();
        grabDelay.restart();
    }

    // Close calendar
    function closePopup() {
        if (!root.visible || closeAnim.running)
            return;

        grabDelay.stop();
        openAnim.stop();

        // Start animation before disabling the focus grab.
        closeAnim.restart();
        outsideGrab.active = false;
    }

    // Toggle calendar visibility
    function toggle() {
        if (root.visible && !closeAnim.running) {
            closePopup();
        } else {
            openPopup();
        }
    }

    // Reset to current month
    function resetToCurrentMonth() {
        monthOffset = 0;
    }

    // Navigate months
    function shiftUp() {
        monthOffset -= 1;
    }

    function shiftDown() {
        monthOffset += 1;
    }

    // Cleanup when the popup is hidden.
    onVisibleChanged: {
        if (!visible) {
            grabDelay.stop();
            outsideGrab.active = false;

            openAnim.stop();
            closeAnim.stop();

            popupYOffset = -28;
            popupOpacity = 0.0;
        }
    }

    // Keep date updated while calendar is open.
    Timer {
        interval: 60000
        repeat: true
        running: root.visible

        onTriggered: {
            root.currentDate = new Date();
        }
    }

    Rectangle {
        id: bg

        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
          if (event.key === Qt.Key_Escape) {
            root.closePopup();
            event.accepted = true;
        }
    }

        color: Theme.background
        border.color: Theme.borderColor
        border.width: 1
        radius: 16

        // QML animation applied to the calendar itself.
        opacity: root.popupOpacity

        transform: Translate {
            y: root.popupYOffset
        }

        MouseArea {
            id: popupMouseArea

            anchors.fill: parent
            hoverEnabled: true

            onWheel: wheel => {
                if (wheel.angleDelta.y > 0)
                    root.shiftUp();
                else
                    root.shiftDown();
            }
        }

        Column {
            id: col

            anchors.centerIn: parent
            spacing: 12
            width: 272

            // Month and year
            Text {
                anchors.horizontalCenter: parent.horizontalCenter

                font.family: Theme.fontFamily
                font.pixelSize: 20
                font.weight: Font.Bold

                color: Theme.text

                text: root.displayedDate.toLocaleDateString(
                    Qt.locale("en_US"),
                    "MMMM yyyy"
                )
            }

            // Weekdays
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Repeater {
                    model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

                    delegate: Text {
                        required property string modelData

                        width: 32
                        horizontalAlignment: Text.AlignHCenter

                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.Bold

                        color: Theme.text
                        text: modelData
                    }
                }
            }

            // Calendar grid
            Grid {
                id: grid

                anchors.horizontalCenter: parent.horizontalCenter

                columns: 7
                spacing: 8

                readonly property int firstDayOfWeek:
                    root.displayedDate.getDay()

                readonly property int daysInMonth:
                    new Date(
                        root.displayedDate.getFullYear(),
                        root.displayedDate.getMonth() + 1,
                        0
                    ).getDate()

                readonly property int totalCells:
                    Math.ceil((firstDayOfWeek + daysInMonth) / 7) * 7

                Repeater {
                    model: grid.totalCells

                    delegate: Item {
                        required property int index

                        readonly property int dayNumber:
                            index - grid.firstDayOfWeek + 1

                        readonly property bool isValidDay:
                            dayNumber >= 1 &&
                            dayNumber <= grid.daysInMonth

                        readonly property bool isToday:
                            isValidDay &&
                            dayNumber === root.today.getDate() &&
                            root.displayedDate.getMonth() === root.today.getMonth() &&
                            root.displayedDate.getFullYear() === root.today.getFullYear()

                        width: 32
                        height: 28

                        Rectangle {
                            anchors.fill: parent

                            visible: parent.isToday
                            color: "#ffffff"
                            radius: 6
                        }

                        Text {
                            anchors.centerIn: parent

                            visible: parent.isValidDay

                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            font.weight: parent.isToday
                                ? Font.Bold
                                : Font.Normal

                            color: parent.isToday
                                ? "#000000"
                                : "#dddddd"

                            text: parent.isValidDay
                                ? parent.dayNumber
                                : ""
                        }
                    }
                }
            }
        }
    }
}


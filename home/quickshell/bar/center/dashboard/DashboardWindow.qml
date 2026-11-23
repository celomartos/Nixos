import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../theme"

PopupWindow {
    id: root

    required property Item anchorItem

    visible: false
    color: "transparent"

    implicitWidth: 620
    implicitHeight: 420

    anchor.window: anchorItem ? anchorItem.QsWindow.window : null
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.SlideX

    anchor.onAnchoring: {
        if (!root.anchorItem || !root.anchorItem.QsWindow || !root.anchorItem.QsWindow.window) {
            return;
        }

        const window = root.anchorItem.QsWindow.window;
        const pos = root.anchorItem.mapToItem(window.contentItem, 0, 0);

        anchor.rect.x = pos.x + (root.anchorItem.width - root.width) / 2;
        anchor.rect.y = pos.y + root.anchorItem.height;
        anchor.rect.width = 1;
        anchor.rect.height = 1;
    }

    // Dashboard state
    property int currentTab: 0
    property bool animatePageTransition: true

    property real popupYOffset: -28
    property real popupOpacity: 0

    // Calendar state
    property int monthOffset: 0
    property var currentDate: new Date()

    readonly property var today: currentDate

    readonly property var displayedDate: new Date(currentDate.getFullYear(), currentDate.getMonth() + monthOffset, 1)

    // Fixed tabs
    readonly property var tabTitles: ["Calendar", "Media", "System"]

    readonly property var tabIcons: ["", "󰝚", "󰍛"]

    // Opening animation
    ParallelAnimation {
        id: openAnim

        NumberAnimation {
            target: root
            property: "popupYOffset"
            from: -28
            to: 0
            duration: 190
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "popupOpacity"
            from: 0
            to: 1
            duration: 190
            easing.type: Easing.OutQuad
        }
    }

    // Closing animation
    ParallelAnimation {
        id: closeAnim

        NumberAnimation {
            target: root
            property: "popupYOffset"
            from: 0
            to: -20
            duration: 130
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: root
            property: "popupOpacity"
            from: 1
            to: 0
            duration: 130
            easing.type: Easing.InQuad
        }

        onFinished: root.visible = false
    }

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

    HyprlandFocusGrab {
        id: outsideGrab

        active: false
        windows: [root]

        onCleared: root.closePopup()
    }

    // Calendar refresh
    Timer {
        interval: 60000
        repeat: true
        running: root.visible

        onTriggered: root.currentDate = new Date()
    }

    // Dashboard navigation
    function changeTab(direction) {
        currentTab = Math.max(0, Math.min(2, currentTab + direction));
    }

    // Calendar navigation
    function shiftMonth(amount) {
        monthOffset += amount;
    }

    function resetToCurrentMonth() {
        monthOffset = 0;
        currentDate = new Date();
    }

    // Open dashboard
    function openPopup() {
        grabDelay.stop();

        openAnim.stop();
        closeAnim.stop();

        // Always start on Calendar without page transition.
        animatePageTransition = false;
        currentTab = 0;

        resetToCurrentMonth();

        popupYOffset = -28;
        popupOpacity = 0;

        root.visible = true;

        Qt.callLater(function () {
            root.animatePageTransition = true;
        });

        openAnim.restart();
        grabDelay.restart();
    }

    // Close dashboard
    function closePopup() {
        if (!root.visible || closeAnim.running)
            return;

        grabDelay.stop();
        openAnim.stop();

        closeAnim.restart();
        outsideGrab.active = false;
    }

    function toggle() {
        if (root.visible && !closeAnim.running)
            closePopup();
        else
            openPopup();
    }

    onVisibleChanged: {
        if (!visible) {
            grabDelay.stop();
            outsideGrab.active = false;

            openAnim.stop();
            closeAnim.stop();

            popupYOffset = -28;
            popupOpacity = 0;
        }
    }

    Rectangle {
        id: bg

        anchors.fill: parent
        radius: 16

        color: Theme.background
        border.color: Theme.borderColor
        border.width: 1

        opacity: root.popupOpacity
        focus: true

        transform: Translate {
            y: root.popupYOffset
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.closePopup();
                event.accepted = true;
            } else if (event.key === Qt.Key_Left) {
                root.changeTab(-1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                root.changeTab(1);
                event.accepted = true;
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 18

            // Tab bar
            Row {
                id: tabBar

                width: parent.width
                height: 42
                spacing: 8

                Repeater {
                    model: 3

                    delegate: Item {
                        required property int index

                        width: (tabBar.width - 16) / 3
                        height: tabBar.height

                        Rectangle {
                            anchors.fill: parent
                            radius: 10

                            color: root.currentTab === index ? Theme.hoverBackground : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 140
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: root.tabIcons[index]

                                color: root.currentTab === index ? Theme.text : Theme.textMuted

                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize

                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.tabTitles[index]

                                color: root.currentTab === index ? Theme.text : Theme.textMuted

                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.weight: root.currentTab === index ? Font.DemiBold : Font.Normal

                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: root.currentTab = index
                        }
                    }
                }
            }

            // Tab indicator
            Rectangle {
                width: parent.width
                height: 2
                color: Theme.borderColor

                Rectangle {
                    width: parent.width / 3
                    height: parent.height
                    radius: 2

                    color: Theme.text
                    x: root.currentTab * width

                    Behavior on x {
                        enabled: root.animatePageTransition

                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Page container
            Item {
                id: pageViewport

                width: parent.width
                height: parent.height - tabBar.height - 20 - 2

                clip: true

                Row {
                    id: pageTrack

                    height: parent.height
                    width: parent.width * 3

                    x: -root.currentTab * pageViewport.width

                    Behavior on x {
                        enabled: root.animatePageTransition

                        NumberAnimation {
                            duration: 280
                            easing.type: Easing.OutCubic
                        }
                    }

                    Repeater {
                        model: 3

                        delegate: Item {
                            required property int index

                            width: pageViewport.width
                            height: pageViewport.height

                            // CALENDAR PAGE
                            Item {
                                visible: index === 0
                                anchors.fill: parent

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 12

                                    // Month header and navigation
                                    Row {
                                        width: parent.width
                                        height: 36

                                        Text {
                                            width: parent.width - 80
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

                                    // Weekdays
                                    Row {
                                        id: weekdaysRow

                                        width: parent.width
                                        height: 20
                                        spacing: 6

                                        Repeater {
                                            model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

                                            delegate: Text {
                                                required property string modelData

                                                width: (weekdaysRow.width - 36) / 7
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

                                    // Calendar grid
                                    Grid {
                                        id: calendarGrid

                                        width: parent.width
                                        columns: 7
                                        spacing: 6

                                        readonly property int firstDayOfWeek: root.displayedDate.getDay()

                                        readonly property int daysInMonth: new Date(root.displayedDate.getFullYear(), root.displayedDate.getMonth() + 1, 0).getDate()

                                        readonly property int totalCells: Math.ceil((firstDayOfWeek + daysInMonth) / 7) * 7

                                        Repeater {
                                            model: calendarGrid.totalCells

                                            delegate: Item {
                                                required property int index

                                                readonly property int dayNumber: index - calendarGrid.firstDayOfWeek + 1

                                                readonly property bool isValidDay: dayNumber >= 1 && dayNumber <= calendarGrid.daysInMonth

                                                readonly property bool isToday: isValidDay && dayNumber === root.today.getDate() && root.displayedDate.getMonth() === root.today.getMonth() && root.displayedDate.getFullYear() === root.today.getFullYear()

                                                width: (calendarGrid.width - 36) / 7
                                                height: 30

                                                Rectangle {
                                                    width: 28
                                                    height: 28
                                                    radius: 9

                                                    anchors.centerIn: parent

                                                    visible: parent.isToday
                                                    color: "#ffffff"
                                                }

                                                Text {
                                                    anchors.centerIn: parent

                                                    visible: parent.isValidDay

                                                    renderType: Theme.textRenderType
                                                    renderTypeQuality: Theme.textRenderQuality
                                                    font.hintingPreference: Theme.fontHinting

                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: Theme.fontSize
                                                    font.weight: parent.isToday ? Font.Bold : Font.Normal

                                                    color: parent.isToday ? "#000000" : Theme.text

                                                    text: parent.isValidDay ? parent.dayNumber : ""
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // MEDIA AND SYSTEM PLACEHOLDERS
                            Column {
                                visible: index !== 0

                                anchors.centerIn: parent
                                spacing: 10

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    text: root.tabIcons[index]

                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 34
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    text: root.tabTitles[index]

                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeLarge
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    text: "Content will be implemented in this section."

                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                }
                            }
                        }
                    }
                }
            }
        }

        // Mouse wheel tab navigation
        MouseArea {
            anchors.fill: parent
            z: 10

            acceptedButtons: Qt.NoButton
            hoverEnabled: true

            onWheel: wheel => {
                if (wheel.angleDelta.y > 0)
                    root.changeTab(-1);
                else if (wheel.angleDelta.y < 0)
                    root.changeTab(1);

                wheel.accepted = true;
            }
        }
    }
}

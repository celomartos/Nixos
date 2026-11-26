import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../../theme"
import "./modules"

PopupWindow {
    id: root

    required property Item anchorItem

    visible: false
    color: "transparent"

    implicitWidth: 620
    implicitHeight: 420

    // ------------------------------------------------------------
    // Window anchoring
    // ------------------------------------------------------------

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

    // ------------------------------------------------------------
    // Dashboard state
    // ------------------------------------------------------------

    property int currentTab: 0
    property bool animatePageTransition: true

    property real popupYOffset: -28
    property real popupOpacity: 0

    readonly property var tabTitles: ["Calendar", "Media", "System"]

    readonly property var tabIcons: ["", "󰝚", "󰍛"]

    // ------------------------------------------------------------
    // Animations
    // ------------------------------------------------------------

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

    // ------------------------------------------------------------
    // Focus management
    // ------------------------------------------------------------

    Timer {
        id: grabDelay

        interval: 60
        repeat: false

        onTriggered: {
            if (!root.visible || closeAnim.running)
                return;

            outsideGrab.active = true;
            bg.forceActiveFocus();
            focusRetry.running = true;
        }
    }

    Timer {
        id: focusRetry

        interval: 40
        repeat: true
        running: false

        property int attempts: 0

        onRunningChanged: {
            if (running)
                attempts = 0;
        }

        onTriggered: {
            if (!root.visible || closeAnim.running) {
                stop();
            } else if (bg.activeFocus) {
                stop();
            } else if (attempts++ > 15) {
                stop();
            } else {
                bg.forceActiveFocus();
            }
        }
    }

    HyprlandFocusGrab {
        id: outsideGrab

        active: false
        windows: [root]

        onCleared: {
            if (root.visible && !closeAnim.running)
                root.closePopup();
        }
    }

    Shortcut {
        sequence: StandardKey.Cancel
        enabled: root.visible && !closeAnim.running

        onActivated: root.closePopup()
    }

    // ------------------------------------------------------------
    // Navigation
    // ------------------------------------------------------------

    function changeTab(direction) {
        currentTab = Math.max(0, Math.min(2, currentTab + direction));
    }

    // ------------------------------------------------------------
    // Popup controls
    // ------------------------------------------------------------

    function openPopup() {
        grabDelay.stop();
        focusRetry.stop();

        openAnim.stop();
        closeAnim.stop();

        // Always start on Calendar.
        animatePageTransition = false;
        currentTab = 0;

        popupYOffset = -28;
        popupOpacity = 0;

        root.visible = true;

        Qt.callLater(function () {
            root.animatePageTransition = true;
        });

        openAnim.restart();
        grabDelay.restart();
    }

    function closePopup() {
        if (!root.visible || closeAnim.running)
            return;

        grabDelay.stop();
        focusRetry.stop();
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
            focusRetry.stop();
            outsideGrab.active = false;

            openAnim.stop();
            closeAnim.stop();

            popupYOffset = -28;
            popupOpacity = 0;
        }
    }

    // ------------------------------------------------------------
    // Dashboard background
    // ------------------------------------------------------------

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

        // Keyboard navigation
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Left) {
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

            // ----------------------------------------------------
            // Tab bar
            // ----------------------------------------------------

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

            // ----------------------------------------------------
            // Tab indicator
            // ----------------------------------------------------

            Rectangle {
                id: indicator

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

            // ----------------------------------------------------
            // Page container
            // ----------------------------------------------------

            Item {
                id: pageViewport

                width: parent.width
                height: parent.height - tabBar.height - indicator.height - 2 * parent.spacing

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

                            // ------------------------------------
                            // CALENDAR PAGE
                            // ------------------------------------

                            Calendar {
                                anchors.fill: parent

                                visible: index === 0

                                dashboardVisible: root.visible && index === 0
                            }

                            // ------------------------------------
                            // MEDIA PAGE
                            // ------------------------------------

                            Media {
                                anchors.fill: parent

                                visible: index === 1
                            }

                            // ------------------------------------
                            // SYSTEM PAGE
                            // ------------------------------------

                            System {
                                anchors.fill: parent

                                visible: index === 2

                                pageActive: root.visible && root.currentTab === 2 && index === 2
                            }
                        }
                    }
                }
            }
        }

        // --------------------------------------------------------
        // Mouse wheel navigation
        // Does not block hover events from dashboard contents.
        // --------------------------------------------------------

        WheelHandler {
            target: null

            orientation: Qt.Vertical
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

            onWheel: event => {
                if (event.angleDelta.y > 0)
                    root.changeTab(-1);
                else if (event.angleDelta.y < 0)
                    root.changeTab(1);

                event.accepted = true;
            }
        }
    }
}

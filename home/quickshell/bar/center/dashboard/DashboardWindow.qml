import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../../theme"
import "./modules"

Item {
    id: root

    // ============================================================
    // PROPERTIES
    // ============================================================

    implicitWidth: 620
    implicitHeight: 420

    property bool active: false

    signal closeRequested

    readonly property var tabTitles: ["Calendar", "Media", "System"]
    readonly property var tabIcons: ["", "󰝚", "󰍛"]

    readonly property int tabCount: tabTitles.length

    readonly property bool hasFullscreen: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.hasFullscreen : false

    property int currentTab: 0
    property bool animatePageTransition: true

    // ============================================================
    // FULLSCREEN
    // ============================================================

    onHasFullscreenChanged: {
        if (hasFullscreen && active)
            closeRequested();
    }

    // ============================================================
    // LIFECYCLE
    // ============================================================

    onActiveChanged: {
        if (active) {
            animatePageTransition = false;
            currentTab = 0;

            grabDelay.restart();

            Qt.callLater(() => {
                if (root.active)
                    root.animatePageTransition = true;
            });
        } else {
            grabDelay.stop();
            focusRetry.stop();

            outsideGrab.active = false;
        }
    }

    // ============================================================
    // FOCUS MANAGEMENT
    // ============================================================

    Timer {
        id: grabDelay

        interval: 60
        repeat: false

        onTriggered: {
            if (!root.active)
                return;

            outsideGrab.active = true;

            bg.forceActiveFocus();
            focusRetry.start();
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
            if (!root.active) {
                stop();
                return;
            }

            if (bg.activeFocus || attempts >= 15) {
                stop();
                return;
            }

            attempts++;
            bg.forceActiveFocus();
        }
    }

    HyprlandFocusGrab {
        id: outsideGrab

        active: false

        windows: root.QsWindow.window ? [root.QsWindow.window] : []

        onCleared: {
            if (root.active)
                root.closeRequested();
        }
    }

    Shortcut {
        sequence: StandardKey.Cancel
        enabled: root.active

        onActivated: root.closeRequested()
    }

    // ============================================================
    // NAVIGATION
    // ============================================================

    function changeTab(direction) {
        const nextTab = Math.max(0, Math.min(root.tabCount - 1, root.currentTab + direction));

        if (nextTab === root.currentTab)
            return;

        root.currentTab = nextTab;
    }

    // ============================================================
    // DASHBOARD BACKGROUND
    // ============================================================

    Rectangle {
        id: bg

        anchors.fill: parent

        radius: Theme.radiusXl

        color: Theme.background

        border.color: Theme.borderColor
        border.width: 1

        // Square top corners to connect with the bar.
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            height: Theme.radiusXl + 1

            color: Theme.background
        }

        // Restore side borders covered by the top rectangle.
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left

            width: 1
            height: Theme.radiusXl + 1

            color: Theme.borderColor
        }

        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right

            width: 1
            height: Theme.radiusXl + 1

            color: Theme.borderColor
        }

        focus: true

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
            id: content

            anchors.fill: parent
            anchors.margins: 22

            spacing: 18

            // ====================================================
            // TAB BAR
            // ====================================================

            Row {
                id: tabBar

                width: parent.width
                height: 42

                spacing: Theme.spacingSm

                Repeater {
                    model: root.tabCount

                    delegate: Item {
                        required property int index

                        width: (tabBar.width - tabBar.spacing * (root.tabCount - 1)) / root.tabCount
                        height: tabBar.height

                        Rectangle {
                            anchors.fill: parent

                            radius: Theme.radiusMd

                            color: root.currentTab === index ? Theme.hoverBackground : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.animDurationFast
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingSm

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

                            onClicked: {
                                root.currentTab = index;
                            }
                        }
                    }
                }
            }

            // ====================================================
            // TAB INDICATOR
            // ====================================================

            Rectangle {
                id: indicator

                width: parent.width
                height: Theme.borderBottomWidth

                color: Theme.borderColor

                Rectangle {
                    width: parent.width / root.tabCount
                    height: parent.height

                    radius: Theme.radiusPill
                    color: Theme.text

                    x: root.currentTab * width

                    Behavior on x {
                        enabled: root.animatePageTransition

                        NumberAnimation {
                            duration: Theme.animDurationSlow
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // ====================================================
            // PAGE CONTAINER
            // ====================================================

            Item {
                id: pageViewport

                width: parent.width

                height: Math.max(0, parent.height - tabBar.height - indicator.height - 2 * parent.spacing)

                clip: true

                Row {
                    id: pageTrack

                    width: pageViewport.width * root.tabCount
                    height: pageViewport.height

                    x: -root.currentTab * pageViewport.width

                    Behavior on x {
                        enabled: root.animatePageTransition

                        NumberAnimation {
                            duration: Theme.animDurationSlow
                            easing.type: Easing.OutCubic
                        }
                    }

                    // --------------------------------------------
                    // CALENDAR
                    // --------------------------------------------

                    Item {
                        width: pageViewport.width
                        height: pageViewport.height

                        Calendar {
                            anchors.fill: parent

                            dashboardVisible: root.active && root.currentTab === 0
                        }
                    }

                    // --------------------------------------------
                    // MEDIA
                    // --------------------------------------------

                    Item {
                        width: pageViewport.width
                        height: pageViewport.height

                        Media {
                            anchors.fill: parent
                        }
                    }

                    // --------------------------------------------
                    // SYSTEM
                    // --------------------------------------------

                    Item {
                        width: pageViewport.width
                        height: pageViewport.height

                        System {
                            anchors.fill: parent

                            pageActive: root.active && root.currentTab === 2
                        }
                    }
                }
            }
        }

        // ========================================================
        // MOUSE WHEEL NAVIGATION
        // ========================================================

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

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../../theme"
import "../../../components"
import "./modules"

Item {
    id: root

    required property real originX
    required property real originY

    anchors.fill: parent

    // Intent drives input/focus; visual visibility remains true until the
    // reveal animation reaches zero. Closing never changes intent back to open.
    readonly property bool popupVisible: reveal.visible
    readonly property Item interactiveArea: popupVisible ? reveal : null
    readonly property bool isInteractive: openRequested && popupVisible
    property bool openRequested: false
    property int openGeneration: 0

    signal inputRegionChanged

    // ------------------------------------------------------------
    // Dashboard state
    // ------------------------------------------------------------

    readonly property var tabTitles: ["Calendar", "Media", "System"]

    readonly property var tabIcons: ["", "󰝚", "󰍛"]

    readonly property int tabCount: tabTitles.length

    readonly property bool hasFullscreen: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.hasFullscreen : false

    property int currentTab: 0
    property bool animatePageTransition: true

    // ------------------------------------------------------------
    // Fullscreen handling
    // ------------------------------------------------------------

    onHasFullscreenChanged: {
        if (hasFullscreen && openRequested)
            closePopup();
    }

    // ------------------------------------------------------------
    // Focus management
    // ------------------------------------------------------------

    Timer {
        id: grabDelay
        interval: 60
        repeat: false
        property int generation: -1

        onTriggered: {
            if (!root.isInteractive || generation !== root.openGeneration)
                return;
            outsideGrab.active = true;
            bg.forceActiveFocus();
            if (!bg.activeFocus)
                focusRetry.restart();
        }
    }

    Timer {
        id: focusRetry
        interval: 40
        repeat: true
        property int attempts: 0
        property int generation: -1

        onTriggered: {
            if (!root.isInteractive || generation !== root.openGeneration || attempts >= 15) {
                stop();
                return;
            }
            if (bg.activeFocus) {
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
        windows: [root.QsWindow.window]

        onCleared: {
            if (root.isInteractive)
                root.closePopup();
        }
    }

    Shortcut {
        sequences: [StandardKey.Cancel]
        enabled: root.isInteractive
        onActivated: root.closePopup()
    }

    // ------------------------------------------------------------
    // Navigation
    // ------------------------------------------------------------

    function changeTab(direction) {
        const nextTab = Math.max(0, Math.min(root.tabCount - 1, root.currentTab + direction));

        if (nextTab === root.currentTab)
            return;
        root.currentTab = nextTab;
    }

    // ------------------------------------------------------------
    // Popup controls
    // ------------------------------------------------------------

    function openPopup() {
        if (root.hasFullscreen || root.popupVisible)
            return;

        // Always start on Calendar.
        animatePageTransition = false;
        currentTab = 0;
        const generation = ++root.openGeneration;
        root.openRequested = true;

        Qt.callLater(() => {
            if (!root.isInteractive || generation !== root.openGeneration)
                return;
            bg.forceActiveFocus();
            root.animatePageTransition = true;
            grabDelay.generation = generation;
            focusRetry.generation = generation;
            focusRetry.attempts = 0;
            grabDelay.restart();
        });
    }

    function closePopup() {
        if (!root.openRequested)
            return;
        root.openGeneration++;
        grabDelay.stop();
        focusRetry.stop();
        outsideGrab.active = false;
        root.openRequested = false;
    }

    function toggle() {
        if (root.popupVisible) {
            if (root.openRequested)
                closePopup();
            return;
        }

        openPopup();
    }

    // ------------------------------------------------------------
    // Animated, clipped dashboard surface
    // ------------------------------------------------------------

    PopupReveal {
        id: reveal

        originX: root.originX
        originY: root.originY
        contentWidth: 620
        contentHeight: 420
        expanded: root.openRequested

        onRevealGeometryChanged: root.inputRegionChanged()

        Rectangle {
            id: bg

            anchors.fill: parent

            radius: Theme.radiusXl

            color: Theme.background

            border.color: Theme.borderColor
            border.width: 1

            enabled: root.isInteractive
            focus: root.isInteractive

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
            id: content

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

            // ----------------------------------------------------
            // Tab indicator
            // ----------------------------------------------------

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

            // ----------------------------------------------------
            // Page container
            // ----------------------------------------------------

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

                            dashboardVisible: root.popupVisible && root.currentTab === 0
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

                            pageActive: root.popupVisible && root.currentTab === 2
                        }
                    }
                }
            }
        }

        // --------------------------------------------------------
        // Mouse wheel navigation
        // --------------------------------------------------------

        WheelHandler {
            target: null
            enabled: root.isInteractive

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
}

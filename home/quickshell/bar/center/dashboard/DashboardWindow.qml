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

    anchor.adjustment: PopupAdjustment.FlipY | PopupAdjustment.SlideX | PopupAdjustment.ResizeY

    anchor.onAnchoring: {
        const item = root.anchorItem;
        const parentWindow = item ? item.QsWindow.window : null;

        if (!parentWindow || !parentWindow.contentItem)
            return;
        const pos = item.mapToItem(parentWindow.contentItem, 0, 0);

        anchor.rect.x = Math.round(pos.x + (item.width - root.width) / 2);

        anchor.rect.y = Math.round(pos.y + item.height);

        anchor.rect.width = 1;
        anchor.rect.height = 1;
    }

    // ------------------------------------------------------------
    // Dashboard state
    // ------------------------------------------------------------

    readonly property var tabTitles: ["Calendar", "Media", "System"]

    readonly property var tabIcons: ["", "󰝚", "󰍛"]

    readonly property int tabCount: tabTitles.length

    readonly property bool hasFullscreen: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.hasFullscreen : false

    property int currentTab: 0
    property bool animatePageTransition: true

    property real popupYOffset: -28
    property real popupOpacity: 0

    // ------------------------------------------------------------
    // Fullscreen handling
    // ------------------------------------------------------------

    onHasFullscreenChanged: {
        if (hasFullscreen && visible)
            closePopup();
    }

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

            duration: Theme.animDurationNormal
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "popupOpacity"

            from: 0
            to: 1

            duration: Theme.animDurationNormal
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

            duration: Theme.animDurationFast
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: root
            property: "popupOpacity"

            from: 1
            to: 0

            duration: Theme.animDurationFast
            easing.type: Easing.InQuad
        }

        onFinished: {
            root.visible = false;
        }
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
            if (!root.visible || closeAnim.running) {
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
        const nextTab = Math.max(0, Math.min(root.tabCount - 1, root.currentTab + direction));

        if (nextTab === root.currentTab)
            return;
        root.currentTab = nextTab;
    }

    // ------------------------------------------------------------
    // Popup controls
    // ------------------------------------------------------------

    function openPopup() {
        if (root.hasFullscreen)
            return;
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

        Qt.callLater(() => {
            if (root.visible && !closeAnim.running)
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

    // ------------------------------------------------------------
    // Visibility
    // ------------------------------------------------------------

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

        radius: Theme.radiusXl

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

                            dashboardVisible: root.visible && root.currentTab === 0
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

                            pageActive: root.visible && root.currentTab === 2
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

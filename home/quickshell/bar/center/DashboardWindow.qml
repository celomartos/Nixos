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
        if (!root.anchorItem ||
            !root.anchorItem.QsWindow ||
            !root.anchorItem.QsWindow.window) {
            return;
        }

        const window = root.anchorItem.QsWindow.window;
        const pos = root.anchorItem.mapToItem(window.contentItem, 0, 0);

        anchor.rect.x = pos.x + (root.anchorItem.width - root.width) / 2;
        anchor.rect.y = pos.y + root.anchorItem.height;
        anchor.rect.width = 1;
        anchor.rect.height = 1;
    }

    property int currentTab: 0
    property real popupYOffset: -28
    property real popupOpacity: 0

    readonly property var tabs: [
        { title: "Geral", icon: "󰋜" },
        { title: "Mídia", icon: "󰝚" },
        { title: "Sistema", icon: "󰍛" }
    ]

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

    function openPopup() {
        grabDelay.stop();
        openAnim.stop();
        closeAnim.stop();

        currentTab = 0;
        popupYOffset = -28;
        popupOpacity = 0;

        root.visible = true;
        openAnim.restart();
        grabDelay.restart();
    }

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
                root.currentTab = Math.max(0, root.currentTab - 1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                root.currentTab = Math.min(root.tabs.length - 1, root.currentTab + 1);
                event.accepted = true;
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 18

            Row {
                id: tabBar
                width: parent.width
                height: 42
                spacing: 8

                Repeater {
                    model: root.tabs

                    delegate: Item {
                        required property int index
                        required property var modelData

                        width: (tabBar.width - 16) / 3
                        height: tabBar.height

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: root.currentTab === index
                                ? Theme.hoverBackground
                                : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: 140; easing.type: Easing.OutCubic }
                            }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: modelData.icon
                                color: root.currentTab === index ? Theme.text : Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: modelData.title
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
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

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
                        NumberAnimation {
                            duration: 280
                            easing.type: Easing.OutCubic
                        }
                    }

                    Repeater {
                        model: root.tabs

                        delegate: Item {
                            required property int index
                            required property var modelData

                            width: pageViewport.width
                            height: pageViewport.height

                            Column {
                                anchors.centerIn: parent
                                spacing: 10

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: ["󰋜", "󰝚", "󰍛"][index]
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 34
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.title
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeLarge
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Conteúdo será implementado nesta etapa."
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
    }
}

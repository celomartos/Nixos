import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../theme"

PanelWindow {
    id: root

    visible: false
    color: "transparent"

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:powermenu"

    property int selectedIndex: 0
    property bool isHolding: false
    property real holdProgress: 0.0
    property string holdActionId: ""
    readonly property int holdDurationMs: 900

    property bool canHibernate: false
    property bool canSuspend: true
    property bool canReboot: true
    property bool canPowerOff: true

    property Item anchorItem: null
    property real cardTargetX: 0
    property real cardTargetY: 0

    function updatePosition() {
        if (!anchorItem || !anchorItem.QsWindow || !anchorItem.QsWindow.window) {
            return;
        }

        const window = anchorItem.QsWindow.window;
        const pos = anchorItem.mapToItem(
            window.contentItem,
            0,
            0
        );

        root.cardTargetX = pos.x + anchorItem.width - menuCard.width;
        root.cardTargetY = pos.y + anchorItem.height - 35;
    }

    property real cardYOffset: -28
    property real cardOpacity: 0.0

    ParallelAnimation {
        id: openAnim

        NumberAnimation {
            target: root
            property: "cardYOffset"
            from: -28
            to: 0
            duration: 180
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "cardOpacity"
            from: 0.0
            to: 1.0
            duration: 180
            easing.type: Easing.OutQuad
        }
    }

    ParallelAnimation {
        id: closeAnim

        NumberAnimation {
            target: root
            property: "cardYOffset"
            from: 0
            to: -20
            duration: 120
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: root
            property: "cardOpacity"
            from: 1.0
            to: 0.0
            duration: 120
            easing.type: Easing.InQuad
        }

        onFinished: {
            root.visible = false;
        }
    }

    readonly property var allActions: [
        {
            id: "logout",
            label: "Encerrar sessão",
            desc: "Finaliza a sessão do Hyprland",
            icon: "󰍃",
            key: "E",
            altKeys: ["Q"],
            dangerous: true,
            command: ["sh", "-c", "hyprctl dispatch exit 2>/dev/null || loginctl terminate-session ${XDG_SESSION_ID:-self}"]
        },
        {
            id: "reboot",
            label: "Reiniciar",
            desc: "Reinicia o sistema operacional",
            icon: "",
            key: "R",
            altKeys: [],
            dangerous: true,
            command: ["systemctl", "reboot"]
        },
        {
            id: "poweroff",
            label: "Desligar",
            desc: "Desliga o computador completamente",
            icon: "",
            key: "D",
            altKeys: ["P"],
            dangerous: true,
            command: ["systemctl", "poweroff"]
        }
    ]

    property var visibleActions: []

    function updateVisibleActions() {
        var filtered = [];
        for (var i = 0; i < allActions.length; i++) {
            var action = allActions[i];
            if (action.id === "hibernate") {
                if (root.canHibernate) filtered.push(action);
            } else if (action.id === "suspend") {
                if (root.canSuspend) filtered.push(action);
            } else if (action.id === "reboot") {
                if (root.canReboot) filtered.push(action);
            } else if (action.id === "poweroff") {
                if (root.canPowerOff) filtered.push(action);
            } else {
                filtered.push(action);
            }
        }
        root.visibleActions = filtered;
        if (root.selectedIndex >= root.visibleActions.length) {
            root.selectedIndex = Math.max(0, root.visibleActions.length - 1);
        }
    }

    Component.onCompleted: {
        updateVisibleActions();
    }

    onVisibleChanged: {
        if (!visible) {
            cancelHold();
            openAnim.stop();
            closeAnim.stop();
            cardYOffset = -28;
            cardOpacity = 0.0;
        } else {
            updatePosition();
            probeProcess.running = true;
            selectedIndex = 0;
            Qt.callLater(() => {
                keyHandler.forceActiveFocus();
            });
        }
    }

    Process {
        id: probeProcess
        command: ["sh", "-c", "hib=$(busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanHibernate 2>/dev/null | awk '{print $2}' | tr -d '\"'); sus=$(busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanSuspend 2>/dev/null | awk '{print $2}' | tr -d '\"'); reb=$(busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanReboot 2>/dev/null | awk '{print $2}' | tr -d '\"'); pwr=$(busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanPowerOff 2>/dev/null | awk '{print $2}' | tr -d '\"'); printf 'hibernate=%s\\nsuspend=%s\\nreboot=%s\\npoweroff=%s\\n' \"$hib\" \"$sus\" \"$reb\" \"$pwr\""]
        running: true

        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return;
                var lines = text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split("=");
                    if (parts.length === 2) {
                        var k = parts[0].trim();
                        var v = parts[1].trim();
                        if (k === "hibernate") root.canHibernate = (v === "yes");
                        else if (k === "suspend") root.canSuspend = (v === "yes");
                        else if (k === "reboot") root.canReboot = (v === "yes");
                        else if (k === "poweroff") root.canPowerOff = (v === "yes");
                    }
                }
                root.updateVisibleActions();
            }
        }
    }

    Process {
        id: execProcess
        running: false
    }

    function executeAction(action) {
        if (!action) return;
        close();
        execProcess.command = action.command;
        execProcess.running = true;
    }

    Timer {
        id: holdTimer
        interval: 16
        repeat: true
        running: false

        onTriggered: {
            root.holdProgress = Math.min(1.0, root.holdProgress + (16 / root.holdDurationMs));
            if (root.holdProgress >= 1.0) {
                stop();
                root.completeHold();
            }
        }
    }

    function startHold(action) {
        if (!action) return;
        if (!action.dangerous) {
            executeAction(action);
            return;
        }
        root.holdActionId = action.id;
        root.holdProgress = 0.0;
        root.isHolding = true;
        holdTimer.start();
    }

    function cancelHold() {
        holdTimer.stop();
        root.isHolding = false;
        root.holdProgress = 0.0;
        root.holdActionId = "";
    }

    function completeHold() {
        holdTimer.stop();
        var currentAction = getCurrentAction();
        root.isHolding = false;
        root.holdProgress = 0.0;
        root.holdActionId = "";
        if (currentAction) {
            executeAction(currentAction);
        }
    }

    function getCurrentAction() {
        if (root.selectedIndex >= 0 && root.selectedIndex < root.visibleActions.length) {
            return root.visibleActions[root.selectedIndex];
        }
        return null;
    }

    function open() {
        updatePosition();
        closeAnim.stop();
        probeProcess.running = true;
        cancelHold();
        root.selectedIndex = 0;
        root.cardYOffset = -28;
        root.cardOpacity = 0.0;
        root.visible = true;
        openAnim.restart();
        Qt.callLater(() => {
            keyHandler.forceActiveFocus();
        });
    }

    function close() {
        cancelHold();
        if (!root.visible || closeAnim.running) {
            return;
        }
        openAnim.stop();
        closeAnim.restart();
    }

    function toggle() {
        if (root.visible && !closeAnim.running) {
            close();
        } else {
            open();
        }
    }

    // Transparent click-catcher - clicking outside closes the menu without darkening the screen
    MouseArea {
        id: dismissArea
        anchors.fill: parent
        onClicked: root.close()
    }

    // Main menu card anchored to power module
    Rectangle {
        id: menuCard

        x: root.cardTargetX
        y: root.cardTargetY
        width: 340

        implicitHeight: cardColumn.implicitHeight + 28
        color: Theme.background
        border.color: Theme.borderColor
        border.width: 1
        radius: 16
        clip: true

        opacity: root.cardOpacity
        transform: Translate {
            y: root.cardYOffset
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        Column {
            id: cardColumn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 14
            spacing: 10

            // Header
            Row {
                width: parent.width
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    color: Theme.text
                    text: "⏻"
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: Theme.text
                    text: "Menu de Energia"
                }

                Item {
                    id: headerSpacer
                    width: parent.width - 24 - 150 - closeBadge.width
                    height: 1
                }

                Rectangle {
                    id: closeBadge
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 22
                    radius: 6
                    color: Qt.rgba(1, 1, 1, 0.06)
                    border.color: Theme.borderColor
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.textMuted
                        text: "Esc"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }

            // Divider
            Rectangle {
                width: parent.width
                height: 1
                color: Theme.borderColor
            }

            // Actions list
            Column {
                id: actionsColumn
                width: parent.width
                spacing: 4

                Repeater {
                    model: root.visibleActions

                    delegate: PowerMenuItem {
                        required property var modelData
                        required property int index

                        actionData: modelData
                        isSelected: (index === root.selectedIndex)
                        isHolding: (root.isHolding && root.holdActionId === modelData.id)
                        holdProgress: root.holdProgress

                        onHovered: {
                            root.selectedIndex = index;
                        }

                        onItemPressed: {
                            root.selectedIndex = index;
                            root.startHold(modelData);
                        }

                        onItemReleased: {
                            root.cancelHold();
                        }

                        onItemClicked: {
                            if (!modelData.dangerous) {
                                root.executeAction(modelData);
                            }
                        }
                    }
                }
            }

            // Hint / Status bar
            Rectangle {
                id: hintBar
                width: parent.width
                height: 32
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.04)
                border.color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: root.isHolding ? Theme.textDanger : Theme.textMuted
                        text: {
                            if (root.isHolding) return "󰔟";
                            var cur = root.getCurrentAction();
                            if (cur && cur.dangerous) return "";
                            return "󰌌";
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: root.isHolding ? Font.Bold : Font.Normal
                        color: root.isHolding ? Theme.textDanger : Theme.textMuted
                        text: {
                            if (root.isHolding) {
                                return "Confirmando... " + Math.round(root.holdProgress * 100) + "%";
                            }
                            var cur = root.getCurrentAction();
                            if (cur && cur.dangerous) {
                                return "Mantenha pressionado para confirmar";
                            }
                            return "Pressione para executar imediatamente";
                        }
                    }
                }
            }
        }

        // Bottom progress indicator bar
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            height: 3
            width: parent.width * root.holdProgress
            color: Theme.textDanger
            visible: root.isHolding
        }
    }

    Item {
        id: keyHandler
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.close();
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || event.key === Qt.Key_K) {
                if (root.visibleActions.length > 0) {
                    root.selectedIndex = (root.selectedIndex - 1 + root.visibleActions.length) % root.visibleActions.length;
                }
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || event.key === Qt.Key_J) {
                if (root.visibleActions.length > 0) {
                    root.selectedIndex = (root.selectedIndex + 1) % root.visibleActions.length;
                }
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                if (event.isAutoRepeat) {
                    event.accepted = true;
                    return;
                }
                var curAction = root.getCurrentAction();
                if (curAction) {
                    if (curAction.dangerous) {
                        root.startHold(curAction);
                    } else {
                        root.executeAction(curAction);
                    }
                }
                event.accepted = true;
                return;
            }

            // Shortcut keys matching
            var keyChar = (event.text || "").toUpperCase();
            if (keyChar.length > 0 && !event.isAutoRepeat) {
                for (var i = 0; i < root.visibleActions.length; i++) {
                    var act = root.visibleActions[i];
                    var matches = (act.key === keyChar);
                    if (!matches && act.altKeys) {
                        for (var k = 0; k < act.altKeys.length; k++) {
                            if (act.altKeys[k] === keyChar) {
                                matches = true;
                                break;
                            }
                        }
                    }
                    if (matches) {
                        root.selectedIndex = i;
                        if (act.dangerous) {
                            root.startHold(act);
                        } else {
                            root.executeAction(act);
                        }
                        event.accepted = true;
                        return;
                    }
                }
            }
        }

        Keys.onReleased: event => {
            if (event.isAutoRepeat) return;
            if (root.isHolding) {
                root.cancelHold();
                event.accepted = true;
            }
        }
    }
}

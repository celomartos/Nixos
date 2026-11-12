import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"

PopupWindow {
    id: root

    visible: false
    color: "transparent"

    implicitWidth: 220
    implicitHeight: cardColumn.implicitHeight + 28

    grabFocus: true

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

    // Anchoring relative to the power module, following CalendarPopup.
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

        anchor.rect.x = pos.x + root.anchorItem.width - root.width;
        anchor.rect.y = pos.y + root.anchorItem.height

        anchor.rect.width = 1;
        anchor.rect.height = 1;
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
            label: "Exit",
            icon: "󰍃",
            key: "E",
            altKeys: ["Q"],
            dangerous: true,
            command: [
                "sh",
                "-c",
                "hyprctl dispatch exit 2>/dev/null || loginctl terminate-session ${XDG_SESSION_ID:-self}"
            ]
        },
        {
            id: "reboot",
            label: "Reboot",
            icon: "",
            key: "R",
            altKeys: [],
            dangerous: true,
            command: ["systemctl", "reboot"]
        },
        {
            id: "poweroff",
            label: "Shutdown",
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

            if (action.id === "reboot") {
                if (root.canReboot)
                    filtered.push(action);
            } else if (action.id === "poweroff") {
                if (root.canPowerOff)
                    filtered.push(action);
            } else {
                filtered.push(action);
            }
        }

        root.visibleActions = filtered;

        if (root.selectedIndex >= root.visibleActions.length) {
            root.selectedIndex = Math.max(
                0,
                root.visibleActions.length - 1
            );
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
            probeProcess.running = true;
            selectedIndex = 0;

            Qt.callLater(() => {
                keyHandler.forceActiveFocus();
            });
        }
    }

    Process {
        id: probeProcess

        command: [
            "sh",
            "-c",
            "hib=$(busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanHibernate 2>/dev/null | awk '{print $2}' | tr -d '\"'); sus=$(busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanSuspend 2>/dev/null | awk '{print $2}' | tr -d '\"'); reb=$(busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanReboot 2>/dev/null | awk '{print $2}' | tr -d '\"'); pwr=$(busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanPowerOff 2>/dev/null | awk '{print $2}' | tr -d '\"'); printf 'hibernate=%s\\nsuspend=%s\\nreboot=%s\\npoweroff=%s\\n' \"$hib\" \"$sus\" \"$reb\" \"$pwr\""
        ]

        running: true

        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0)
                    return;

                var lines = text.trim().split("\n");

                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split("=");

                    if (parts.length === 2) {
                        var k = parts[0].trim();
                        var v = parts[1].trim();

                        if (k === "hibernate")
                            root.canHibernate = (v === "yes");
                        else if (k === "suspend")
                            root.canSuspend = (v === "yes");
                        else if (k === "reboot")
                            root.canReboot = (v === "yes");
                        else if (k === "poweroff")
                            root.canPowerOff = (v === "yes");
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
        if (!action)
            return;

        close();

        execProcess.command = action.command;
        execProcess.running = true;
    }

    // Lógica do Hold
    Timer {
        id: holdTimer

        interval: 16
        repeat: true
        running: false

        onTriggered: {
            root.holdProgress = Math.min(
                1.0,
                root.holdProgress + (16 / root.holdDurationMs)
            );

            if (root.holdProgress >= 1.0) {
                stop();
                root.completeHold();
            }
        }
    }

    function startHold(action) {
        if (!action)
            return;

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
        if (
            root.selectedIndex >= 0 &&
            root.selectedIndex < root.visibleActions.length
        ) {
            return root.visibleActions[root.selectedIndex];
        }

        return null;
    }

    function open() {
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

        if (!root.visible || closeAnim.running)
            return;

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

    // Main menu card
    Rectangle {
        id: menuCard

        anchors.fill: parent

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

            // Actions list
            Column {
                id: actionsColumn
                width: parent.width

                Repeater {
                    model: root.visibleActions

                    delegate: Column {
                        required property var modelData
                        required property int index
                        width: parent.width

                        PowerMenuItem {
                            width: parent.width
                            actionData: modelData

                            isSelected: (index === root.selectedIndex)
                            isHolding: (
                                root.isHolding &&
                                root.holdActionId === modelData.id
                            )
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

                            onItemClicked: {} 
                        }

                        // Separação entre as opções (Agora visível)
                        Item {
                            width: parent.width
                            height: 12 // Mais espaço vertical
                            visible: index < root.visibleActions.length - 1

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - 16 // Margem lateral menor (linha mais larga)
                                height: 1
                                color: Qt.rgba(1, 1, 1, 0.25) // Opacidade de 15% (antes era 0.08)
                            }
                        }
                    }
                }
            }
        }
    }

    // Keyboard handler
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

            if (
                event.key === Qt.Key_Up ||
                event.key === Qt.Key_Backtab ||
                event.key === Qt.Key_K
            ) {
                if (root.visibleActions.length > 0) {
                    root.selectedIndex = (
                        root.selectedIndex - 1 +
                        root.visibleActions.length
                    ) % root.visibleActions.length;
                }

                event.accepted = true;
                return;
            }

            if (
                event.key === Qt.Key_Down ||
                event.key === Qt.Key_Tab ||
                event.key === Qt.Key_J
            ) {
                if (root.visibleActions.length > 0) {
                    root.selectedIndex = (
                        root.selectedIndex + 1
                    ) % root.visibleActions.length;
                }

                event.accepted = true;
                return;
            }

            if (
                event.key === Qt.Key_Return ||
                event.key === Qt.Key_Enter ||
                event.key === Qt.Key_Space
            ) {
                if (event.isAutoRepeat) {
                    event.accepted = true;
                    return;
                }

                var curAction = root.getCurrentAction();

                if (curAction) {
                    root.startHold(curAction);
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
                        root.startHold(act);

                        event.accepted = true;
                        return;
                    }
                }
            }
        }

        Keys.onReleased: event => {
            if (event.isAutoRepeat)
                return;

            if (root.isHolding) {
                root.cancelHold();
                event.accepted = true;
            }
        }
    }
}

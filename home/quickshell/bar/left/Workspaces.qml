
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../theme"

Item {
    id: root

    implicitHeight: Theme.barHeight
    implicitWidth: wsRow.implicitWidth + 8

    function getWorkspace(id) {
        const workspaces = Hyprland.workspaces.values;

        for (const workspace of workspaces) {
            if (workspace.id === id)
                return workspace;
        }

        return null;
    }

    function normalizeAppId(value) {
        return String(value || "")
            .toLowerCase()
            .replace(/\.desktop$/, "")
            .replace(/[-_.\s]/g, "");
    }

    function getAppIcon(win) {
        const ipc = win.lastIpcObject;
        const appClass = String(ipc?.class || ipc?.initialClass || "");

        if (!appClass)
            return "";

        try {
            let entry = DesktopEntries.heuristicLookup(appClass);

            if (!entry?.icon) {
                const target = normalizeAppId(appClass);
                const applications = DesktopEntries.applications.values;

                for (const app of applications) {
                    const identifiers = [
                        app.startupClass,
                        app.id
                    ];

                    if (identifiers.some(
                        value => value &&
                            normalizeAppId(value) === target
                    )) {
                        entry = app;
                        break;
                    }
                }
            }

            const icon = entry?.icon || appClass.toLowerCase();

            return Quickshell.iconPath(icon, true);
        } catch (error) {
            console.warn("Erro ao localizar ícone:", appClass, error);
            return "";
        }
    }

Connections {
    target: Hyprland

    function onRawEvent(event) {
        switch (event.name) {
        case "openwindow":
            Hyprland.refreshToplevels();
            break;

        case "movewindow":
            Hyprland.refreshToplevels();
            Hyprland.refreshWorkspaces();
            break;
        }
    }
}
    Row {
        id: wsRow

        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
            model: 5

            delegate: Rectangle {
                id: wsButton

                required property int index

                readonly property int wsId: index + 1
                readonly property var ws: root.getWorkspace(wsId)

                readonly property bool isFocused:
                    Hyprland.focusedWorkspace?.id === wsId

                readonly property bool isUrgent:
                    ws?.urgent ?? false

                readonly property int windowCount:
                    ws ? ws.toplevels.values.length : 0

                readonly property bool hovered:
                    mouseArea.containsMouse

                implicitHeight: Theme.barHeight - 6
                implicitWidth: labelRow.implicitWidth + 16

                radius: 10

                color: (isFocused || isUrgent || hovered)
                    ? Theme.hoverBackground
                    : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: 100
                    }
                }

                Row {
                    id: labelRow

                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.weight: Theme.fontWeight

                        color: Theme.text

                        text: (isFocused || isUrgent)
                            ? ""
                            : ""
                    }

                    Repeater {
                        model: ws ? ws.toplevels.values : []

                        delegate: Image {
                            required property var modelData

                            anchors.verticalCenter: parent.verticalCenter

                            width: 18
                            height: 18

                            source: root.getAppIcon(modelData)
                            sourceSize: Qt.size(36, 36)

                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true

                            visible: status === Image.Ready
                        }
                    }
                }

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        Hyprland.dispatch(
                            "hl.dsp.focus({ workspace = " + wsId + " })"
                        );
                    }
                }
            }
        }
    }
}


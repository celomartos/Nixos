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
        return String(value || "").toLowerCase().replace(/\.desktop$/, "").replace(/[-_.\s]/g, "");
    }

    // Retorna as classes da janela, priorizando initialClass.
    function getWindowClasses(win) {
        const ipc = win?.lastIpcObject;

        const initialClass = String(ipc?.initialClass || "");
        const appClass = String(ipc?.class || "");

        const classes = [];

        if (initialClass)
            classes.push(initialClass);

        if (appClass && appClass !== initialClass)
            classes.push(appClass);

        return classes;
    }

    // Identifica o aplicativo para evitar ícones duplicados.
    function getAppKey(win) {
        const appClasses = getWindowClasses(win);

        if (appClasses.length === 0)
            return "";

        const normalizedClasses = appClasses.map(value => normalizeAppId(value)).filter(value => value);

        // Unifica as possíveis identificações do Thunar.
        if (normalizedClasses.some(value => value === "thunar" || value === "orgxfcethunar")) {
            return "thunar";
        }

        // Procura correspondências exatas nos desktop entries.
        const applications = DesktopEntries.applications.values;

        for (const appClass of appClasses) {
            const target = normalizeAppId(appClass);

            if (!target)
                continue;

            for (const app of applications) {
                const startupClass = normalizeAppId(app.startupClass);
                const appId = normalizeAppId(app.id);

                if (target === startupClass || target === appId) {
                    return startupClass || appId || target;
                }
            }
        }

        // Utiliza a classe original caso não encontre correspondência.
        return normalizedClasses[0] || "";
    }

    // Retorna somente uma janela por aplicativo.
    function getUniqueToplevels(workspace) {
        if (!workspace)
            return [];

        const windows = workspace.toplevels.values;

        const result = [];
        const seen = [];

        for (const win of windows) {
            const key = getAppKey(win);

            // Não agrupa janelas sem identificação.
            if (!key) {
                result.push(win);
                continue;
            }

            // Ignora aplicativos que já possuem um ícone.
            if (seen.indexOf(key) !== -1)
                continue;

            seen.push(key);
            result.push(win);
        }

        return result;
    }

    function getAppIcon(win) {
        const appClasses = getWindowClasses(win);

        if (appClasses.length === 0)
            return "";

        try {
            const normalizedClasses = appClasses.map(value => normalizeAppId(value));

            // Identificação direta do ícone do Thunar.
            const isThunar = normalizedClasses.some(value => value === "thunar" || value === "orgxfcethunar");

            if (isThunar) {
                return Quickshell.iconPath("org.xfce.thunar", "system-file-manager");
            }

            const applications = DesktopEntries.applications.values;

            let entry = null;

            // Primeiro tenta encontrar correspondências exatas.
            for (const appClass of appClasses) {
                const target = normalizeAppId(appClass);

                for (const app of applications) {
                    const identifiers = [app.startupClass, app.id];

                    const matches = identifiers.some(value => value && normalizeAppId(value) === target);

                    if (matches) {
                        entry = app;
                        break;
                    }
                }

                if (entry?.icon)
                    break;
            }

            // Utiliza a busca heurística como alternativa.
            if (!entry?.icon) {
                entry = null;

                for (const appClass of appClasses) {
                    const candidate = DesktopEntries.heuristicLookup(appClass);

                    if (candidate?.icon) {
                        entry = candidate;
                        break;
                    }
                }
            }

            const icon = entry?.icon || appClasses[0].toLowerCase();

            return Quickshell.iconPath(icon, true);
        } catch (error) {
            console.warn("Erro ao localizar ícone:", appClasses[0], error);

            return "";
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            switch (event.name) {
            case "openwindow":
            case "closewindow":
            case "movewindow":
            case "movewindowv2":
                Hyprland.refreshWorkspaces();
                Hyprland.refreshToplevels();
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

                readonly property bool isFocused: Hyprland.focusedWorkspace?.id === wsId

                readonly property bool isUrgent: ws?.urgent ?? false

                readonly property int windowCount: ws ? ws.toplevels.values.length : 0

                readonly property bool hovered: mouseArea.containsMouse

                implicitHeight: Theme.barHeight - 6
                implicitWidth: labelRow.implicitWidth + 12

                radius: 10

                color: (isFocused || isUrgent || hovered) ? Theme.hoverBackground : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animDuration
                    }
                }

                Row {
                    id: labelRow

                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: Theme.iconVerticalOffset

                        renderType: Theme.textRenderType
                        renderTypeQuality: Theme.textRenderQuality
                        font.hintingPreference: Theme.fontHinting

                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.weight: Theme.fontWeight

                        color: Theme.text

                        text: (isFocused || isUrgent) ? "" : ""
                    }

                    Repeater {
                        model: root.getUniqueToplevels(ws)

                        delegate: Image {
                            required property var modelData

                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: -1

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
                        Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsId + " })");
                    }
                }
            }
        }
    }
}

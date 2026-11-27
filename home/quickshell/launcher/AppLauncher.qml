import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import "../theme"

PanelWindow {
    id: root

    visible: false
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    readonly property bool fullscreenActive: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.hasFullscreen : false

    margins {
        top: 34
    }

    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-app-launcher"

    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // --------------------------------------------------
    // CONFIGURAÇÕES
    // --------------------------------------------------

    readonly property var excludedCategories: ["Settings", "System", "AudioVideo", "Audio"]

    readonly property var launcherCategories: [
        {
            id: "all",
            label: "Todos",
            desktopCategories: []
        },
        {
            id: "games",
            label: "🎮 Jogos",
            desktopCategories: ["Game"]
        },
        {
            id: "development",
            label: "💻 Desenvolvimento",
            desktopCategories: ["Development", "IDE", "TextEditor"]
        },
        {
            id: "settings",
            label: "⚙️ Configurações",
            desktopCategories: ["Settings"]
        },
        {
            id: "internet",
            label: "🌐 Internet",
            desktopCategories: ["Network", "WebBrowser"]
        },
        {
            id: "accessories",
            label: "📁 Acessórios",
            desktopCategories: ["Utility", "Accessories"]
        },
        {
            id: "graphics",
            label: "🎨 Gráficos",
            desktopCategories: ["Graphics", "Image", "Photo"]
        }
    ]

    property string selectedCategoryId: "all"

    // --------------------------------------------------
    // PAGINAÇÃO HORIZONTAL
    // --------------------------------------------------

    readonly property int columnsPerPage: 6
    readonly property int appCellHeight: 156

    readonly property int rowsPerPage: Math.max(1, Math.floor(appGrid.height / appCellHeight))

    readonly property int itemsPerPage: columnsPerPage * rowsPerPage

    readonly property int pageCount: Math.ceil(filteredApplications.length / itemsPerPage)

    property int selectedApplicationIndex: -1
    property int currentPage: 0

    // Posição lógica do seletor, preservada entre páginas.
    property int navigationRow: 0
    property int navigationColumn: 0
    property int navigationRepeatInterval: 50
    property double lastNavigationAcceptedAt: 0

    property real wheelAccumulator: 0

    property bool animatePageTransitions: true

    // Alterna entre navegação por teclado e mouse.
    property bool keyboardNavigationActive: false
    property point keyboardModePointerOrigin: Qt.point(-1, -1)
    readonly property real pointerResumeDistance: 8

    property int refreshGeneration: 0

    // Destino atual da animação.
    readonly property real targetPageX: {
        if (appGrid.width <= 0)
            return 0;

        const maxX = Math.max(0, appGrid.contentWidth - appGrid.width);

        return Math.max(0, Math.min(currentPage * appGrid.width, maxX));
    }

    // Detecta se a grade ainda está em movimento.
    readonly property bool pageTransitionActive: Math.abs(appGrid.contentX - targetPageX) > 1

    SearchModel {
        id: searchModel
        applications: DesktopEntries.applications.values
        categories: root.launcherCategories
        excludedCategories: root.excludedCategories
        categoryId: root.selectedCategoryId
        queryText: searchInput.text
    }

    readonly property var filteredApplications: searchModel.filteredApplications

    // --------------------------------------------------
    // ORGANIZAÇÃO DOS APLICATIVOS POR PÁGINA
    // --------------------------------------------------

    readonly property var pagedApplications: {
        const source = root.filteredApplications;
        const rows = root.rowsPerPage;
        const columns = root.columnsPerPage;
        const pageSize = root.itemsPerPage;

        const result = [];

        for (let page = 0; page < root.pageCount; page++) {
            for (let column = 0; column < columns; column++) {
                for (let row = 0; row < rows; row++) {
                    const sourceIndex = page * pageSize + row * columns + column;

                    const entry = sourceIndex < source.length ? source[sourceIndex] : null;

                    result.push({
                        id: `${page}-${column}-${row}`,
                        sourceIndex: entry ? sourceIndex : -1,
                        entry: entry
                    });
                }
            }
        }

        return result;
    }

    // --------------------------------------------------
    // MAPEAMENTO DE POSIÇÕES DA GRADE
    // --------------------------------------------------

    // Retorna o aplicativo que ocupa exatamente a posição solicitada.
    function applicationIndexAt(page, row, column) {
        if (page < 0 || page >= pageCount)
            return -1;

        if (row < 0 || row >= rowsPerPage)
            return -1;

        if (column < 0 || column >= columnsPerPage)
            return -1;

        const index = page * itemsPerPage + row * columnsPerPage + column;
        const pageStart = page * itemsPerPage;
        const pageEnd = Math.min(pageStart + itemsPerPage, filteredApplications.length);

        return index >= pageStart && index < pageEnd ? index : -1;
    }

    // Em páginas incompletas, procura o cartão mais próximo da posição desejada.
    // A distância prioriza permanecer na mesma linha.
    function nearestApplicationIndexAt(page, row, column) {
        if (page < 0 || page >= pageCount)
            return -1;

        const start = page * itemsPerPage;
        const end = Math.min(start + itemsPerPage, filteredApplications.length);

        if (start >= end)
            return -1;

        let bestIndex = -1;
        let bestDistance = Infinity;

        for (let index = start; index < end; index++) {
            const offset = index - start;
            const candidateRow = Math.floor(offset / columnsPerPage);
            const candidateColumn = offset % columnsPerPage;

            const distance = Math.abs(candidateRow - row) * columnsPerPage + Math.abs(candidateColumn - column);

            if (distance < bestDistance) {
                bestDistance = distance;
                bestIndex = index;
            }
        }

        return bestIndex;
    }

    // --------------------------------------------------
    // CATEGORIAS
    // --------------------------------------------------

    function selectCategory(categoryId) {
        if (root.selectedCategoryId === categoryId)
            return;

        root.selectedCategoryId = categoryId;
    }

    function cycleCategory(direction) {
        const count = root.launcherCategories.length;

        let currentIndex = root.launcherCategories.findIndex(category => category.id === root.selectedCategoryId);

        if (currentIndex < 0)
            currentIndex = 0;

        const nextIndex = (currentIndex + direction + count) % count;

        root.selectCategory(root.launcherCategories[nextIndex].id);
    }

    // --------------------------------------------------
    // POSICIONAMENTO E ANIMAÇÃO DAS PÁGINAS
    // --------------------------------------------------

    function positionPage(page) {
        if (!root.visible || appGrid.width <= 0)
            return;

        const maxX = Math.max(0, appGrid.contentWidth - appGrid.width);

        const targetX = Math.max(0, Math.min(page * appGrid.width, maxX));

        appGrid.contentX = targetX;
    }

    // --------------------------------------------------
    // ATUALIZAÇÃO DA SELEÇÃO
    // --------------------------------------------------

    function refreshSelection() {
        animatePageTransitions = false;

        wheelAccumulator = 0;
        currentPage = 0;

        selectedApplicationIndex = filteredApplications.length > 0 ? 0 : -1;
        navigationRow = 0;
        navigationColumn = 0;

        const generation = ++refreshGeneration;

        Qt.callLater(() => {
            if (generation !== refreshGeneration)
                return;

            if (!root.visible) {
                animatePageTransitions = true;
                return;
            }

            appGrid.forceLayout();

            appGrid.contentX = 0;

            Qt.callLater(() => {
                if (generation === refreshGeneration)
                    animatePageTransitions = true;
            });
        });
    }

    // --------------------------------------------------
    // ATUALIZAÇÃO DO LAYOUT AO REDIMENSIONAR
    // --------------------------------------------------

    function refreshPageLayout() {
        if (!root.visible || appGrid.width <= 0)
            return;

        animatePageTransitions = false;

        const generation = ++refreshGeneration;

        Qt.callLater(() => {
            if (generation !== refreshGeneration)
                return;

            if (!root.visible) {
                animatePageTransitions = true;
                return;
            }

            appGrid.forceLayout();

            const count = filteredApplications.length;

            if (count === 0) {
                selectedApplicationIndex = -1;
                currentPage = 0;
                navigationRow = 0;
                navigationColumn = 0;
            } else {
                selectedApplicationIndex = Math.max(0, Math.min(selectedApplicationIndex, count - 1));

                currentPage = Math.min(Math.floor(selectedApplicationIndex / itemsPerPage), Math.max(0, pageCount - 1));

                const offset = selectedApplicationIndex % itemsPerPage;

                navigationRow = Math.floor(offset / columnsPerPage);
                navigationColumn = offset % columnsPerPage;
            }

            positionPage(currentPage);

            Qt.callLater(() => {
                if (generation === refreshGeneration)
                    animatePageTransitions = true;
            });
        });
    }

    // Seleciona um índice mantendo uma posição lógica de navegação.
    function selectApplicationAt(index, preferredRow, preferredColumn) {
        if (index < 0 || index >= filteredApplications.length)
            return;

        const previousPage = currentPage;
        const page = Math.floor(index / itemsPerPage);

        selectedApplicationIndex = index;
        currentPage = page;

        navigationRow = Math.max(0, Math.min(preferredRow, rowsPerPage - 1));
        navigationColumn = Math.max(0, Math.min(preferredColumn, columnsPerPage - 1));

        if (page !== previousPage)
            positionPage(page);
    }

    // Seleção normal: atualiza também a posição lógica para a célula real.
    function selectApplication(index) {
        if (index < 0 || index >= filteredApplications.length)
            return;

        const offset = index % itemsPerPage;
        const row = Math.floor(offset / columnsPerPage);
        const column = offset % columnsPerPage;

        selectApplicationAt(index, row, column);
    }

    // --------------------------------------------------
    // MODOS DE INTERAÇÃO: MOUSE / TECLADO
    // --------------------------------------------------

    function activateKeyboardNavigation() {
        if (keyboardNavigationActive)
            return;

        keyboardModePointerOrigin = pointerTracker.hovered ? pointerTracker.point.position : Qt.point(-1, -1);

        keyboardNavigationActive = true;
    }

    function restoreMouseNavigation() {
        keyboardNavigationActive = false;
        keyboardModePointerOrigin = Qt.point(-1, -1);
    }

    // Compartilhado pelo HoverHandler e pelo bloqueador de entrada.
    // Mantém a origem no mesmo sistema de coordenadas do backdrop.
    function checkPointerMovement(position) {
        if (!keyboardNavigationActive)
            return;

        if (keyboardModePointerOrigin.x < 0 || keyboardModePointerOrigin.y < 0) {
            keyboardModePointerOrigin = position;
            return;
        }

        const dx = position.x - keyboardModePointerOrigin.x;
        const dy = position.y - keyboardModePointerOrigin.y;
        const distanceSquared = dx * dx + dy * dy;
        const thresholdSquared = pointerResumeDistance * pointerResumeDistance;

        if (distanceSquared >= thresholdSquared)
            restoreMouseNavigation();
    }

    // --------------------------------------------------
    // NAVEGAÇÃO PELO TECLADO
    // --------------------------------------------------

    function handleNavigationKey(key, isAutoRepeat) {
        const arrowKeys = [Qt.Key_Left, Qt.Key_Right, Qt.Key_Up, Qt.Key_Down];

        if (!arrowKeys.includes(key))
            return false;

        const now = Date.now();

        // Limita a velocidade das repetições das setas.
        if (isAutoRepeat && now - lastNavigationAcceptedAt < navigationRepeatInterval)
            return true;

        if (!root.navigate(key))
            return false;

        lastNavigationAcceptedAt = now;

        return true;
    }

    function navigate(key) {
        if (key === Qt.Key_Left || key === Qt.Key_Right || key === Qt.Key_Up || key === Qt.Key_Down) {
            root.activateKeyboardNavigation();
        }

        const count = filteredApplications.length;

        if (count === 0)
            return false;

        if (selectedApplicationIndex < 0) {
            selectApplication(0);
            return true;
        }

        const index = selectedApplicationIndex;
        const page = currentPage;

        const offset = index % itemsPerPage;
        const row = Math.floor(offset / columnsPerPage);
        const column = offset % columnsPerPage;

        let target = -1;

        switch (key) {
        case Qt.Key_Left:
            if (column > 0) {
                target = applicationIndexAt(page, row, column - 1);

                if (target >= 0)
                    selectApplication(target);
            } else if (page > 0) {
                const targetRow = navigationRow;
                const targetColumn = columnsPerPage - 1;

                target = nearestApplicationIndexAt(page - 1, targetRow, targetColumn);

                if (target >= 0)
                    selectApplicationAt(target, targetRow, targetColumn);
            }

            return true;
        case Qt.Key_Right:
            if (column < columnsPerPage - 1) {
                target = applicationIndexAt(page, row, column + 1);

                if (target >= 0)
                    selectApplication(target);
            } else if (page + 1 < pageCount) {
                const targetRow = navigationRow;
                const targetColumn = 0;

                target = nearestApplicationIndexAt(page + 1, targetRow, targetColumn);

                if (target >= 0)
                    selectApplicationAt(target, targetRow, targetColumn);
            }

            return true;
        case Qt.Key_Up:
            if (row > 0) {
                target = applicationIndexAt(page, row - 1, column);

                if (target >= 0)
                    selectApplication(target);
            }

            return true;
        case Qt.Key_Down:
            if (row < rowsPerPage - 1) {
                target = applicationIndexAt(page, row + 1, column);

                if (target >= 0)
                    selectApplication(target);
            }

            return true;
        default:
            return false;
        }
    }
    // --------------------------------------------------
    // TROCA PROGRAMÁTICA DE PÁGINA
    // --------------------------------------------------

    function changePage(direction) {
        if (pageCount <= 1)
            return;

        const nextPage = Math.max(0, Math.min(currentPage + direction, pageCount - 1));

        if (nextPage === currentPage)
            return;

        const desiredRow = navigationRow;
        const desiredColumn = navigationColumn;

        const target = nearestApplicationIndexAt(nextPage, desiredRow, desiredColumn);

        if (target >= 0) {
            selectApplicationAt(target, desiredRow, desiredColumn);
        }
    }

    // --------------------------------------------------
    // SCROLL
    // --------------------------------------------------

    function handleWheel(angleDelta, pixelDelta) {
        if (pageCount <= 1)
            return;

        const delta = angleDelta !== 0 ? angleDelta : pixelDelta;

        if (delta === 0)
            return;

        wheelAccumulator += delta;

        const threshold = angleDelta !== 0 ? 120 : 100;

        const steps = Math.floor(Math.abs(wheelAccumulator) / threshold);

        if (steps < 1)
            return;

        const direction = wheelAccumulator > 0 ? -1 : 1;

        wheelAccumulator -= Math.sign(wheelAccumulator) * steps * threshold;

        root.changePage(direction * steps);
    }

    // --------------------------------------------------
    // CLIQUE FORA DOS ELEMENTOS INTERATIVOS
    // --------------------------------------------------

    function itemContainsPoint(item, point) {
        if (!item || !item.visible)
            return false;

        const localPoint = item.mapFromItem(backdrop, point.x, point.y);

        return localPoint.x >= 0 && localPoint.y >= 0 && localPoint.x <= item.width && localPoint.y <= item.height;
    }

    function isInteractiveArea(point) {
        if (itemContainsPoint(searchBar, point))
            return true;

        if (itemContainsPoint(categoryBar, point))
            return true;

        // Considera todos os delegates instanciados.
        // Inclui os cartões visíveis durante a transição.
        for (let i = 0; i < appGrid.count; i++) {
            const delegate = appGrid.itemAtIndex(i);

            if (!delegate)
                continue;

            if (itemContainsPoint(delegate.cardItem, point))
                return true;
        }

        return false;
    }

    // --------------------------------------------------
    // EXECUÇÃO
    // --------------------------------------------------

    function launchEntry(entry) {
        if (!entry || !entry.id) {
            console.warn("Invalid desktop entry.");
            return;
        }

        if (entry.runInTerminal) {
            Quickshell.execDetached({
                command: ["kitty", "--", ...entry.command],
                workingDirectory: entry.workingDirectory
            });
        } else {
            const launchId = String(entry.id).replace(/\.desktop$/i, "");
            Quickshell.execDetached(["gtk-launch", launchId]);
        }

        root.closeLauncher();
    }

    function launchSelected() {
        if (selectedApplicationIndex < 0 || selectedApplicationIndex >= filteredApplications.length)
            return;

        root.launchEntry(filteredApplications[selectedApplicationIndex]);
    }

    // --------------------------------------------------
    // CONTROLE DO LAUNCHER
    // --------------------------------------------------

    function openLauncher() {
        if (fullscreenActive)
            return;

        root.visible = true;
    }

    function closeLauncher() {
        root.visible = false;
    }

    IpcHandler {
        target: "app-launcher"

        function toggle(): void {
            if (root.visible)
                root.closeLauncher();
            else
                root.openLauncher();
        }
    }

    onFullscreenActiveChanged: {
        if (fullscreenActive)
            root.closeLauncher();
    }

    onVisibleChanged: {
        keyboardNavigationActive = false;
        keyboardModePointerOrigin = Qt.point(-1, -1);

        if (visible) {
            searchInput.text = "";
            wheelAccumulator = 0;

            const alreadyAll = selectedCategoryId === "all";

            selectedCategoryId = "all";

            if (alreadyAll)
                root.refreshSelection();

            Qt.callLater(() => {
                if (root.visible)
                    searchInput.forceActiveFocus();
            });
        }
    }

    onSelectedCategoryIdChanged: {
        root.refreshSelection();
    }

    onRowsPerPageChanged: {
        root.refreshPageLayout();
    }

    // --------------------------------------------------
    // INTERFACE
    // --------------------------------------------------

    Rectangle {
        id: backdrop

        anchors.fill: parent

        color: "#B3111111"

        // ==============================================
        // CLIQUE EM ESPAÇOS VAZIOS
        // ==============================================

        // Observa a posição do mouse sem capturar cliques.
        HoverHandler {
            id: pointerTracker

            acceptedDevices: PointerDevice.Mouse
            cursorShape: root.keyboardNavigationActive ? Qt.BlankCursor : undefined

            // Segunda via de detecção: o cursor volta ao modo mouse
            // assim que houver movimento físico suficiente.
            onPointChanged: {
                if (hovered)
                    root.checkPointerMovement(point.position);
            }
        }

        TapHandler {
            enabled: !root.keyboardNavigationActive
            acceptedButtons: Qt.LeftButton

            gesturePolicy: TapHandler.DragThreshold
            dragThreshold: 32
            longPressThreshold: 0

            onTapped: (eventPoint, button) => {
                const point = eventPoint.position;

                if (!root.isInteractiveArea(point))
                    root.closeLauncher();
            }
        }

        // ==============================================
        // PESQUISA
        // ==============================================

        Rectangle {
            id: searchBar

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 32

            width: 340
            height: 35

            radius: 10

            color: "#20F5F5F5"

            border.width: 1
            border.color: "#40F5F5F5"

            Row {
                anchors.fill: parent

                anchors.leftMargin: 14
                anchors.rightMargin: 14

                spacing: 10

                Text {
                    width: 18
                    height: parent.height

                    text: "⌕"

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    font.family: Theme.fontFamily
                    font.pixelSize: 18

                    color: "#80F5F5F5"
                }

                Item {
                    width: parent.width - 18 - 10
                    height: parent.height

                    TextInput {
                        id: searchInput

                        anchors.fill: parent

                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall

                        color: Theme.text

                        selectionColor: "#60FFFFFF"
                        selectedTextColor: "#000000"

                        verticalAlignment: TextInput.AlignVCenter
                        selectByMouse: !root.keyboardNavigationActive

                        Keys.priority: Keys.BeforeItem

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                root.closeLauncher();
                                event.accepted = true;
                                return;
                            }

                            if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                                root.activateKeyboardNavigation();

                                const backwards = event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier);

                                root.cycleCategory(backwards ? -1 : 1);

                                event.accepted = true;
                                return;
                            }

                            if (root.handleNavigationKey(event.key, event.isAutoRepeat)) {
                                event.accepted = true;
                                return;
                            }
                        }

                        onAccepted: {
                            root.launchSelected();
                        }

                        onTextEdited: {
                            root.refreshSelection();
                        }
                    }

                    Text {
                        anchors.fill: parent

                        visible: searchInput.text.length === 0

                        text: "Search"

                        verticalAlignment: Text.AlignVCenter

                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall

                        color: "#80F5F5F5"

                        enabled: false
                    }
                }
            }
        }

        // ==============================================
        // CATEGORIAS
        // ==============================================

        Item {
            id: categoryBar

            anchors.top: searchBar.bottom
            anchors.topMargin: 16

            anchors.horizontalCenter: parent.horizontalCenter

            width: categoryRow.implicitWidth
            height: 34

            Row {
                id: categoryRow

                anchors.centerIn: parent

                spacing: 8

                Repeater {
                    model: root.launcherCategories

                    delegate: Item {
                        id: categoryDelegate

                        required property var modelData

                        readonly property bool selected: root.selectedCategoryId === modelData.id

                        width: categoryText.implicitWidth + 28
                        height: 34

                        Rectangle {
                            anchors.fill: parent

                            radius: 8

                            color: categoryDelegate.selected ? "#30FFFFFF" : (!root.keyboardNavigationActive && categoryMouse.containsMouse) ? "#18FFFFFF" : "transparent"

                            border.width: categoryDelegate.selected ? 1 : 0
                            border.color: "#80FFFFFF"

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.animDuration
                                }
                            }
                        }

                        Text {
                            id: categoryText

                            anchors.centerIn: parent

                            text: categoryDelegate.modelData.label

                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall

                            color: Theme.text

                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            id: categoryMouse

                            anchors.fill: parent
                            enabled: !root.keyboardNavigationActive

                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                root.selectCategory(categoryDelegate.modelData.id);

                                searchInput.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }

        // ==============================================
        // GRADE HORIZONTAL DE APLICATIVOS
        // ==============================================

        GridView {
            id: appGrid

            anchors.top: categoryBar.bottom
            anchors.topMargin: 28

            anchors.bottom: parent.bottom
            anchors.bottomMargin: 32

            anchors.horizontalCenter: parent.horizontalCenter

            width: Math.min(parent.width - 96, 1120)

            cellWidth: width / root.columnsPerPage
            cellHeight: root.appCellHeight

            flow: GridView.FlowTopToBottom

            layoutDirection: Qt.LeftToRight
            verticalLayoutDirection: GridView.TopToBottom

            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds

            clip: true

            interactive: false

            keyNavigationEnabled: false
            keyNavigationWraps: false

            highlightFollowsCurrentItem: false

            onWidthChanged: {
                root.refreshPageLayout();
            }

            model: ScriptModel {
                objectProp: "id"

                values: root.pagedApplications
            }

            // Animação que acompanha alterações rápidas de destino.
            Behavior on contentX {
                enabled: root.animatePageTransitions

                NumberAnimation {
                    duration: Theme.animDurationSlow
                    easing.type: Easing.OutCubic
                }
            }
            // Scroll vertical do mouse e touchpad.
            WheelHandler {
                enabled: !root.keyboardNavigationActive
                target: null

                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

                orientation: Qt.Vertical

                onWheel: event => {
                    root.handleWheel(event.angleDelta.y, event.pixelDelta.y);

                    event.accepted = true;
                }
            }

            // ------------------------------------------
            // DELEGATES
            // ------------------------------------------

            delegate: LauncherAppTile {
                launcher: root
                cellWidth: appGrid.cellWidth
                cellHeight: appGrid.cellHeight
            }
        }

        // ==============================================
        // NENHUM RESULTADO
        // ==============================================

        Text {
            anchors.centerIn: appGrid

            visible: root.filteredApplications.length === 0

            text: "No applications found"

            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize

            color: Theme.textMuted
        }

        // Bloqueia toda a entrada do mouse enquanto as setas estiverem ativas.
        // Fica acima dos demais elementos, mas não recebe foco de teclado.
        MouseArea {
            id: keyboardInputBlocker

            anchors.fill: parent
            z: 10000

            enabled: root.keyboardNavigationActive && root.visible
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons

            // Este MouseArea bloqueia os eventos, mas NÃO define cursorShape.
            // A visibilidade do cursor é controlada exclusivamente pelo HoverHandler.
            onEntered: {
                root.checkPointerMovement(Qt.point(mouseX, mouseY));
            }

            onPositionChanged: {
                root.checkPointerMovement(Qt.point(mouseX, mouseY));
            }

            onWheel: event => {
                event.accepted = true;
            }
        }
    }
}

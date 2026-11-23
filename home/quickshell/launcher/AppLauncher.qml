import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
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
            desktopCategories: ["Settings", "Utility"]
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

    property real wheelAccumulator: 0

    property bool animatePageTransitions: true

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

    // --------------------------------------------------
    // CATEGORIZAÇÃO EXCLUSIVA
    // --------------------------------------------------

    // Retorna o id da categoria "primária" do aplicativo.
    // A primeira categoria da lista (exceto "all") que casa com as
    // categorias do .desktop vence. Retorna null se nenhuma casar.
    function primaryCategoryIdFor(entry) {
        const categories = entry.categories || [];

        if (categories.length === 0)
            return null;

        for (const cat of root.launcherCategories) {
            if (cat.id === "all")
                continue;

            if ((cat.desktopCategories || []).some(c => categories.includes(c)))
                return cat.id;
        }

        return null;
    }

    // Índice da categoria na lista (para ordenação). "null" vai para o fim.
    function categorySortIndex(categoryId) {
        if (!categoryId)
            return root.launcherCategories.length;

        for (let i = 0; i < root.launcherCategories.length; i++) {
            if (root.launcherCategories[i].id === categoryId)
                return i;
        }

        return root.launcherCategories.length;
    }

    // --------------------------------------------------
    // PONTUAÇÃO DE RELEVÂNCIA DE BUSCA
    // --------------------------------------------------

    function searchRelevanceScore(entry, query, terms) {
        const name = String(entry.name || "").toLowerCase();
        const genericName = String(entry.genericName || "").toLowerCase();
        const comment = String(entry.comment || "").toLowerCase();
        const id = String(entry.id || "").toLowerCase();
        const keywords = (entry.keywords || []).join(" ").toLowerCase();

        let score = 0;

        if (name === query)
            score += 1000;
        else if (name.startsWith(query))
            score += 800;
        else if (name.split(/\s+/).some(word => word.startsWith(query)))
            score += 600;
        else if (name.includes(query))
            score += 400;

        if (genericName === query)
            score += 500;
        else if (genericName.startsWith(query))
            score += 400;
        else if (genericName.split(/\s+/).some(word => word.startsWith(query)))
            score += 300;
        else if (genericName.includes(query))
            score += 200;

        const keywordWords = keywords.split(/[\s,]+/);
        if (keywordWords.some(word => word === query))
            score += 250;
        else if (keywordWords.some(word => word.startsWith(query)))
            score += 150;
        else if (keywords.includes(query))
            score += 100;

        if (comment.includes(query))
            score += 50;

        if (id.includes(query))
            score += 25;

        if (terms.length > 1) {
            let allTermsInName = true;
            for (const term of terms) {
                if (!name.includes(term)) {
                    allTermsInName = false;
                    break;
                }
            }
            if (allTermsInName)
                score += 900;
        }

        return score;
    }

    // --------------------------------------------------
    // FILTRAGEM E ORDENAÇÃO
    // --------------------------------------------------

    readonly property var filteredApplications: {
        const categoryId = root.selectedCategoryId;
        const query = searchInput.text.trim().toLowerCase();
        const terms = query.length > 0 ? query.split(/\s+/).filter(term => term.length > 0) : [];
        const hasQuery = terms.length > 0;

        const entries = [...DesktopEntries.applications.values].filter(entry => {
            const name = String(entry.name || "").trim();

            if (!name || !entry.id)
                return false;

            if (entry.noDisplay)
                return false;

            if (categoryId !== "all") {
                if (root.primaryCategoryIdFor(entry) !== categoryId)
                    return false;

                const blocked = categoryId === "settings" ? ["System", "AudioVideo", "Audio"] : root.excludedCategories;

                if ((entry.categories || []).some(category => blocked.includes(category)))
                    return false;
            }

            if (hasQuery) {
                const searchableText = [entry.name || "", entry.genericName || "", entry.comment || "", entry.id || "", (entry.keywords || []).join(" "), (entry.categories || []).join(" ")].join(" ").toLowerCase();

                if (!terms.every(term => searchableText.includes(term)))
                    return false;
            }

            return true;
        });

        // Com busca: ranking por relevância, depois alfabético.
        if (hasQuery) {
            return entries.map(entry => ({
                        entry: entry,
                        score: root.searchRelevanceScore(entry, query, terms)
                    })).sort((a, b) => {
                if (b.score !== a.score)
                    return b.score - a.score;

                return a.entry.name.toLowerCase().localeCompare(b.entry.name.toLowerCase());
            }).map(item => item.entry);
        }

        // Sem busca: agrupa por categoria (seguindo a ordem das abas em
        // launcherCategories) e ordena alfabeticamente dentro de cada grupo.
        // Em abas específicas todos os apps têm a mesma categoria primária,
        // então o resultado é alfabético — o agrupamento só afeta "Todos".
        const categorized = entries.map(entry => ({
                    entry: entry,
                    categoryIndex: root.categorySortIndex(root.primaryCategoryIdFor(entry))
                }));

        categorized.sort((a, b) => {
            if (a.categoryIndex !== b.categoryIndex)
                return a.categoryIndex - b.categoryIndex;

            return a.entry.name.toLowerCase().localeCompare(b.entry.name.toLowerCase());
        });

        return categorized.map(item => item.entry);
    }

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

        wheelAccumulator = 0;

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

    function selectApplication(index) {
        if (index < 0 || index >= filteredApplications.length)
            return;

        const offset = index % itemsPerPage;
        const row = Math.floor(offset / columnsPerPage);
        const column = offset % columnsPerPage;

        selectApplicationAt(index, row, column);
    }

    // --------------------------------------------------
    // NAVEGAÇÃO PELO TECLADO
    // --------------------------------------------------

    function navigate(key) {
        const count = filteredApplications.length;

        if (count === 0)
            return false;

        if (selectedApplicationIndex < 0) {
            if (key === Qt.Key_Left || key === Qt.Key_Right || key === Qt.Key_Up || key === Qt.Key_Down) {
                selectApplication(0);
                return true;
            }

            return false;
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
        root.visible = true;
    }

    function closeLauncher() {
        root.visible = false;
    }

    IpcHandler {
        target: "app-launcher"

        function toggle(): void {
            root.visible = !root.visible;
        }
    }

    onVisibleChanged: {
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

        TapHandler {
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
                        selectByMouse: true

                        Keys.priority: Keys.BeforeItem

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                root.closeLauncher();
                                event.accepted = true;
                                return;
                            }

                            if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                                const backwards = event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier);

                                root.cycleCategory(backwards ? -1 : 1);

                                event.accepted = true;
                                return;
                            }

                            if (root.navigate(event.key)) {
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

                            color: categoryDelegate.selected ? "#30FFFFFF" : categoryMouse.containsMouse ? "#18FFFFFF" : "transparent"

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

            Behavior on contentX {
                enabled: root.animatePageTransitions

                SmoothedAnimation {
                    duration: 200
                    reversingMode: SmoothedAnimation.Immediate
                }
            }

            WheelHandler {
                target: null

                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

                orientation: Qt.Vertical

                onWheel: event => {
                    root.handleWheel(event.angleDelta.y, event.pixelDelta.y);

                    event.accepted = true;
                }
            }

            delegate: Item {
                id: appDelegate

                required property var modelData
                required property int index

                readonly property int sourceIndex: modelData.sourceIndex

                readonly property bool selected: sourceIndex >= 0 && root.selectedApplicationIndex === sourceIndex

                readonly property Item cardItem: tile

                width: appGrid.cellWidth
                height: appGrid.cellHeight

                Rectangle {
                    id: tile

                    anchors.fill: parent
                    anchors.margins: 16

                    visible: !!appDelegate.modelData.entry

                    radius: 16

                    color: appDelegate.selected ? "#20FFFFFF" : "transparent"

                    border.width: appDelegate.selected ? 1 : 0
                    border.color: "#80FFFFFF"

                    IconImage {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 16

                        implicitSize: 64

                        asynchronous: true

                        source: appDelegate.modelData.entry ? Quickshell.iconPath(appDelegate.modelData.entry.icon || "", "application-x-executable") : ""
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom

                        anchors.bottomMargin: 10

                        height: 34

                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize

                        color: Theme.text

                        text: appDelegate.modelData.entry ? appDelegate.modelData.entry.name : ""

                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: tileMouse

                        anchors.fill: parent

                        enabled: !!appDelegate.modelData.entry

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: {
                            if (root.pageTransitionActive)
                                return;

                            root.selectApplication(appDelegate.sourceIndex);
                        }

                        onClicked: {
                            root.selectApplication(appDelegate.sourceIndex);

                            root.launchEntry(appDelegate.modelData.entry);
                        }
                    }
                }
            }
        }

        Text {
            anchors.centerIn: appGrid

            visible: root.filteredApplications.length === 0

            text: "No applications found"

            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize

            color: Theme.textMuted
        }
    }
}

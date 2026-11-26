import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import "../theme"
import "../services"

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

    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-clipboard"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property bool fullscreenActive: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.hasFullscreen : false

    // ── Constantes de layout ────────────────────────────────────────────────
    readonly property int cardMaxWidth: 720
    readonly property int cardMaxHeight: 560
    readonly property int cardMargin: 48
    readonly property int contentMargin: 20
    readonly property int delegateHeight: 76
    readonly property int thumbnailSize: 58

    property int selectedIndex: 0
    property real cardYOffset: -16
    property real cardOpacity: 0

    readonly property var filteredEntries: {
        const revision = CliphistService.revision;
        const query = searchField.text.trim().toLowerCase();

        const result = [];
        const count = CliphistService.entries.count;

        for (let i = 0; i < count; i++) {
            const entry = CliphistService.entries.get(i);
            const searchable = [entry.preview, entry.isImage ? "image" : "text", entry.entryId].join(" ").toLowerCase();

            if (query && !searchable.includes(query))
                continue;
            result.push(entry);
        }

        return result;
    }

    // -------------------------------------------------------------------------
    // Animations
    // -------------------------------------------------------------------------

    ParallelAnimation {
        id: openAnimation

        NumberAnimation {
            target: root
            property: "cardYOffset"
            from: -16
            to: 0
            duration: 180
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "cardOpacity"
            from: 0
            to: 1
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: closeAnimation

        NumberAnimation {
            target: root
            property: "cardYOffset"
            to: -10
            duration: 130
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: root
            property: "cardOpacity"
            to: 0
            duration: 130
            easing.type: Easing.InCubic
        }

        onFinished: {
            root.visible = false;
        }
    }

    // -------------------------------------------------------------------------
    // Functions
    // -------------------------------------------------------------------------

    function openPanel() {
        if (fullscreenActive)
            return;
        openAnimation.stop();
        closeAnimation.stop();

        selectedIndex = 0;
        searchField.text = "";

        cardYOffset = -16;
        cardOpacity = 0;

        visible = true;

        CliphistService.refresh();

        Qt.callLater(() => {
            if (!root.visible)
                return;
            searchField.forceActiveFocus();
            openAnimation.start();
        });
    }

    function closePanel() {
        if (!visible)
            return;
        openAnimation.stop();
        closeAnimation.stop();
        closeAnimation.start();
    }

    function toggle() {
        if (visible)
            closePanel();
        else
            openPanel();
    }

    function moveSelection(direction) {
        const count = filteredEntries.length;

        if (count === 0)
            return;
        const nextIndex = Math.max(0, Math.min(count - 1, selectedIndex + direction));

        if (nextIndex === selectedIndex)
            return;
        selectedIndex = nextIndex;

        listView.positionViewAtIndex(nextIndex, ListView.Contain);
    }

    function copyItem(id) {
        CliphistService.copy(id);
        closePanel();
    }

    function copySelected() {
        const entry = filteredEntries[selectedIndex];

        if (!entry)
            return;
        copyItem(entry.entryId);
    }

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            root.toggle();
        }
    }

    onFullscreenActiveChanged: {
        if (fullscreenActive)
            closePanel();
    }

    onVisibleChanged: {
        if (!visible) {
            openAnimation.stop();
            closeAnimation.stop();

            cardYOffset = -16;
            cardOpacity = 0;
            selectedIndex = 0;
        }
    }

    onFilteredEntriesChanged: {
        const count = filteredEntries.length;

        if (count === 0) {
            selectedIndex = 0;
        } else if (selectedIndex >= count) {
            selectedIndex = count - 1;
        }
    }

    // -------------------------------------------------------------------------
    // Backdrop (clique fora fecha o painel)
    // -------------------------------------------------------------------------

    Rectangle {
        anchors.fill: parent
        color: Theme.background
        opacity: 0.78

        // Substitui o TapHandler manual — mais simples e imune a mudanças
        // na geometria/translação do card.
        MouseArea {
            anchors.fill: parent
            onClicked: root.closePanel()
        }
    }

    // -------------------------------------------------------------------------
    // Main card
    // -------------------------------------------------------------------------

    Item {
        id: cardMotion

        z: 1

        width: Math.max(0, Math.min(root.cardMaxWidth, root.width - root.cardMargin))
        height: Math.max(0, Math.min(root.cardMaxHeight, root.height - root.cardMargin))

        anchors.centerIn: parent

        opacity: root.cardOpacity

        transform: Translate {
            y: root.cardYOffset
        }

        Rectangle {
            anchors.fill: parent

            radius: Theme.radiusXl
            color: Theme.cardBackground

            border.width: 1
            border.color: Theme.borderColor

            clip: true
        }

        Column {
            id: content

            anchors.fill: parent
            anchors.margins: root.contentMargin

            spacing: 14

            // -----------------------------------------------------------------
            // Header
            // -----------------------------------------------------------------

            Row {
                id: headerRow

                width: parent.width
                height: 42

                spacing: 10

                Column {
                    width: headerRow.width - countBadge.width - headerRow.spacing

                    anchors.verticalCenter: parent.verticalCenter

                    spacing: 3

                    Text {
                        text: "Clipboard"

                        color: Theme.text

                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: "Clipboard history"

                        color: Theme.textMuted

                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }

                Rectangle {
                    id: countBadge

                    width: 64
                    height: 28

                    anchors.verticalCenter: parent.verticalCenter

                    radius: Theme.radiusLg
                    color: Theme.hoverBackground

                    Text {
                        anchors.centerIn: parent

                        text: String(root.filteredEntries.length)

                        color: Theme.text

                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                    }
                }
            }

            // -----------------------------------------------------------------
            // Search
            // -----------------------------------------------------------------

            Rectangle {
                id: searchBox

                width: parent.width
                height: 44

                radius: Theme.radiusLg
                color: Theme.background

                border.width: 1
                border.color: Theme.borderColor

                TextInput {
                    id: searchField

                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14

                    verticalAlignment: TextInput.AlignVCenter

                    color: Theme.text
                    selectionColor: Theme.hoverBackground
                    selectedTextColor: Theme.text

                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize

                    selectByMouse: true
                    clip: true

                    Keys.priority: Keys.BeforeItem

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            root.closePanel();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            root.moveSelection(1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            root.moveSelection(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.copySelected();
                            event.accepted = true;
                        }
                    }

                    onTextChanged: {
                        root.selectedIndex = 0;

                        Qt.callLater(() => {
                            listView.positionViewAtBeginning();
                        });
                    }
                }

                // Placeholder independente (compatível com Quickshell 0.3.2).
                // `placeholderTextColor` não existe nessa versão do TextInput.
                Text {
                    anchors.left: searchField.left
                    anchors.right: searchField.right
                    anchors.verticalCenter: searchField.verticalCenter

                    visible: searchField.text.length === 0

                    text: "Search clipboard..."

                    color: Theme.textMuted

                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize

                    elide: Text.ElideRight
                }
            }

            // -----------------------------------------------------------------
            // Clipboard list
            // -----------------------------------------------------------------

            Item {
                id: listArea

                width: parent.width

                height: Math.max(100, parent.height - headerRow.height - searchBox.height - footerRow.height - content.spacing * 3)

                ListView {
                    id: listView

                    anchors.fill: parent

                    clip: true
                    spacing: 6

                    // cacheBuffer pré-instancia alguns delegates fora da viewport,
                    // melhorando a rolagem sem custo excessivo de memória.
                    cacheBuffer: 200

                    model: root.filteredEntries
                    currentIndex: root.selectedIndex

                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Item {
                        id: delegateItem

                        required property int index
                        required property string entryId
                        required property string preview
                        required property bool isImage
                        required property string extension
                        required property string previewUrl
                        required property bool previewReady
                        required property bool previewLoading
                        required property string summary

                        width: listView.width
                        height: root.delegateHeight

                        Component.onCompleted: {
                            if (isImage)
                                CliphistService.requestPreview(entryId);
                        }

                        // Seleção instantânea, sem animação de cor.
                        Rectangle {
                            anchors.fill: parent

                            radius: Theme.radiusLg

                            color: root.selectedIndex === delegateItem.index ? Theme.hoverBackground : Theme.cardBackground
                        }

                        // -----------------------------------------------------------------
                        // Thumbnail
                        // -----------------------------------------------------------------

                        Rectangle {
                            id: thumbnail

                            width: root.thumbnailSize
                            height: root.thumbnailSize

                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter

                            radius: Theme.radiusLg

                            color: Theme.background

                            border.width: 1
                            border.color: Theme.borderColor

                            clip: true

                            Image {
                                anchors.fill: parent

                                visible: delegateItem.isImage && delegateItem.previewReady

                                source: delegateItem.previewUrl

                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true

                                sourceSize: Qt.size(root.thumbnailSize, root.thumbnailSize)

                                cache: true
                            }

                            Text {
                                anchors.centerIn: parent

                                visible: !delegateItem.isImage || !delegateItem.previewReady

                                text: delegateItem.isImage ? "▧" : "Aa"

                                color: Theme.textMuted

                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.DemiBold
                            }
                        }

                        // -----------------------------------------------------------------
                        // Entry information
                        // -----------------------------------------------------------------

                        Column {
                            anchors.left: thumbnail.right
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 12

                            anchors.verticalCenter: parent.verticalCenter

                            spacing: 5

                            Text {
                                width: parent.width

                                text: delegateItem.isImage ? delegateItem.summary : delegateItem.preview

                                color: Theme.text

                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize

                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Text {
                                width: parent.width

                                text: (delegateItem.isImage ? "Image" : "Text") + " · " + delegateItem.entryId

                                color: Theme.textMuted

                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall

                                elide: Text.ElideRight
                            }
                        }

                        // -----------------------------------------------------------------
                        // Mouse interaction
                        // -----------------------------------------------------------------

                        MouseArea {
                            anchors.fill: parent

                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onEntered: {
                                root.selectedIndex = delegateItem.index;
                            }

                            onClicked: {
                                root.copyItem(delegateItem.entryId);
                            }
                        }
                    }
                }

                // -----------------------------------------------------------------
                // Empty / loading / error state
                // -----------------------------------------------------------------

                Text {
                    anchors.centerIn: parent

                    width: parent.width - 32

                    visible: root.filteredEntries.length === 0

                    text: {
                        if (CliphistService.loading)
                            return "Loading clipboard history...";

                        if (CliphistService.errorMessage.length > 0)
                            return CliphistService.errorMessage;

                        if (searchField.text.trim().length > 0)
                            return "No matching items found.";

                        return "Your clipboard history is empty.";
                    }

                    color: Theme.textMuted

                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    wrapMode: Text.WordWrap
                }
            }

            // -----------------------------------------------------------------
            // Footer
            // -----------------------------------------------------------------

            Row {
                id: footerRow

                width: parent.width
                height: 22

                Text {
                    anchors.centerIn: parent

                    width: parent.width

                    text: "↑ ↓  Navigate       Enter  Copy       Esc  Close"

                    color: Theme.textMuted

                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}

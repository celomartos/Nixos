import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick.Effects
import "../../theme"

Item {
    id: root

    implicitHeight: Theme.barHeight
    implicitWidth: trayRow.implicitWidth > 0 ? trayRow.implicitWidth + 20 : 0

    visible: trayRow.implicitWidth > 0

    // Estado do arraste
    property bool dragActive: false
    property string draggedItemId: ""
    property var dragOrder: []
    property real dragPointerX: 0

    // Ordem personalizada dos ícones
    readonly property var orderedItems: {
        const activeOrder = root.dragActive ? root.dragOrder : (orderData.itemIds || []);

        const items = SystemTray.items.values.filter(item => item.status !== Status.Passive);

        const originalOrder = items.slice();

        return items.sort((a, b) => {
            const aIndex = activeOrder.indexOf(a.id);
            const bIndex = activeOrder.indexOf(b.id);

            if (aIndex === -1 && bIndex === -1) {
                return originalOrder.indexOf(a) - originalOrder.indexOf(b);
            }

            if (aIndex === -1)
                return 1;
            if (bIndex === -1)
                return -1;

            return aIndex - bIndex;
        });
    }

    // Inicia o arraste
    function beginDrag(itemId, pointerX) {
        root.dragOrder = root.orderedItems.map(item => item.id);

        root.draggedItemId = itemId;
        root.dragPointerX = pointerX;
        root.dragActive = true;
    }

    // Atualiza a ordem enquanto o mouse se movimenta
    function updateDragOrder(itemId, pointerX) {
        if (!root.dragActive || root.draggedItemId !== itemId)
            return;

        root.dragPointerX = pointerX;

        const currentItems = root.orderedItems.slice();

        const sourceIndex = currentItems.findIndex(item => item.id === itemId);

        if (sourceIndex === -1)
            return;

        const draggedItem = currentItems.splice(sourceIndex, 1)[0];

        let insertIndex = currentItems.length;

        for (let i = 0; i < currentItems.length; i++) {
            const siblingIndex = root.orderedItems.findIndex(item => item.id === currentItems[i].id);

            const sibling = trayRepeater.itemAt(siblingIndex);

            if (!sibling)
                continue;

            const midpoint = sibling.x + sibling.width / 2;

            if (pointerX < midpoint) {
                insertIndex = i;
                break;
            }
        }

        currentItems.splice(insertIndex, 0, draggedItem);

        const newOrder = currentItems.map(item => item.id);

        if (JSON.stringify(newOrder) !== JSON.stringify(root.dragOrder)) {
            root.dragOrder = newOrder;
        }
    }

    // Finaliza e salva a nova ordem
    function finishDrag(itemId, pointerX) {
        if (!root.dragActive)
            return;

        root.updateDragOrder(itemId, pointerX);

        orderData.itemIds = root.dragOrder.slice();

        root.dragActive = false;
        root.draggedItemId = "";
        root.dragOrder = [];
    }

    // Persistência da ordem
    FileView {
        id: orderFile

        path: Quickshell.statePath("tray-order.json")
        printErrors: false

        adapter: JsonAdapter {
            id: orderData

            property var itemIds: []
        }

        onAdapterUpdated: writeAdapter()
    }

    Row {
        id: trayRow

        anchors.centerIn: parent
        spacing: 8

        // Anima a movimentação dos ícones vizinhos
        move: Transition {
            NumberAnimation {
                properties: "x"
                duration: Theme.animDuration
                easing.type: Easing.OutCubic
            }
        }

        Repeater {
            id: trayRepeater

            model: ScriptModel {
                values: root.orderedItems
                objectProp: "id"
            }

            delegate: Rectangle {
                id: trayItem

                required property var modelData

                implicitWidth: 32
                implicitHeight: 24

                radius: 16

                color: mouseArea.containsMouse ? Theme.hoverBackground : "transparent"

                z: mouseArea.dragging ? 1 : 0

                scale: mouseArea.dragging ? 1.08 : 1.0

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animDuration
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.animDuration
                    }
                }

                // Mantém o ícone alinhado ao cursor
                transform: Translate {
                    x: mouseArea.dragging ? root.dragPointerX - mouseArea.grabOffsetX - trayItem.x : 0
                }

                // --- ICONE CORRIGIDO AQUI ---
                IconImage {
                    id: iconImg

                    anchors.centerIn: parent

                    source: trayItem.modelData.icon
                    implicitSize: 16

                    // Lista de apps que têm ícones escuros e precisam ser forçados para branco.
                    // Se você achar outro app com o mesmo problema, basta adicionar o nome na lista.
                    readonly property var darkIconsApps: ["easyeffects"]

                    // Verifica se o app atual está na lista
                    readonly property bool needsWhiteColor: {
                        const id = String(trayItem.modelData.id || "").toLowerCase();
                        const title = String(trayItem.modelData.title || "").toLowerCase();
                        return darkIconsApps.some(app => id.includes(app) || title.includes(app));
                    }

                    // O efeito SÓ é ativado se o app estiver na lista acima
                    layer.enabled: needsWhiteColor
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: Theme.text
                        brightness: 1.0
                    }
                }
                QsMenuAnchor {
                    id: menuAnchor

                    menu: trayItem.modelData.hasMenu ? trayItem.modelData.menu : null

                    anchor.item: trayItem
                    anchor.edges: Edges.Bottom
                }

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent

                    hoverEnabled: true

                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                    cursorShape: dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                    property bool canDrag: false
                    property bool dragging: false
                    property bool wasDragged: false

                    property real pressX: 0
                    property real pressY: 0
                    property real grabOffsetX: 0

                    onPressed: mouse => {
                        canDrag = mouse.button === Qt.LeftButton;

                        const pointer = mouseArea.mapToItem(trayRow, mouse.x, mouse.y);

                        pressX = pointer.x;
                        pressY = pointer.y;

                        grabOffsetX = pointer.x - trayItem.x;

                        dragging = false;
                        wasDragged = false;
                    }

                    onPositionChanged: mouse => {
                        if (!pressed || !canDrag)
                            return;

                        const pointer = mouseArea.mapToItem(trayRow, mouse.x, mouse.y);

                        const dx = pointer.x - pressX;
                        const dy = pointer.y - pressY;

                        // Limite para iniciar o arraste
                        if (!dragging && Math.sqrt(dx * dx + dy * dy) >= 7) {
                            dragging = true;
                            wasDragged = true;

                            root.beginDrag(trayItem.modelData.id, pointer.x);
                        }

                        if (dragging) {
                            root.updateDragOrder(trayItem.modelData.id, pointer.x);
                        }
                    }

                    onReleased: mouse => {
                        if (dragging) {
                            const pointer = mouseArea.mapToItem(trayRow, mouse.x, mouse.y);

                            root.finishDrag(trayItem.modelData.id, pointer.x);
                        }

                        canDrag = false;
                        dragging = false;
                    }

                    onCanceled: {
                        if (dragging) {
                            root.dragActive = false;
                            root.draggedItemId = "";
                            root.dragOrder = [];
                        }

                        canDrag = false;
                        dragging = false;
                    }

                    onClicked: mouse => {
                        if (wasDragged) {
                            wasDragged = false;
                            return;
                        }

                        if (mouse.button === Qt.RightButton || trayItem.modelData.onlyMenu) {
                            if (trayItem.modelData.hasMenu && trayItem.modelData.menu) {
                                menuAnchor.open();
                            } else {
                                trayItem.modelData.secondaryActivate();
                            }
                        } else if (mouse.button === Qt.LeftButton) {
                            trayItem.modelData.activate();
                        } else if (mouse.button === Qt.MiddleButton) {
                            trayItem.modelData.secondaryActivate();
                        }
                    }

                    onWheel: wheel => {
                        trayItem.modelData.scroll(wheel.angleDelta.y, false);
                    }
                }

                // Tooltip
                readonly property string tipString: {
                    let t = (trayItem.modelData.tooltipTitle || trayItem.modelData.title || "").trim();

                    let d = (trayItem.modelData.tooltipDescription || "").trim();

                    if (t && d && t !== d) {
                        return t + "\n" + d;
                    }

                    return t || d;
                }

                PopupWindow {
                    id: tooltipPopup

                    anchor.window: trayItem.QsWindow.window

                    anchor.edges: Edges.Top | Edges.Left
                    anchor.gravity: Edges.Bottom | Edges.Right
                    anchor.adjustment: PopupAdjustment.SlideX

                    anchor.onAnchoring: {
                        const pos = trayItem.mapToItem(trayItem.QsWindow.window.contentItem, 0, 0);

                        anchor.rect.x = pos.x + (trayItem.width - width) / 2;

                        anchor.rect.y = pos.y + trayItem.height;

                        anchor.rect.width = 1;
                        anchor.rect.height = 1;
                    }

                    visible: mouseArea.containsMouse && !mouseArea.dragging && trayItem.tipString.length > 0

                    color: "transparent"

                    implicitWidth: tipBox.implicitWidth
                    implicitHeight: tipBox.implicitHeight

                    Rectangle {
                        id: tipBox

                        anchors.fill: parent

                        color: Theme.background
                        border.color: Theme.borderColor
                        border.width: 1
                        radius: 8

                        implicitWidth: tipText.implicitWidth + 16
                        implicitHeight: tipText.implicitHeight + 12

                        Text {
                            id: tipText

                            anchors.centerIn: parent

                            renderType: Theme.textRenderType
                            renderTypeQuality: Theme.textRenderQuality
                            font.hintingPreference: Theme.fontHinting

                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall

                            color: Theme.text
                            text: trayItem.tipString
                        }
                    }
                }
            }
        }
    }
}

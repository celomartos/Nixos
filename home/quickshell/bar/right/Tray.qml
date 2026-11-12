import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../theme"

Item {
    id: root

    implicitHeight: Theme.barHeight
    implicitWidth: trayRow.implicitWidth > 0 ? (trayRow.implicitWidth + 20) : 0
    visible: trayRow.implicitWidth > 0

    Row {
        id: trayRow
        anchors.centerIn: parent
        spacing: 8 // Reduzido de 10 para 8 (mais compacto)

        Repeater {
            model: SystemTray.items

            delegate: Rectangle {
                id: trayItem
                required property var modelData

                visible: modelData.status !== Status.Passive

                implicitWidth: 32
                implicitHeight: 24
                radius: 16
                color: mouseArea.containsMouse ? Theme.hoverBackground : "transparent"

                Behavior on color {
                    ColorAnimation { duration: Theme.animDuration }
                }

                IconImage {
                    id: iconImg
                    anchors.centerIn: parent
                    source: trayItem.modelData.icon
                    implicitSize: 16
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
                    cursorShape: Qt.PointingHandCursor

                    onClicked: mouse => {
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

                readonly property string tipString: {
                    let t = (trayItem.modelData.tooltipTitle || trayItem.modelData.title || "").trim();
                    let d = (trayItem.modelData.tooltipDescription || "").trim();
                    if (t && d && t !== d) return t + "\n" + d;
                    return t || d;
                }
                PopupWindow {
                    id: tooltipPopup

                    anchor.window: trayItem.QsWindow.window

                    anchor.edges: Edges.Top | Edges.Left
                    anchor.gravity: Edges.Bottom | Edges.Right
                    anchor.adjustment: PopupAdjustment.SlideX

                    anchor.onAnchoring: {
                        const pos = trayItem.mapToItem(
                            trayItem.QsWindow.window.contentItem,
                            0,
                            0
                        );

                        anchor.rect.x = pos.x + (trayItem.width - width) / 2;
                        anchor.rect.y = pos.y + trayItem.height;
                        anchor.rect.width = 1;
                        anchor.rect.height = 1;
                    }

                    visible: mouseArea.containsMouse && trayItem.tipString.length > 0

                    color: "transparent"

                    width: tipBox.implicitWidth
                    height: tipBox.implicitHeight

                    Rectangle {
                        id: tipBox

                        anchors.fill: parent

                        color: Theme.background
                        border.color: Theme.borderColor
                        border.width: 1
                        radius: 8

                        // Padding reduzido para ficar igual aos outros tooltips
                        implicitWidth: tipText.implicitWidth + 16
                        implicitHeight: tipText.implicitHeight + 12

                        Text {
                            id: tipText

                            anchors.centerIn: parent
                            
                            // Renderização de alta qualidade
                            renderType: Theme.textRenderType
                            renderTypeQuality: Theme.textRenderQuality
                            font.hintingPreference: Theme.fontHinting
                            
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall // Era Theme.fontSize - 3
                            color: Theme.text

                            text: trayItem.tipString
                        }
                    }
                }
            }
        }
    }
}

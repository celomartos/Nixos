
import QtQuick
import Quickshell
import "../../theme"

PopupWindow {
    id: root

    required property Item anchorItem

    anchor.window: anchorItem ? anchorItem.QsWindow.window : null
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.SlideX

    anchor.onAnchoring: {
        if (!anchorItem || !anchorItem.QsWindow.window)
            return;

        const window = anchorItem.QsWindow.window;
        const pos = anchorItem.mapToItem(
            window.contentItem,
            0,
            0
        );

        anchor.rect.x = pos.x + (anchorItem.width - width) / 2;
        anchor.rect.y = pos.y + anchorItem.height;
        anchor.rect.width = 1;
        anchor.rect.height = 1;
    }

    implicitWidth: 320
    implicitHeight: col.implicitHeight + 48
    color: "transparent"

    property int monthOffset: 0
    property var currentDate: new Date()

    readonly property var today: currentDate

    readonly property var displayedDate: new Date(
        currentDate.getFullYear(),
        currentDate.getMonth() + monthOffset,
        1
    )

    readonly property alias hovered: popupMouseArea.containsMouse

    function resetToCurrentMonth() {
        monthOffset = 0;
    }

    function shiftUp() {
        monthOffset -= 1;
    }

    function shiftDown() {
        monthOffset += 1;
    }

    // Atualiza a data ao abrir o calendário.
    onVisibleChanged: {
        if (visible)
            currentDate = new Date();
    }

    // Mantém a data atualizada enquanto o calendário estiver aberto.
    Timer {
        interval: 60000
        repeat: true
        running: root.visible

        onTriggered: {
            root.currentDate = new Date();
        }
    }

    Rectangle {
        id: bg

        anchors.fill: parent
        color: Theme.background
        border.color: Theme.borderColor
        border.width: 1
        radius: 16

        MouseArea {
            id: popupMouseArea

            anchors.fill: parent
            hoverEnabled: true

            onWheel: wheel => {
                if (wheel.angleDelta.y > 0)
                    root.shiftUp();
                else
                    root.shiftDown();
            }
        }

        Column {
            id: col

            anchors.centerIn: parent
            spacing: 12
            width: 272

            // Mês e ano
            Text {
                anchors.horizontalCenter: parent.horizontalCenter

                font.family: Theme.fontFamily
                font.pixelSize: 20
                font.weight: Font.Bold

                color: Theme.text

                text: root.displayedDate.toLocaleDateString(
                    Qt.locale("en_US"),
                    "MMMM yyyy"
                )
            }

            // Dias da semana
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Repeater {
                    model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

                    delegate: Text {
                        required property string modelData

                        width: 32
                        horizontalAlignment: Text.AlignHCenter

                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.Bold

                        color: Theme.text
                        text: modelData
                    }
                }
            }

            // Grade do calendário
            Grid {
                id: grid

                anchors.horizontalCenter: parent.horizontalCenter

                columns: 7
                spacing: 8

                readonly property int firstDayOfWeek:
                    root.displayedDate.getDay()

                readonly property int daysInMonth:
                    new Date(
                        root.displayedDate.getFullYear(),
                        root.displayedDate.getMonth() + 1,
                        0
                    ).getDate()

                readonly property int totalCells:
                    Math.ceil((firstDayOfWeek + daysInMonth) / 7) * 7

                Repeater {
                    model: grid.totalCells

                    delegate: Item {
                        required property int index

                        readonly property int dayNumber:
                            index - grid.firstDayOfWeek + 1

                        readonly property bool isValidDay:
                            dayNumber >= 1 && dayNumber <= grid.daysInMonth

                        readonly property bool isToday:
                            isValidDay &&
                            dayNumber === root.today.getDate() &&
                            root.displayedDate.getMonth() === root.today.getMonth() &&
                            root.displayedDate.getFullYear() === root.today.getFullYear()

                        width: 32
                        height: 28

                        Rectangle {
                            anchors.fill: parent

                            visible: parent.isToday
                            color: "#ffffff"
                            radius: 6
                        }

                        Text {
                            anchors.centerIn: parent

                            visible: parent.isValidDay

                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            font.weight: parent.isToday
                                ? Font.Bold
                                : Font.Normal

                            color: parent.isToday
                                ? "#000000"
                                : "#dddddd"

                            text: parent.isValidDay
                                ? parent.dayNumber
                                : ""
                        }
                    }
                }
            }
        }
    }
}


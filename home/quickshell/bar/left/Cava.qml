import QtQuick
import Quickshell
import "../../theme"
import "../../components"
import "../../services"

Item {
    id: root

    implicitHeight: Theme.barHeight

    readonly property int fixedCavaWidth: 160

    implicitWidth: fixedCavaWidth + (Theme.itemPaddingHorizontal * 2)

    readonly property var glyphs: ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]

    function getVisualizerText() {
        const values = CavaService.levels;
        const displayCount = 16;

        let output = "";

        for (let i = 0; i < displayCount; i++) {
            const sourceIndex = Math.floor(i * values.length / displayCount);

            const level = Math.max(0, Math.min(7, Math.round(values[sourceIndex] || 0)));

            output += glyphs[level];
        }

        return output;
    }

    BarItem {
        id: barItem

        anchors.fill: parent
        clickable: false

        Text {
            width: root.fixedCavaWidth
            height: Theme.barHeight

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            renderType: Theme.textRenderType
            renderTypeQuality: Theme.textRenderQuality
            font.hintingPreference: Theme.fontHinting

            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight

            color: Theme.text

            text: root.getVisualizerText()

            clip: true
        }
    }
}

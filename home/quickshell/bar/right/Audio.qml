import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../../theme"
import "../../components"

Item {
    id: root

    implicitHeight: Theme.barHeight
    implicitWidth: audioItem.implicitWidth

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: (sink && sink.ready && sink.audio) ? sink.audio.volume : 0.0
    readonly property bool muted: (sink && sink.ready && sink.audio) ? sink.audio.muted : false
    readonly property int volumePercent: Math.round(root.volume * 100)

    // Rastreia e vincula propriedades reativas do sink ativo
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    function getAudioIcon() {
        if (root.muted) return "󰖁"; // Ícone de mudo
        if (root.volumePercent <= 33) return "";
        if (root.volumePercent <= 66) return "";
        return "";
    }

    BarItem {
        id: audioItem
        anchors.centerIn: parent
        clickable: true
        
        // Removido o espaço duplo e adicionado o ícone de mudo
        text: root.getAudioIcon() + "  " + root.volumePercent + "%"

        onClicked: {
            if (root.sink && root.sink.ready && root.sink.audio) {
                root.sink.audio.muted = !root.sink.audio.muted;
            }
        }

        onWheel: wheel => {
            if (root.sink && root.sink.ready && root.sink.audio) {
                var currentVol = root.sink.audio.volume;
                var delta = (wheel.angleDelta.y > 0) ? 0.05 : -0.05;
                var nextVol = Math.round((currentVol + delta) * 20) / 20;
                if (nextVol < 0.0) nextVol = 0.0;
                if (nextVol > 1.0) nextVol = 1.0;
                root.sink.audio.volume = nextVol;
                if (root.sink.audio.muted && delta > 0) {
                    root.sink.audio.muted = false;
                }
            }
        }
    }
}

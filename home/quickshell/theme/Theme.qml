pragma Singleton
import QtQuick

QtObject {
    // Cores base
    readonly property color background: "#000000"
    readonly property color borderColor: Qt.rgba(1, 1, 1, 0.2)
    readonly property color hoverBackground: "#3c3c3c"
    readonly property color text: "#ffffff"
    readonly property color textMuted: "#a6adc8"
    readonly property color textDanger: "#f38ba8"

    // Tipografia
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 16
    readonly property int fontWeight: Font.DemiBold

    // Geometria
    readonly property int barHeight: 32
    readonly property int borderBottomWidth: 2
    readonly property int itemRadius: 12
    readonly property int itemPaddingHorizontal: 12
    readonly property int itemSpacing: 8
    readonly property int animDuration: 100
}

pragma Singleton
import QtQuick

QtObject {
    // Escala global (1.0 = 100%). Útil para HiDPI ou ajuste fino.
    readonly property real scale: 1.0

    // Cores base
    readonly property color background: "#000000"
    readonly property color borderColor: Qt.rgba(1, 1, 1, 0.2)
    readonly property color hoverBackground: "#3c3c3c"
    readonly property color text: "#ffffff"
    readonly property color textMuted: "#a6adc8"
    readonly property color textDanger: "#f38ba8"

    // Tipografia — famílias
    readonly property string fontFamily: "JetBrainsMono Nerd Font"

    // Tipografia — tamanhos (derivados da escala)
    readonly property int fontSizeSmall: Math.round(12 * scale)
    readonly property int fontSize:      Math.round(16 * scale) // 15 costuma preencher melhor a barra de 32px que 16
    readonly property int fontSizeLarge: Math.round(18 * scale)

    // Tipografia — pesos (use enums: mapeiam para os pesos reais da fonte)
    // Se achar que ainda está fino, troque para Font.Bold
    readonly property int fontWeight:      Font.DemiBold 
    readonly property int fontWeightBold:  Font.Bold

    // Tipografia — ajustes finos
    readonly property real letterSpacing: 0
    readonly property real lineHeightMultiplier: 1.0
    
    // Dica: Use este offset no Text dos ícones para centralizar com o texto
    readonly property int iconVerticalOffset: -1   

    // Renderização
    // NativeRendering pega o hinting do sistema (mais parecido com Waybar)
    readonly property int textRenderType: Text.NativeRendering 
    readonly property int textRenderQuality: Text.VeryHighRenderTypeQuality
    readonly property int fontHinting: Font.PreferFullHinting

    // Geometria
    readonly property int barHeight: 32
    readonly property int borderBottomWidth: 2
    readonly property int itemRadius: 12
    readonly property int itemPaddingHorizontal: 10 // Reduzido (era 12)
    readonly property int itemSpacing: 6            // Reduzido (era 8)
    readonly property int animDuration: 100
}

pragma Singleton
import QtQuick

QtObject {
    // ============================================================
    // COLOR PALETTE — edit only this block
    // ============================================================
    // Format: "#RRGGBB", "#RRGGBBAA" or Qt.rgba(r, g, b, a)
    // where r, g, b ∈ [0, 1] and a ∈ [0, 1].

    // Backgrounds
    property color paletteBackground: "#000000"
    property color paletteCard: Qt.rgba(1, 1, 1, 0.035)
    property color paletteHover: "#3c3c3c"

    // Text
    property color paletteText: "#ffffff"
    property color paletteTextMuted: "#a6adc8"
    property color paletteTextDanger: "#FF828C"

    // Borders and dividers
    property color paletteBorder: Qt.rgba(1, 1, 1, 0.2)
    property color paletteDivider: Qt.rgba(1, 1, 1, 0.12)

    // Accent
    property color paletteAccent: "#ffffff"
    property color paletteAccentText: "#000000"

    // ============================================================
    // SEMANTIC COLOR TOKENS — do not edit, use these in components
    // ============================================================

    readonly property color background: paletteBackground
    readonly property color cardBackground: paletteCard
    readonly property color hoverBackground: paletteHover

    readonly property color text: paletteText
    readonly property color textMuted: paletteTextMuted
    readonly property color textDanger: paletteTextDanger

    readonly property color borderColor: paletteBorder
    readonly property color progressTrack: paletteDivider

    readonly property color todayBackground: paletteAccent
    readonly property color todayText: paletteAccentText

    // ============================================================
    // TYPOGRAPHY
    // ============================================================

    // Global scale (1.0 = 100%). Useful for HiDPI or fine tuning.
    readonly property real scale: 1.0

    readonly property string fontFamily: "Inter Regular"

    readonly property int fontSizeSmall: Math.round(12 * scale)
    readonly property int fontSize: Math.round(16 * scale)
    readonly property int fontSizeLarge: Math.round(18 * scale)

    readonly property int fontWeight: Font.Medium
    readonly property int fontWeightBold: Font.DemiBold

    readonly property real letterSpacing: 0
    readonly property real lineHeightMultiplier: 1.0

    // Vertical offset to align icons with adjacent text.
    readonly property int iconVerticalOffset: -1

    // ============================================================
    // TEXT RENDERING
    // ============================================================

    readonly property int textRenderType: Text.NativeRendering
    readonly property int textRenderQuality: Text.VeryHighRenderTypeQuality
    readonly property int fontHinting: Font.PreferFullHinting

    // ============================================================
    // RADII
    // ============================================================

    readonly property int radiusSm: 6
    readonly property int radiusMd: 10
    readonly property int radiusLg: 12
    readonly property int radiusXl: 16
    readonly property int radiusPill: 9999

    // ============================================================
    // SPACING
    // ============================================================

    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacingMd: 12
    readonly property int spacingLg: 16
    readonly property int spacingXl: 24

    // ============================================================
    // COMPONENT GEOMETRY
    // ============================================================

    readonly property int barHeight: 32
    readonly property int borderBottomWidth: 2
    readonly property int itemRadius: radiusLg
    readonly property int itemPaddingHorizontal: 10
    readonly property int itemSpacing: 6

    // ============================================================
    // ANIMATION
    // ============================================================

    readonly property int animDurationFast: 120
    readonly property int animDuration: 100
    readonly property int animDurationNormal: 180
    readonly property int animDurationSlow: 280

    // ============================================================
    // OPACITY
    // ============================================================

    readonly property real opacityDisabled: 0.35
}

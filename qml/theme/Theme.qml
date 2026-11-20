pragma Singleton
import QtQuick

QtObject {
    id: root

    property SystemPalette palette: SystemPalette {
        colorGroup: SystemPalette.Active
    }

    readonly property bool isDark: (palette.window.r * 0.299 + palette.window.g * 0.587 + palette.window.b * 0.114) < 0.5

    // System-integrated surfaces & text (follows KDE / Windows color scheme)
    readonly property color bgPrimary: palette.window
    readonly property color bgHeader: palette.window
    readonly property color bgSurface: isDark ? Qt.lighter(palette.window, 1.18) : palette.base
    readonly property color bgElevated: isDark ? Qt.lighter(palette.window, 1.32) : palette.alternateBase
    readonly property color bgInput: palette.base
    readonly property color border: Qt.rgba(palette.windowText.r, palette.windowText.g, palette.windowText.b, isDark ? 0.14 : 0.16)
    readonly property color separator: Qt.rgba(palette.windowText.r, palette.windowText.g, palette.windowText.b, isDark ? 0.10 : 0.12)

    readonly property color textPrimary: palette.windowText
    readonly property color textSecondary: Qt.rgba(palette.windowText.r, palette.windowText.g, palette.windowText.b, 0.72)
    readonly property color textMuted: Qt.rgba(palette.windowText.r, palette.windowText.g, palette.windowText.b, 0.52)

    // System Accent & Semantic Colors
    readonly property color accent: palette.highlight
    readonly property color accentText: palette.highlightedText
    readonly property color success: isDark ? "#33D17A" : "#1E8E4F"
    readonly property color warning: isDark ? "#F5C211" : "#B57B00"
    readonly property color error: isDark ? "#E01B24" : "#C01C28"
    readonly property color errorText: isDark ? "#FF7B63" : "#A51D2D"
    readonly property color errorSoft: Qt.rgba(error.r, error.g, error.b, isDark ? 0.18 : 0.10)

    // Energy Domain Accents
    readonly property color solar: isDark ? "#F5C211" : "#D48806"
    readonly property color solarSoft: Qt.rgba(solar.r, solar.g, solar.b, isDark ? 0.16 : 0.12)
    readonly property color battery: isDark ? "#33D17A" : "#1E8E4F"
    readonly property color batterySoft: Qt.rgba(battery.r, battery.g, battery.b, isDark ? 0.16 : 0.12)
    readonly property color grid: isDark ? "#62A0EA" : "#1C71D8"
    readonly property color gridSoft: Qt.rgba(grid.r, grid.g, grid.b, isDark ? 0.16 : 0.12)
    readonly property color load: isDark ? "#C061CB" : "#813D9C"
    readonly property color loadSoft: Qt.rgba(load.r, load.g, load.b, isDark ? 0.16 : 0.12)

    // Spacing & Radii
    readonly property int radiusSm: 6
    readonly property int radiusMd: 9
    readonly property int radiusLg: 12
    readonly property int radiusPill: 999
    readonly property int spacingSm: 6
    readonly property int spacingMd: 12
    readonly property int spacingLg: 18
}

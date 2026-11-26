pragma Singleton
import QtQuick

QtObject {
    id: root

    property SystemPalette palette: SystemPalette {
        colorGroup: SystemPalette.Active
    }

    readonly property bool isDark: (palette.window.r * 0.299 + palette.window.g * 0.587 + palette.window.b * 0.114) < 0.5

    // System-integrated surfaces & text (follows KDE / Windows / GNOME color scheme)
    readonly property color bgPrimary: palette.window
    readonly property color bgHeader: palette.window
    readonly property color bgSurface: isDark ? Qt.lighter(palette.window, 1.14) : palette.base
    readonly property color bgElevated: isDark ? Qt.lighter(palette.window, 1.26) : palette.alternateBase
    readonly property color bgInput: palette.base
    readonly property color border: Qt.rgba(palette.windowText.r, palette.windowText.g, palette.windowText.b, isDark ? 0.09 : 0.10)
    readonly property color separator: Qt.rgba(palette.windowText.r, palette.windowText.g, palette.windowText.b, isDark ? 0.07 : 0.08)

    readonly property color textPrimary: palette.windowText
    readonly property color textSecondary: Qt.rgba(palette.windowText.r, palette.windowText.g, palette.windowText.b, 0.70)
    readonly property color textMuted: Qt.rgba(palette.windowText.r, palette.windowText.g, palette.windowText.b, 0.54)

    // System Accent & Semantic Colors (toned to sit cleanly inside native ramps)
    readonly property color accent: palette.highlight
    readonly property color accentText: palette.highlightedText
    readonly property color success: isDark ? "#4CC38A" : "#16A34A"
    readonly property color warning: isDark ? "#E5B94C" : "#B47B00"
    readonly property color error: isDark ? "#E5484D" : "#DC2626"
    readonly property color errorText: isDark ? "#F27175" : "#B91C1C"
    readonly property color errorSoft: Qt.rgba(error.r, error.g, error.b, isDark ? 0.14 : 0.08)

    // Unified Energy Domain Accents (shared across Flow Graph, KPI cards & Charts)
    readonly property color solar: isDark ? "#E5B94C" : "#C67F00"
    readonly property color solarSoft: Qt.rgba(solar.r, solar.g, solar.b, isDark ? 0.14 : 0.10)
    readonly property color battery: isDark ? "#4CC38A" : "#16A34A"
    readonly property color batterySoft: Qt.rgba(battery.r, battery.g, battery.b, isDark ? 0.14 : 0.10)
    readonly property color grid: isDark ? "#5B9DF2" : "#2563EB"
    readonly property color gridSoft: Qt.rgba(grid.r, grid.g, grid.b, isDark ? 0.14 : 0.10)
    readonly property color load: isDark ? "#A78BFA" : "#7C3AED"
    readonly property color loadSoft: Qt.rgba(load.r, load.g, load.b, isDark ? 0.14 : 0.10)

    // Typography helper
    readonly property string monoFamily: "monospace"

    // 4px Spacing & Nested Radii Scale
    readonly property int radiusSm: 6
    readonly property int radiusMd: 8
    readonly property int radiusLg: 12
    readonly property int radiusPill: 999
    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacingMd: 12
    readonly property int spacingLg: 16
    readonly property int spacingXl: 24
    readonly property int cardPadding: 20
    readonly property int rowPadding: 16
    readonly property int pageMargin: 24
}

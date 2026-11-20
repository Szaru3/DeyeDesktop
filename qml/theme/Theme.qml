pragma Singleton
import QtQuick

QtObject {
    // Authentic Libadwaita Dark Palette (GNOME HIG)
    readonly property color bgPrimary: "#242424"        // --window-bg-color
    readonly property color bgHeader: "#303030"         // --headerbar-bg-color
    readonly property color bgSurface: "#303030"        // --card-bg-color / boxed-list
    readonly property color bgElevated: "#383838"       // popover / hover surface
    readonly property color bgInput: "#1E1E1E"          // --view-bg-color
    readonly property color bgButton: "#3A3A3A"
    readonly property color bgButtonHover: "#454545"
    readonly property color border: "#3F3F3F"           // subtle hairline border
    readonly property color separator: "#3B3B3B"
    readonly property color borderFocus: "#3584E4"      // --accent-bg-color

    readonly property color textPrimary: "#FFFFFF"
    readonly property color textSecondary: "#B8B8B8"
    readonly property color textMuted: "#8C8C8C"

    // Libadwaita Semantic Accents
    readonly property color accent: "#3584E4"           // Adwaita Blue 3 (suggested-action)
    readonly property color accentHover: "#4A94EB"
    readonly property color accentText: "#78AEED"
    readonly property color success: "#33D17A"          // Adwaita Green 3
    readonly property color warning: "#F5C211"          // Adwaita Yellow 4
    readonly property color error: "#E01B24"            // Adwaita Red 3 (destructive)
    readonly property color errorText: "#FF7B63"
    readonly property color errorSoft: "#3A2224"

    // Energy Domain Accents (harmonized with Adwaita palette)
    readonly property color solar: "#F5C211"
    readonly property color solarSoft: "#353020"
    readonly property color battery: "#33D17A"
    readonly property color batterySoft: "#223329"
    readonly property color grid: "#62A0EA"
    readonly property color gridSoft: "#232D3B"
    readonly property color load: "#C061CB"
    readonly property color loadSoft: "#322536"

    // Spacing & Radii (Adwaita HIG)
    readonly property int radiusSm: 6
    readonly property int radiusMd: 9
    readonly property int radiusLg: 12
    readonly property int radiusPill: 999
    readonly property int spacingSm: 6
    readonly property int spacingMd: 12
    readonly property int spacingLg: 18
}

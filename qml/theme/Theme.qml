pragma Singleton
import QtQuick

QtObject {
    // Palette — Dark Slate Energy Dashboard
    readonly property color bgPrimary: "#0B1120"
    readonly property color bgSurface: "#131C31"
    readonly property color bgElevated: "#1C2841"
    readonly property color bgInput: "#0F172A"
    readonly property color border: "#2A3955"
    readonly property color borderFocus: "#38BDF8"

    readonly property color textPrimary: "#F8FAFC"
    readonly property color textSecondary: "#94A3B8"
    readonly property color textMuted: "#64748B"

    // Energy Domain Accents
    readonly property color solar: "#F59E0B"
    readonly property color solarSoft: "#292212"
    readonly property color battery: "#10B981"
    readonly property color batterySoft: "#0E2922"
    readonly property color grid: "#38BDF8"
    readonly property color gridSoft: "#0E2436"
    readonly property color load: "#A78BFA"
    readonly property color loadSoft: "#221A36"

    // Status
    readonly property color success: "#10B981"
    readonly property color warning: "#F59E0B"
    readonly property color error: "#F43F5E"
    readonly property color errorSoft: "#331420"
    readonly property color accent: "#38BDF8"
    readonly property color accentHover: "#0EA5E9"

    // Spacing & Radius
    readonly property int radiusSm: 6
    readonly property int radiusMd: 10
    readonly property int radiusLg: 14
    readonly property int spacingSm: 8
    readonly property int spacingMd: 14
    readonly property int spacingLg: 20
}

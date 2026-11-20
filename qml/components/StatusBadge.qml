import QtQuick
import DeyeDesktop

Rectangle {
    id: root

    property string status: "UNKNOWN"

    readonly property bool isOnline: status === "NORMAL" || status === "ONLINE"
    readonly property bool isPartial: status === "PARTIAL_OFFLINE"
    readonly property bool isOffline: status === "ALL_OFFLINE" || status === "OFFLINE"

    readonly property color badgeColor: isOnline ? Theme.success
                                      : isPartial ? Theme.warning
                                      : isOffline ? Theme.errorText
                                      : Theme.textMuted

    readonly property string labelText: isOnline ? "Online"
                                      : isPartial ? "Partial"
                                      : isOffline ? "Offline"
                                      : "Unknown"

    implicitWidth: row.implicitWidth + 16
    implicitHeight: 24
    radius: Theme.radiusPill
    color: Qt.rgba(badgeColor.r, badgeColor.g, badgeColor.b, 0.15)
    border.color: Qt.rgba(badgeColor.r, badgeColor.g, badgeColor.b, 0.30)
    border.width: 1

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Rectangle {
            width: 7
            height: 7
            radius: 3.5
            color: root.badgeColor
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.labelText
            color: root.badgeColor
            font.pixelSize: 12
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}

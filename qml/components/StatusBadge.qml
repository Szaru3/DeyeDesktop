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
                                      : isOffline ? Theme.error
                                      : Theme.textMuted

    readonly property string labelText: isOnline ? "Online"
                                      : isPartial ? "Partial"
                                      : isOffline ? "Offline"
                                      : "Unknown"

    implicitWidth: row.implicitWidth + 18
    implicitHeight: 26
    radius: 13
    color: Qt.rgba(badgeColor.r, badgeColor.g, badgeColor.b, 0.16)
    border.color: Qt.rgba(badgeColor.r, badgeColor.g, badgeColor.b, 0.45)
    border.width: 1

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Rectangle {
            width: 8
            height: 8
            radius: 4
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

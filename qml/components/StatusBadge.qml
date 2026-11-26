import QtQuick
import DeyeDesktop

Item {
    id: root

    property string status: "UNKNOWN"

    readonly property bool isOnline: status === "NORMAL" || status === "ONLINE"
    readonly property bool isPartial: status === "PARTIAL_OFFLINE"
    readonly property bool isOffline: status === "ALL_OFFLINE" || status === "OFFLINE"

    readonly property color badgeColor: isOnline ? Theme.success
                                      : isPartial ? Theme.warning
                                      : isOffline ? Theme.errorText
                                      : Theme.textMuted

    readonly property string labelText: isOnline ? I18n.t("Online")
                                      : isPartial ? I18n.t("Partial")
                                      : isOffline ? I18n.t("Offline")
                                      : I18n.t("Unknown")

    implicitWidth: row.implicitWidth + 4
    implicitHeight: 24

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        spacing: 8

        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: root.badgeColor
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.labelText
            color: (root.isPartial || root.isOffline) ? root.badgeColor : Theme.textSecondary
            font.pixelSize: 12
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}

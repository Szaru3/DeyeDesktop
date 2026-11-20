import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import DeyeDesktop

Rectangle {
    id: root
    color: Theme.bgPrimary

    // 0: Overview, 1: Devices, 2: Alerts, 3: Plant Info
    property int currentSection: 0
    readonly property var sectionTitles: ["Overview", "Devices", "Alerts", "Plant Info"]

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Native-styled Header Bar
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 54
            color: Theme.bgHeader

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Theme.separator
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 14
                spacing: 10

                // Hamburger Menu Button (replaces DeyeDesktop logo)
                ToolButton {
                    id: menuButton
                    text: "☰"
                    font.pixelSize: 17
                    ToolTip.visible: hovered
                    ToolTip.text: "Navigation menu"
                    onClicked: navMenu.open()

                    ButtonGroup {
                        id: navGroup
                        exclusive: true
                    }

                    Menu {
                        id: navMenu
                        y: menuButton.height + 4

                        MenuItem {
                            text: "Overview"
                            checkable: true
                            autoExclusive: true
                            ButtonGroup.group: navGroup
                            checked: root.currentSection === 0
                            onTriggered: root.currentSection = 0
                        }
                        MenuItem {
                            text: "Devices"
                            checkable: true
                            autoExclusive: true
                            ButtonGroup.group: navGroup
                            checked: root.currentSection === 1
                            onTriggered: root.currentSection = 1
                        }
                        MenuItem {
                            text: "Alerts"
                            checkable: true
                            autoExclusive: true
                            ButtonGroup.group: navGroup
                            checked: root.currentSection === 2
                            onTriggered: root.currentSection = 2
                        }
                        MenuItem {
                            text: "Plant Info"
                            checkable: true
                            autoExclusive: true
                            ButtonGroup.group: navGroup
                            checked: root.currentSection === 3
                            onTriggered: root.currentSection = 3
                        }
                    }
                }

                // Active section label (fixed width so header items stay stationary)
                Label {
                    Layout.preferredWidth: 86
                    text: root.sectionTitles[root.currentSection]
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                // Demo Pill
                Rectangle {
                    visible: appController.demoMode
                    implicitWidth: demoLbl.implicitWidth + 12
                    implicitHeight: 20
                    radius: Theme.radiusPill
                    color: Theme.solarSoft
                    border.color: Qt.rgba(Theme.solar.r, Theme.solar.g, Theme.solar.b, 0.5)
                    Label {
                        id: demoLbl
                        anchors.centerIn: parent
                        text: "DEMO"
                        color: Theme.solar
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }

                // Native Plant / Station Selector (shows plant name + address in menu)
                ComboBox {
                    id: stationCombo
                    Layout.preferredWidth: 280
                    Layout.maximumWidth: 360
                    model: appController.stationModel
                    textRole: "name"
                    currentIndex: appController.selectedStationIndex
                    popup.width: Math.max(width, 340)
                    onActivated: function(idx) {
                        appController.selectStationByIndex(idx)
                    }

                    delegate: ItemDelegate {
                        id: plantDelegate
                        width: ListView.view ? ListView.view.width : 328
                        implicitHeight: model.location && model.location.length > 0 ? 52 : 36
                        highlighted: stationCombo.highlightedIndex === index

                        readonly property color dotColor: (model.connectionStatus === "NORMAL" || model.connectionStatus === "ONLINE")
                                                          ? Theme.success
                                                          : (model.connectionStatus === "PARTIAL_OFFLINE")
                                                            ? Theme.warning
                                                            : (model.connectionStatus === "ALL_OFFLINE" || model.connectionStatus === "OFFLINE")
                                                              ? Theme.errorText
                                                              : Theme.textMuted

                        contentItem: RowLayout {
                            spacing: 10

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: plantDelegate.dotColor
                                Layout.alignment: Qt.AlignVCenter
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Label {
                                    Layout.fillWidth: true
                                    text: model.name
                                    font.weight: stationCombo.currentIndex === index ? Font.Bold : Font.Normal
                                    color: plantDelegate.highlighted ? Theme.accentText : Theme.textPrimary
                                    elide: Text.ElideRight
                                }

                                Label {
                                    Layout.fillWidth: true
                                    visible: model.location && model.location.length > 0
                                    text: model.location
                                    font.pixelSize: 11
                                    color: plantDelegate.highlighted ? Theme.accentText : Theme.textSecondary
                                    opacity: plantDelegate.highlighted ? 0.85 : 1.0
                                    elide: Text.ElideRight
                                }
                            }

                            Label {
                                visible: model.installedCapacityKw > 0
                                text: model.installedCapacityKw.toFixed(1) + " kWp"
                                font.pixelSize: 11
                                color: plantDelegate.highlighted ? Theme.accentText : Theme.textMuted
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }

                StatusBadge {
                    status: appController.connectionStatus
                }

                Item { Layout.fillWidth: true }

                // Red Sign Out Button
                Button {
                    id: signOutButton
                    implicitHeight: 32
                    leftPadding: 14
                    rightPadding: 14
                    text: "Sign Out"
                    onClicked: appController.logout()

                    contentItem: Label {
                        text: signOutButton.text
                        color: "#FFFFFF"
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: Theme.radiusSm
                        color: signOutButton.down
                               ? Qt.darker(Theme.error, 1.15)
                               : signOutButton.hovered
                                 ? Qt.lighter(Theme.error, 1.12)
                                 : Theme.error
                    }
                }
            }
        }

        // Scrollable AdwClamp Dashboard Body
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: bodyColumn.implicitHeight + 48
            clip: true

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id: bodyColumn
                width: Math.min(980, parent.width - 40)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 22
                spacing: 16

                // Error Banner
                Rectangle {
                    visible: appController.errorMessage.length > 0
                    Layout.fillWidth: true
                    implicitHeight: dashErr.implicitHeight + 18
                    radius: Theme.radiusMd
                    color: Theme.errorSoft
                    border.color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.55)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        Label {
                            id: dashErr
                            Layout.fillWidth: true
                            text: appController.errorMessage
                            color: Theme.errorText
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                        Button {
                            flat: true
                            text: "Dismiss"
                            onClicked: appController.clearError()
                        }
                    }
                }

                // Station Summary Strip
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        spacing: 3
                        Label {
                            text: appController.selectedStationName || "No Plant Selected"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                        }
                        Label {
                            text: {
                                var parts = [];
                                if (appController.installedCapacityKw > 0)
                                    parts.push(appController.installedCapacityKw.toFixed(1) + " kWp");
                                if (appController.selectedStationLocation.length > 0)
                                    parts.push(appController.selectedStationLocation);
                                return parts.length > 0 ? parts.join("  •  ") : "Real-time plant overview";
                            }
                            color: Theme.textSecondary
                            font.pixelSize: 13
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: "Updated " + appController.lastUpdateText
                        color: Theme.textMuted
                        font.pixelSize: 12
                    }
                }

                // Section 0: Overview
                ColumnLayout {
                    visible: root.currentSection === 0
                    Layout.fillWidth: true
                    spacing: 16

                    PowerFlowDiagram {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 300
                        generationPowerW: appController.generationPowerW
                        consumptionPowerW: appController.consumptionPowerW
                        batteryPowerW: appController.batteryPowerW
                        batterySoc: appController.batterySoc
                        hasBatterySoc: appController.hasBatterySoc
                        gridPowerW: appController.gridPowerW
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: width >= 800 ? 4 : 2
                        columnSpacing: 12
                        rowSpacing: 12

                        MetricCard {
                            Layout.fillWidth: true
                            title: "Solar Generation"
                            valueText: appController.formatPower(appController.generationPowerW)
                            subtitle: appController.generationPowerW > 10 ? "Producing power" : "Standby / Night"
                            accentColor: Theme.solar
                        }

                        MetricCard {
                            Layout.fillWidth: true
                            title: "Battery"
                            valueText: appController.hasBatterySoc
                                       ? (Math.round(appController.batterySoc) + "%")
                                       : appController.formatPower(appController.batteryPowerW)
                            inlineSubtitle: {
                                var p = appController.formatPower(appController.batteryPowerW);
                                if (appController.batteryPowerW > 10) return "Charging • " + p;
                                if (appController.batteryPowerW < -10) return "Discharging • " + p;
                                return "Idle";
                            }
                            subtitle: ""
                            accentColor: Theme.battery
                            showProgress: appController.hasBatterySoc
                            progressValue: appController.batterySoc
                        }

                        MetricCard {
                            Layout.fillWidth: true
                            title: "Grid"
                            valueText: appController.formatPower(appController.gridPowerW)
                            subtitle: appController.gridPowerW > 10 ? "Importing from grid"
                                    : appController.gridPowerW < -10 ? "Exporting to grid"
                                    : "Balanced"
                            accentColor: Theme.grid
                        }

                        MetricCard {
                            Layout.fillWidth: true
                            title: "Home Load"
                            valueText: appController.formatPower(appController.consumptionPowerW)
                            subtitle: "Current consumption"
                            accentColor: Theme.load
                        }
                    }
                }

                // Section 1: Devices
                Rectangle {
                    visible: root.currentSection === 1
                    Layout.fillWidth: true
                    implicitHeight: appController.deviceCount > 0
                                    ? devicesListCol.implicitHeight
                                    : (devicesEmpty.implicitHeight + 48)
                    radius: Theme.radiusLg
                    color: Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        id: devicesEmpty
                        visible: appController.deviceCount === 0
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 24
                        spacing: 6

                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: appController.busy ? "Loading devices…" : "No Devices Found"
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }
                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No inverters, data loggers, or batteries were returned for this plant."
                            color: Theme.textSecondary
                        }
                    }

                    ColumnLayout {
                        id: devicesListCol
                        visible: appController.deviceCount > 0
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: 0

                        Repeater {
                            model: appController.deviceModel

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.margins: 14
                                    spacing: 12

                                    // Device Type Badge
                                    Rectangle {
                                        implicitWidth: typeLbl.implicitWidth + 16
                                        implicitHeight: 26
                                        radius: Theme.radiusSm
                                        color: Theme.bgElevated
                                        border.color: Theme.border
                                        border.width: 1

                                        Label {
                                            id: typeLbl
                                            anchors.centerIn: parent
                                            text: model.deviceType
                                            color: Theme.textSecondary
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    // Name, Model & Serial Number
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Label {
                                            Layout.fillWidth: true
                                            text: model.deviceName
                                            font.pixelSize: 14
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        Label {
                                            Layout.fillWidth: true
                                            text: {
                                                var parts = [];
                                                if (model.deviceSn.length > 0) parts.push("SN: " + model.deviceSn);
                                                if (model.productId.length > 0 && model.productId !== model.deviceName)
                                                    parts.push(model.productId);
                                                return parts.join("  •  ");
                                            }
                                            color: Theme.textSecondary
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                        }
                                    }

                                    // Last Seen
                                    Label {
                                        visible: model.lastSeenText !== "—"
                                        text: model.lastSeenText
                                        color: Theme.textMuted
                                        font.pixelSize: 11
                                    }

                                    // Online / Offline Badge
                                    StatusBadge {
                                        status: model.connectionStatus
                                    }

                                    // Inverter Settings Button
                                    Button {
                                        visible: model.deviceType === "Inverter" || model.deviceType === "Microinverter"
                                        text: "Settings"
                                        onClicked: {
                                            appController.openInverterSettings(model.deviceSn, model.deviceName)
                                            inverterSettingsDialog.open()
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: index < appController.deviceCount - 1
                                    Layout.fillWidth: true
                                    height: 1
                                    color: Theme.separator
                                }
                            }
                        }
                    }
                }

                // Section 2: Alerts
                Rectangle {
                    visible: root.currentSection === 2
                    Layout.fillWidth: true
                    implicitHeight: alertsPlaceholder.implicitHeight + 48
                    radius: Theme.radiusLg
                    color: Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        id: alertsPlaceholder
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 24
                        spacing: 6

                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Alerts"
                            font.pixelSize: 17
                            font.weight: Font.Bold
                        }
                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Active warnings and historical fault notifications for this plant will appear here."
                            color: Theme.textSecondary
                        }
                    }
                }

                // Section 3: Plant Info
                Rectangle {
                    visible: root.currentSection === 3
                    Layout.fillWidth: true
                    implicitHeight: plantInfoCol.implicitHeight + 8
                    radius: Theme.radiusLg
                    color: Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1

                    component InfoRow: ColumnLayout {
                        property string label: ""
                        property string value: ""
                        property bool showSeparator: true
                        Layout.fillWidth: true
                        spacing: 0

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.margins: 14
                            spacing: 12
                            Label {
                                text: label
                                color: Theme.textSecondary
                                Layout.preferredWidth: 180
                            }
                            Label {
                                text: value
                                font.weight: Font.Medium
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }
                        }

                        Rectangle {
                            visible: showSeparator
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.separator
                        }
                    }

                    ColumnLayout {
                        id: plantInfoCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: 0

                        InfoRow {
                            label: "Plant Name"
                            value: appController.selectedStationName || "—"
                        }
                        InfoRow {
                            label: "Plant ID"
                            value: appController.selectedStationId > 0 ? String(appController.selectedStationId) : "—"
                        }
                        InfoRow {
                            label: "Address"
                            value: appController.selectedStationLocation || "Not specified"
                        }
                        InfoRow {
                            label: "Installed Capacity"
                            value: appController.installedCapacityKw > 0
                                   ? (appController.installedCapacityKw.toFixed(2) + " kWp")
                                   : "—"
                        }
                        InfoRow {
                            label: "Connection Status"
                            value: appController.connectionStatus
                        }
                        InfoRow {
                            label: "Last Update"
                            value: appController.lastUpdateText
                            showSeparator: false
                        }
                    }
                }
            }
        }
    }

    InverterSettingsDialog {
        id: inverterSettingsDialog
    }
}

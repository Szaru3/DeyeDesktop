import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import DeyeDesktop

Rectangle {
    id: root
    color: Theme.bgPrimary

    // 0: Overview, 1: Devices, 2: Alerts, 3: Plant Info
    property int currentSection: 0
    readonly property var sectionKeys: ["Overview", "Devices", "Alerts", "Plant Info"]

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Native-styled Header Bar (equal 16px horizontal padding)
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
                anchors.leftMargin: Theme.cardPadding
                anchors.rightMargin: Theme.cardPadding
                spacing: Theme.spacingMd

                // Hamburger Menu Button
                ToolButton {
                    id: menuButton
                    text: "☰"
                    font.pixelSize: 17
                    ToolTip.visible: hovered
                    ToolTip.text: I18n.t("Navigation menu")
                    onClicked: navMenu.open()

                    ButtonGroup {
                        id: navGroup
                        exclusive: true
                    }

                    Menu {
                        id: navMenu
                        y: menuButton.height + 4

                        MenuItem {
                            text: I18n.t("Overview")
                            checkable: true
                            autoExclusive: true
                            ButtonGroup.group: navGroup
                            checked: root.currentSection === 0
                            onTriggered: root.currentSection = 0
                        }
                        MenuItem {
                            text: I18n.t("Devices")
                            checkable: true
                            autoExclusive: true
                            ButtonGroup.group: navGroup
                            checked: root.currentSection === 1
                            onTriggered: root.currentSection = 1
                        }
                        MenuItem {
                            text: appController.activeAlertCount > 0
                                  ? (I18n.t("Alerts") + " (" + appController.activeAlertCount + ")")
                                  : I18n.t("Alerts")
                            checkable: true
                            autoExclusive: true
                            ButtonGroup.group: navGroup
                            checked: root.currentSection === 2
                            onTriggered: root.currentSection = 2
                        }
                        MenuItem {
                            text: I18n.t("Plant Info")
                            checkable: true
                            autoExclusive: true
                            ButtonGroup.group: navGroup
                            checked: root.currentSection === 3
                            onTriggered: root.currentSection = 3
                        }
                    }
                }

                // Active section label (fixed width so plant selector never shifts)
                Label {
                    Layout.preferredWidth: 112
                    text: I18n.t(root.sectionKeys[root.currentSection])
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

                // Native Plant / Station Selector
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
                    text: I18n.t("Sign Out")
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

        // Scrollable Clamped Body (equal 20px margins & 16px spacing)
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: bodyColumn.implicitHeight + Theme.pageMargin * 2
            clip: true

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id: bodyColumn
                width: Math.min(980, parent.width - Theme.pageMargin * 2)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Theme.pageMargin
                spacing: Theme.spacingLg

                // Error Banner
                Rectangle {
                    visible: appController.errorMessage.length > 0
                    Layout.fillWidth: true
                    implicitHeight: dashErr.implicitHeight + 24
                    radius: Theme.radiusMd
                    color: Theme.errorSoft
                    border.color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.55)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
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
                            text: I18n.t("Dismiss")
                            onClicked: appController.clearError()
                        }
                    }
                }

                // Station Summary Strip
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingMd

                    ColumnLayout {
                        spacing: 3
                        Label {
                            text: appController.selectedStationName || I18n.t("No Plant Selected")
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
                                return parts.length > 0 ? parts.join("  •  ") : I18n.t("Real-time plant overview");
                            }
                            color: Theme.textSecondary
                            font.pixelSize: 13
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: I18n.t("Updated") + " " + appController.lastUpdateText
                        color: Theme.textMuted
                        font.pixelSize: 12
                    }
                }

                // ===================== SECTION 0: OVERVIEW =====================
                ColumnLayout {
                    visible: root.currentSection === 0
                    Layout.fillWidth: true
                    spacing: Theme.spacingLg

                    PowerFlowDiagram {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 340
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
                        columnSpacing: Theme.spacingLg
                        rowSpacing: Theme.spacingLg

                        MetricCard {
                            Layout.fillWidth: true
                            title: I18n.t("Solar Generation")
                            valueText: appController.formatPower(appController.generationPowerW)
                            subtitle: appController.generationPowerW > 10 ? I18n.t("Producing power") : I18n.t("Standby / Night")
                            accentColor: Theme.solar
                        }

                        MetricCard {
                            Layout.fillWidth: true
                            title: I18n.t("Battery")
                            valueText: appController.hasBatterySoc
                                       ? (Math.round(appController.batterySoc) + "%")
                                       : appController.formatPower(appController.batteryPowerW)
                            inlineSubtitle: {
                                var p = appController.formatPower(appController.batteryPowerW);
                                if (appController.batteryPowerW > 10) return I18n.t("Charging") + " • " + p;
                                if (appController.batteryPowerW < -10) return I18n.t("Discharging") + " • " + p;
                                return I18n.t("Idle");
                            }
                            subtitle: ""
                            accentColor: Theme.battery
                            showProgress: appController.hasBatterySoc
                            progressValue: appController.batterySoc
                        }

                        MetricCard {
                            Layout.fillWidth: true
                            title: I18n.t("Grid")
                            valueText: appController.formatPower(appController.gridPowerW)
                            subtitle: appController.gridPowerW > 10 ? I18n.t("Importing from grid")
                                    : appController.gridPowerW < -10 ? I18n.t("Exporting to grid")
                                    : I18n.t("Balanced")
                            accentColor: Theme.grid
                        }

                        MetricCard {
                            Layout.fillWidth: true
                            title: I18n.t("Home Load")
                            valueText: appController.formatPower(appController.consumptionPowerW)
                            subtitle: I18n.t("Current consumption")
                            accentColor: Theme.load
                        }
                    }

                    PowerProfileChart {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 330
                        points: appController.powerProfilePoints
                        dateText: appController.powerProfileDateText
                        onPreviousDay: appController.shiftPowerProfileDate(-1)
                        onNextDay: appController.shiftPowerProfileDate(1)
                    }

                    EnergyHistoryChart {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 330
                        items: appController.energyHistoryItems
                        mode: appController.energyHistoryMode
                        periodText: appController.energyHistoryMode === 2 ? I18n.t("All Years") : appController.energyHistoryPeriodText
                        onModeSelected: function(newMode) { appController.setEnergyHistoryMode(newMode) }
                        onPreviousPeriod: appController.shiftEnergyHistoryPeriod(-1)
                        onNextPeriod: appController.shiftEnergyHistoryPeriod(1)
                    }
                }

                // ===================== SECTION 1: DEVICES =====================
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
                            text: appController.busy ? I18n.t("Loading devices…") : I18n.t("No Devices Found")
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }
                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: I18n.t("No inverters, data loggers, or batteries were returned for this plant.")
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
                                    Layout.margins: Theme.rowPadding
                                    spacing: Theme.spacingMd

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
                                            text: I18n.t(model.deviceType)
                                            color: Theme.textSecondary
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 4

                                            Label {
                                                Layout.maximumWidth: parent.width - 30
                                                text: model.deviceName
                                                font.pixelSize: 14
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                            }

                                            ToolButton {
                                                implicitWidth: 24
                                                implicitHeight: 24
                                                padding: 0
                                                text: "✎"
                                                font.pixelSize: 13
                                                ToolTip.visible: hovered
                                                ToolTip.text: I18n.t("Rename device")
                                                onClicked: {
                                                    renameDialog.targetSn = model.deviceSn
                                                    renameDialog.originalName = model.originalName
                                                    renameNameField.text = model.deviceName
                                                    renameDialog.open()
                                                    renameNameField.forceActiveFocus()
                                                    renameNameField.selectAll()
                                                }
                                            }

                                            Item { Layout.fillWidth: true }
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

                                    Label {
                                        visible: model.lastSeenText !== "—"
                                        text: model.lastSeenText
                                        color: Theme.textMuted
                                        font.pixelSize: 11
                                    }

                                    StatusBadge {
                                        status: model.connectionStatus
                                    }

                                    Button {
                                        visible: model.deviceType === "Inverter" || model.deviceType === "Microinverter"
                                        text: I18n.t("Settings")
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

                // ===================== SECTION 2: ALERTS =====================
                Rectangle {
                    visible: root.currentSection === 2
                    Layout.fillWidth: true
                    implicitHeight: appController.alertCount > 0
                                    ? alertsListCol.implicitHeight
                                    : (alertsEmpty.implicitHeight + 48)
                    radius: Theme.radiusLg
                    color: Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        id: alertsEmpty
                        visible: appController.alertCount === 0
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 24
                        spacing: 6

                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: I18n.t("No Alerts")
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }
                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: I18n.t("No active faults or recent warnings were reported for this plant in the last 7 days.")
                            color: Theme.textSecondary
                        }
                    }

                    ColumnLayout {
                        id: alertsListCol
                        visible: appController.alertCount > 0
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: 0

                        Repeater {
                            model: appController.alertModel

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.margins: Theme.rowPadding
                                    spacing: Theme.spacingMd

                                    Rectangle {
                                        readonly property bool isFault: model.level === "Fault"
                                        readonly property color pillColor: isFault ? Theme.errorText : Theme.warning
                                        implicitWidth: codeLbl.implicitWidth + 16
                                        implicitHeight: 26
                                        radius: Theme.radiusSm
                                        color: Qt.rgba(pillColor.r, pillColor.g, pillColor.b, 0.16)
                                        border.color: Qt.rgba(pillColor.r, pillColor.g, pillColor.b, 0.45)
                                        border.width: 1

                                        Label {
                                            id: codeLbl
                                            anchors.centerIn: parent
                                            text: model.alertCode.length > 0 ? (I18n.t(model.level) + " • " + model.alertCode) : I18n.t(model.level)
                                            color: parent.pillColor
                                            font.pixelSize: 11
                                            font.weight: Font.Bold
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Label {
                                            Layout.fillWidth: true
                                            text: model.alertMessage
                                            font.pixelSize: 14
                                            font.weight: Font.DemiBold
                                            wrapMode: Text.WordWrap
                                        }

                                        Label {
                                            Layout.fillWidth: true
                                            text: {
                                                var parts = [];
                                                if (model.deviceType.length > 0) parts.push(I18n.t(model.deviceType));
                                                if (model.deviceSn.length > 0) parts.push("SN: " + model.deviceSn);
                                                parts.push(I18n.t("Started") + ": " + model.startTimeText);
                                                return parts.join("  •  ");
                                            }
                                            color: Theme.textSecondary
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Rectangle {
                                        readonly property color stCol: model.isActive ? Theme.errorText : Theme.success
                                        implicitWidth: stLbl.implicitWidth + 16
                                        implicitHeight: 24
                                        radius: Theme.radiusPill
                                        color: Qt.rgba(stCol.r, stCol.g, stCol.b, 0.15)
                                        border.color: Qt.rgba(stCol.r, stCol.g, stCol.b, 0.35)
                                        border.width: 1

                                        Label {
                                            id: stLbl
                                            anchors.centerIn: parent
                                            text: model.isActive ? I18n.t("Active") : I18n.t("Resolved")
                                            color: parent.stCol
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: index < appController.alertCount - 1
                                    Layout.fillWidth: true
                                    height: 1
                                    color: Theme.separator
                                }
                            }
                        }
                    }
                }

                // ===================== SECTION 3: PLANT INFO =====================
                ColumnLayout {
                    visible: root.currentSection === 3
                    Layout.fillWidth: true
                    spacing: Theme.spacingLg

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: plantInfoCol.implicitHeight
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
                                Layout.margins: Theme.rowPadding
                                spacing: Theme.spacingMd
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
                                label: I18n.t("Plant Name")
                                value: appController.selectedStationName || "—"
                            }
                            InfoRow {
                                label: I18n.t("Plant ID")
                                value: appController.selectedStationId > 0 ? String(appController.selectedStationId) : "—"
                            }
                            InfoRow {
                                label: I18n.t("Address")
                                value: appController.selectedStationLocation || I18n.t("Not specified")
                            }
                            InfoRow {
                                label: I18n.t("Installed Capacity")
                                value: appController.installedCapacityKw > 0
                                       ? (appController.installedCapacityKw.toFixed(2) + " kWp")
                                       : "—"
                            }
                            InfoRow {
                                label: I18n.t("Connection Status")
                                value: appController.connectionStatus
                            }
                            InfoRow {
                                label: I18n.t("Last Update")
                                value: appController.lastUpdateText
                                showSeparator: false
                            }
                        }
                    }

                    component TempTableCard: Rectangle {
                        id: tempCard
                        property string title: ""
                        property string emptyText: ""
                        property var rows: []

                        Layout.fillWidth: true
                        implicitHeight: tempCardCol.implicitHeight
                        radius: Theme.radiusLg
                        color: Theme.bgSurface
                        border.color: Theme.border
                        border.width: 1
                        clip: true

                        ColumnLayout {
                            id: tempCardCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            spacing: 0

                            // Card Header
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.margins: Theme.cardPadding
                                spacing: Theme.spacingSm

                                Label {
                                    text: tempCard.title
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                    Layout.fillWidth: true
                                }

                                Label {
                                    visible: tempCard.rows.length > 0
                                    text: tempCard.rows.length + " " + I18n.t("sensors")
                                    color: Theme.textMuted
                                    font.pixelSize: 12
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Theme.separator
                            }

                            // Empty State
                            ColumnLayout {
                                visible: tempCard.rows.length === 0
                                Layout.fillWidth: true
                                Layout.margins: 24
                                spacing: 4

                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: tempCard.emptyText
                                    color: Theme.textSecondary
                                    font.pixelSize: 13
                                }
                            }

                            // Table Header Row
                            Rectangle {
                                visible: tempCard.rows.length > 0
                                Layout.fillWidth: true
                                implicitHeight: 36
                                color: Theme.bgElevated

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.rowPadding
                                    anchors.rightMargin: Theme.rowPadding
                                    spacing: Theme.spacingMd

                                    Label {
                                        text: I18n.t("Device")
                                        color: Theme.textSecondary
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 200
                                    }
                                    Label {
                                        text: I18n.t("Sensor")
                                        color: Theme.textSecondary
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 180
                                    }
                                    Label {
                                        text: I18n.t("Temperature")
                                        color: Theme.textSecondary
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        Layout.preferredWidth: 100
                                        horizontalAlignment: Text.AlignRight
                                    }
                                    Label {
                                        text: I18n.t("Status")
                                        color: Theme.textSecondary
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        Layout.preferredWidth: 84
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    Label {
                                        text: I18n.t("Updated")
                                        color: Theme.textSecondary
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        Layout.preferredWidth: 74
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 1
                                    color: Theme.separator
                                }
                            }

                            // Table Data Rows
                            Repeater {
                                model: tempCard.rows

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.leftMargin: Theme.rowPadding
                                        Layout.rightMargin: Theme.rowPadding
                                        Layout.topMargin: 10
                                        Layout.bottomMargin: 10
                                        spacing: Theme.spacingMd

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.preferredWidth: 200
                                            spacing: 1

                                            Label {
                                                Layout.fillWidth: true
                                                text: modelData.deviceName
                                                font.pixelSize: 13
                                                font.weight: Font.Medium
                                                elide: Text.ElideRight
                                            }
                                            Label {
                                                Layout.fillWidth: true
                                                visible: modelData.deviceSn.length > 0 && modelData.deviceSn !== modelData.deviceName
                                                text: "SN: " + modelData.deviceSn
                                                color: Theme.textMuted
                                                font.pixelSize: 11
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Label {
                                            Layout.fillWidth: true
                                            Layout.preferredWidth: 180
                                            text: modelData.sensorName
                                            color: Theme.textSecondary
                                            font.pixelSize: 13
                                            elide: Text.ElideRight
                                        }

                                        Label {
                                            Layout.preferredWidth: 100
                                            text: modelData.tempText
                                            font.pixelSize: 13
                                            font.weight: Font.Bold
                                            horizontalAlignment: Text.AlignRight
                                        }

                                        Item {
                                            Layout.preferredWidth: 84
                                            implicitHeight: 24

                                            Rectangle {
                                                readonly property color pillCol: modelData.status === "High"
                                                    ? Theme.errorText
                                                    : modelData.status === "Warm"
                                                      ? Theme.warning
                                                      : modelData.status === "Low"
                                                        ? Theme.grid
                                                        : Theme.success
                                                anchors.centerIn: parent
                                                implicitWidth: tempStLbl.implicitWidth + 14
                                                implicitHeight: 22
                                                radius: Theme.radiusPill
                                                color: Qt.rgba(pillCol.r, pillCol.g, pillCol.b, 0.15)
                                                border.color: Qt.rgba(pillCol.r, pillCol.g, pillCol.b, 0.4)
                                                border.width: 1

                                                Label {
                                                    id: tempStLbl
                                                    anchors.centerIn: parent
                                                    text: I18n.t(modelData.status)
                                                    color: parent.pillCol
                                                    font.pixelSize: 11
                                                    font.weight: Font.DemiBold
                                                }
                                            }
                                        }

                                        Label {
                                            Layout.preferredWidth: 74
                                            text: modelData.updatedText
                                            color: Theme.textMuted
                                            font.pixelSize: 12
                                            horizontalAlignment: Text.AlignRight
                                        }
                                    }

                                    Rectangle {
                                        visible: index < tempCard.rows.length - 1
                                        Layout.fillWidth: true
                                        height: 1
                                        color: Theme.separator
                                    }
                                }
                            }
                        }
                    }

                    // Battery Temperatures Table Card (Temperature- Battery, then BMSTemp)
                    TempTableCard {
                        title: I18n.t("Battery Temperatures")
                        emptyText: I18n.t("No battery temperature data available for this plant.")
                        rows: appController.batteryTemperatures
                    }

                    // Other Sensors Table Card
                    TempTableCard {
                        title: I18n.t("Other sensors")
                        emptyText: I18n.t("No other temperature sensors available for this plant.")
                        rows: appController.otherTempSensors
                    }
                }
            }
        }
    }

    InverterSettingsDialog {
        id: inverterSettingsDialog
    }

    Dialog {
        id: renameDialog
        modal: true
        anchors.centerIn: Overlay.overlay
        width: Math.min(420, Overlay.overlay ? Overlay.overlay.width - 48 : 400)
        title: I18n.t("Rename Device")
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property string targetSn: ""
        property string originalName: ""

        ColumnLayout {
            anchors.fill: parent
            spacing: Theme.spacingMd

            Label {
                Layout.fillWidth: true
                text: "SN: " + renameDialog.targetSn + "  •  " + I18n.t("Default") + ": " + renameDialog.originalName
                color: Theme.textSecondary
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            TextField {
                id: renameNameField
                Layout.fillWidth: true
                placeholderText: renameDialog.originalName
                onAccepted: {
                    appController.renameDevice(renameDialog.targetSn, renameNameField.text)
                    renameDialog.close()
                }
            }

            Label {
                Layout.fillWidth: true
                text: I18n.t("Saved locally on this computer (does not modify Deye Cloud).")
                color: Theme.textMuted
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSm

                Button {
                    flat: true
                    text: I18n.t("Reset")
                    onClicked: {
                        appController.renameDevice(renameDialog.targetSn, "")
                        renameDialog.close()
                    }
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: I18n.t("Cancel")
                    onClicked: renameDialog.close()
                }

                Button {
                    id: saveRenameBtn
                    implicitHeight: 34
                    leftPadding: 16
                    rightPadding: 16
                    text: I18n.t("Save")
                    onClicked: {
                        appController.renameDevice(renameDialog.targetSn, renameNameField.text)
                        renameDialog.close()
                    }
                    contentItem: Label {
                        text: saveRenameBtn.text
                        color: Theme.accentText
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: Theme.radiusSm
                        color: saveRenameBtn.down ? Qt.darker(Theme.accent, 1.15)
                             : saveRenameBtn.hovered ? Qt.lighter(Theme.accent, 1.12)
                             : Theme.accent
                    }
                }
            }
        }
    }
}

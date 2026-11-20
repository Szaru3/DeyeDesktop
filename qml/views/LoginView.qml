import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import DeyeDesktop

Rectangle {
    id: root
    color: Theme.bgPrimary

    property bool showAppSecret: false
    property bool showPassword: false
    // Auto-collapse Developer API Settings once App ID & App Secret are saved
    property bool devSectionExpanded: appController.savedAppId.length === 0 || appController.savedAppSecret.length === 0

    function submitLogin() {
        if (appIdField.text.trim().length === 0 || appSecretField.text.trim().length === 0) {
            devSectionExpanded = true
        }
        appController.login(
            regionCombo.currentIndex,
            customUrlField.text,
            appIdField.text,
            appSecretField.text,
            0, // Email login
            emailField.text,
            "",
            "",
            "",
            companyIdField.text,
            passwordField.text,
            rememberCheck.checked
        )
    }

    component GroupTitle: Label {
        color: Theme.textSecondary
        font.pixelSize: 12
        font.weight: Font.Bold
        leftPadding: 4
    }

    component FieldLabel: Label {
        color: Theme.textSecondary
        font.pixelSize: 12
        font.weight: Font.Medium
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: Math.max(height, clampContainer.implicitHeight + 56)
        clip: true

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        // AdwClamp-style centered column with native KDE controls
        ColumnLayout {
            id: clampContainer
            width: Math.min(440, parent.width - 40)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Math.max(28, (parent.height - implicitHeight) / 2)
            spacing: 16

            // App Header
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 48
                    height: 48
                    radius: 14
                    color: Theme.solarSoft
                    border.color: Qt.rgba(Theme.solar.r, Theme.solar.g, Theme.solar.b, 0.5)
                    border.width: 1

                    Label {
                        anchors.centerIn: parent
                        text: "☀"
                        color: Theme.solar
                        font.pixelSize: 22
                    }
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "DeyeDesktop"
                    font.pixelSize: 22
                    font.weight: Font.Bold
                }

                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "Sign in to your Deye Cloud account"
                    color: Theme.textSecondary
                    wrapMode: Text.WordWrap
                }
            }

            // Error Banner
            Rectangle {
                visible: appController.errorMessage.length > 0
                Layout.fillWidth: true
                implicitHeight: errText.implicitHeight + 20
                radius: Theme.radiusMd
                color: Theme.errorSoft
                border.color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.55)
                border.width: 1

                Label {
                    id: errText
                    anchors.fill: parent
                    anchors.margins: 10
                    text: appController.errorMessage
                    color: Theme.errorText
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
            }

            // Group 1: Account (Email + Password + Remember checkbox)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                GroupTitle { text: "Account" }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: accGroupCol.implicitHeight + 28
                    radius: Theme.radiusLg
                    color: Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        id: accGroupCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 14
                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            FieldLabel { text: "Email Address" }
                            TextField {
                                id: emailField
                                Layout.fillWidth: true
                                text: appController.savedEmail
                                placeholderText: "you@example.com"
                                onAccepted: root.submitLogin()
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            FieldLabel { text: "Password" }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                TextField {
                                    id: passwordField
                                    Layout.fillWidth: true
                                    text: appController.savedPassword
                                    placeholderText: "Account password"
                                    echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                                    onAccepted: root.submitLogin()
                                }
                                Button {
                                    text: root.showPassword ? "Hide" : "Show"
                                    onClicked: root.showPassword = !root.showPassword
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.separator
                        }

                        CheckBox {
                            id: rememberCheck
                            Layout.fillWidth: true
                            checked: appController.savedRememberMe
                            text: "Remember credentials on this computer"
                        }
                    }
                }
            }

            // Group 2: Collapsible Developer API Settings
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: devExpanderCol.implicitHeight
                radius: Theme.radiusLg
                color: Theme.bgSurface
                border.color: Theme.border
                border.width: 1
                clip: true

                ColumnLayout {
                    id: devExpanderCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 50
                        color: headerHover.containsMouse ? Theme.bgElevated : "transparent"
                        radius: Theme.radiusLg

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 10

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Label {
                                    text: "Developer API Settings"
                                    font.weight: Font.DemiBold
                                }

                                Label {
                                    text: (appIdField.text.trim().length > 0 && appSecretField.text.trim().length > 0)
                                          ? (regionCombo.displayText + " • Configured")
                                          : "Region, App ID & App Secret"
                                    color: Theme.textMuted
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            Label {
                                text: root.devSectionExpanded ? "▾" : "▸"
                                color: Theme.textSecondary
                                font.pixelSize: 15
                            }
                        }

                        MouseArea {
                            id: headerHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.devSectionExpanded = !root.devSectionExpanded
                        }
                    }

                    ColumnLayout {
                        visible: root.devSectionExpanded
                        Layout.fillWidth: true
                        spacing: 0

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.separator
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.margins: 14
                            spacing: 10

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                FieldLabel { text: "Cloud Region" }

                                ComboBox {
                                    id: regionCombo
                                    Layout.fillWidth: true
                                    model: appController.regionNames
                                    currentIndex: Math.max(0, Math.min(appController.savedRegionIndex, count - 1))
                                }

                                TextField {
                                    id: customUrlField
                                    Layout.fillWidth: true
                                    visible: regionCombo.currentIndex === 2
                                    text: appController.savedCustomBaseUrl
                                    placeholderText: "https://eu1-developer.deyecloud.com"
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    FieldLabel { text: "App ID" }
                                    TextField {
                                        id: appIdField
                                        Layout.fillWidth: true
                                        text: appController.savedAppId
                                        placeholderText: "App ID"
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    FieldLabel { text: "App Secret" }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6
                                        TextField {
                                            id: appSecretField
                                            Layout.fillWidth: true
                                            text: appController.savedAppSecret
                                            placeholderText: "App Secret"
                                            echoMode: root.showAppSecret ? TextInput.Normal : TextInput.Password
                                        }
                                        Button {
                                            text: root.showAppSecret ? "Hide" : "Show"
                                            onClicked: root.showAppSecret = !root.showAppSecret
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                FieldLabel { text: "Company ID (optional)" }
                                TextField {
                                    id: companyIdField
                                    Layout.fillWidth: true
                                    text: appController.savedCompanyId
                                    placeholderText: "Leave empty for personal accounts"
                                    onAccepted: root.submitLogin()
                                }
                            }
                        }
                    }
                }
            }

            // Action Buttons (native KDE buttons)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    id: signInButton
                    Layout.fillWidth: true
                    implicitHeight: 38
                    enabled: !appController.busy
                    text: appController.busy ? "Signing in..." : "Sign In"
                    onClicked: root.submitLogin()

                    contentItem: Label {
                        text: signInButton.text
                        color: signInButton.enabled ? Theme.accentText : Theme.textMuted
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: Theme.radiusSm
                        color: !signInButton.enabled
                               ? Theme.bgElevated
                               : signInButton.down
                                 ? Qt.darker(Theme.accent, 1.15)
                                 : signInButton.hovered
                                   ? Qt.lighter(Theme.accent, 1.12)
                                   : Theme.accent
                    }
                }

                Button {
                    Layout.fillWidth: true
                    flat: true
                    enabled: !appController.busy
                    text: "Preview Demo Mode"
                    onClicked: appController.loginDemo()
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import DeyeDesktop

Rectangle {
    id: root
    color: Theme.bgPrimary

    property bool showAppSecret: false
    property bool showPassword: false
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
        font.weight: Font.Medium
        leftPadding: 4
    }

    component FieldLabel: Label {
        color: Theme.textSecondary
        font.pixelSize: 12
        font.weight: Font.Medium
    }

    // Top-right persistent Language Selector
    RowLayout {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Theme.pageMargin
        spacing: Theme.spacingSm
        z: 5

        Label {
            text: I18n.t("Language")
            color: Theme.textSecondary
            font.pixelSize: 12
        }

        ComboBox {
            id: langCombo
            implicitWidth: 118
            model: ["English", "Polski"]
            currentIndex: appController.language === "pl" ? 1 : 0
            onActivated: function(idx) {
                appController.language = (idx === 1) ? "pl" : "en"
            }
        }
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: Math.max(height, clampContainer.implicitHeight + 96)
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        clip: true

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        // Centered clamped login column with uniform padding
        ColumnLayout {
            id: clampContainer
            width: Math.min(440, parent.width - 40)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Math.max(56, (parent.height - implicitHeight) / 2)
            spacing: Theme.spacingLg

            // App Header
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Image {
                    Layout.alignment: Qt.AlignHCenter
                    source: "qrc:/qt/qml/DeyeDesktop/assets/icon.png"
                    Layout.preferredWidth: 56
                    Layout.preferredHeight: 56
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "DeyeDesktop"
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                }

                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: I18n.t("Sign in to your Deye Cloud account")
                    color: Theme.textSecondary
                    wrapMode: Text.WordWrap
                }
            }

            // Error Banner
            Rectangle {
                visible: appController.errorMessage.length > 0
                Layout.fillWidth: true
                implicitHeight: errText.implicitHeight + 24
                radius: Theme.radiusMd
                color: Theme.errorSoft
                border.color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.55)
                border.width: 1

                Label {
                    id: errText
                    anchors.fill: parent
                    anchors.margins: 12
                    text: appController.errorMessage
                    color: Theme.errorText
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
            }

            // Group 1: Account
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                GroupTitle { text: I18n.t("Account") }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: accGroupCol.implicitHeight + Theme.cardPadding * 2
                    radius: Theme.radiusLg
                    color: Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        id: accGroupCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Theme.cardPadding
                        spacing: Theme.spacingMd

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            FieldLabel { text: I18n.t("Email Address") }
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
                            FieldLabel { text: I18n.t("Password") }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                TextField {
                                    id: passwordField
                                    Layout.fillWidth: true
                                    text: appController.savedPassword
                                    placeholderText: I18n.t("Account password")
                                    echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                                    onAccepted: root.submitLogin()
                                }
                                Button {
                                    text: root.showPassword ? I18n.t("Hide") : I18n.t("Show")
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
                            text: I18n.t("Remember credentials on this computer")
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
                        implicitHeight: 56
                        color: headerHover.containsMouse ? Theme.bgElevated : "transparent"
                        radius: Theme.radiusLg

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.cardPadding
                            anchors.rightMargin: Theme.cardPadding
                            spacing: 12

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Label {
                                    text: I18n.t("Developer API Settings")
                                    font.weight: Font.Medium
                                }

                                Label {
                                    text: (appIdField.text.trim().length > 0 && appSecretField.text.trim().length > 0)
                                          ? (regionCombo.displayText + " • " + I18n.t("Configured"))
                                          : I18n.t("Region, App ID & App Secret")
                                    color: Theme.textMuted
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            Label {
                                text: root.devSectionExpanded ? "▾" : "▸"
                                color: Theme.textSecondary
                                font.pixelSize: 14
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
                            Layout.margins: Theme.cardPadding
                            spacing: Theme.spacingMd

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                FieldLabel { text: I18n.t("Cloud Region") }

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
                                            text: root.showAppSecret ? I18n.t("Hide") : I18n.t("Show")
                                            onClicked: root.showAppSecret = !root.showAppSecret
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                FieldLabel { text: I18n.t("Company ID (optional)") }
                                TextField {
                                    id: companyIdField
                                    Layout.fillWidth: true
                                    text: appController.savedCompanyId
                                    placeholderText: I18n.t("Leave empty for personal accounts")
                                    onAccepted: root.submitLogin()
                                }
                            }
                        }
                    }
                }
            }

            // Action Buttons
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSm

                Button {
                    id: signInButton
                    Layout.fillWidth: true
                    implicitHeight: 40
                    enabled: !appController.busy
                    text: appController.busy ? I18n.t("Signing in...") : I18n.t("Sign In")
                    onClicked: root.submitLogin()

                    contentItem: Label {
                        text: signInButton.text
                        color: signInButton.enabled ? Theme.accentText : Theme.textMuted
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: Theme.radiusMd
                        color: !signInButton.enabled
                               ? Theme.bgElevated
                               : signInButton.down
                                 ? Qt.darker(Theme.accent, 1.15)
                                 : signInButton.hovered
                                   ? Qt.lighter(Theme.accent, 1.10)
                                   : Theme.accent
                    }
                }

                Button {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    flat: true
                    enabled: !appController.busy
                    text: I18n.t("Preview Demo Mode")
                    onClicked: appController.loginDemo()
                }
            }
        }
    }
}

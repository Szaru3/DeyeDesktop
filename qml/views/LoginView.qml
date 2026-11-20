import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import DeyeDesktop

Rectangle {
    id: root
    color: Theme.bgPrimary

    property int loginMethod: appController.savedLoginMethod
    property bool showAppSecret: false
    property bool showPassword: false

    function submitLogin() {
        appController.login(
            regionCombo.currentIndex,
            customUrlField.text,
            appIdField.text,
            appSecretField.text,
            root.loginMethod,
            emailField.text,
            countryCodeField.text,
            mobileField.text,
            usernameField.text,
            companyIdField.text,
            passwordField.text,
            rememberSwitch.checked
        )
    }

    component GroupTitle: Text {
        color: Theme.textSecondary
        font.pixelSize: 12
        font.weight: Font.Bold
        leftPadding: 4
    }

    component FieldLabel: Text {
        color: Theme.textSecondary
        font.pixelSize: 12
        font.weight: Font.Medium
    }

    component AdwField: TextField {
        Layout.fillWidth: true
        implicitHeight: 36
        color: Theme.textPrimary
        placeholderTextColor: Theme.textMuted
        font.pixelSize: 13
        leftPadding: 11
        rightPadding: 11
        selectionColor: Theme.accent
        selectedTextColor: Theme.textPrimary
        background: Rectangle {
            radius: Theme.radiusSm
            color: Theme.bgInput
            border.color: parent.activeFocus ? Theme.borderFocus : Theme.border
            border.width: parent.activeFocus ? 1.5 : 1
        }
    }

    component AdwSwitch: Switch {
        id: sw
        implicitWidth: 44
        implicitHeight: 24
        indicator: Rectangle {
            implicitWidth: 44
            implicitHeight: 24
            radius: 12
            color: sw.checked ? Theme.accent : "#4D4D4D"
            Behavior on color { ColorAnimation { duration: 150 } }

            Rectangle {
                x: sw.checked ? parent.width - width - 3 : 3
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18
                radius: 9
                color: "#FFFFFF"
                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }
        }
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: Math.max(height, clampContainer.implicitHeight + 56)
        clip: true

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        // AdwClamp-style centered column
        ColumnLayout {
            id: clampContainer
            width: Math.min(460, parent.width - 40)
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

                    Text {
                        anchors.centerIn: parent
                        text: "☀"
                        color: Theme.solar
                        font.pixelSize: 22
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "DeyeDesktop"
                    color: Theme.textPrimary
                    font.pixelSize: 22
                    font.weight: Font.Bold
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "Connect with your Deye Cloud Developer Portal account"
                    color: Theme.textSecondary
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                }
            }

            // Error Banner (AdwBanner style)
            Rectangle {
                visible: appController.errorMessage.length > 0
                Layout.fillWidth: true
                implicitHeight: errText.implicitHeight + 20
                radius: Theme.radiusMd
                color: Theme.errorSoft
                border.color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.6)
                border.width: 1

                Text {
                    id: errText
                    anchors.fill: parent
                    anchors.margins: 10
                    text: appController.errorMessage
                    color: Theme.errorText
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
            }

            // Group 1: Developer API Credentials (AdwPreferencesGroup)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                GroupTitle { text: "Developer Application" }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: devGroupCol.implicitHeight + 24
                    radius: Theme.radiusLg
                    color: Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        id: devGroupCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 10

                        // Region
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            FieldLabel { text: "Cloud Region" }

                            ComboBox {
                                id: regionCombo
                                Layout.fillWidth: true
                                implicitHeight: 36
                                model: appController.regionNames
                                currentIndex: Math.max(0, Math.min(appController.savedRegionIndex, count - 1))

                                contentItem: Text {
                                    leftPadding: 11
                                    rightPadding: 28
                                    text: regionCombo.displayText
                                    color: Theme.textPrimary
                                    font.pixelSize: 13
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }

                                background: Rectangle {
                                    radius: Theme.radiusSm
                                    color: Theme.bgInput
                                    border.color: regionCombo.activeFocus ? Theme.borderFocus : Theme.border
                                }

                                popup: Popup {
                                    y: regionCombo.height + 4
                                    width: regionCombo.width
                                    implicitHeight: contentItem.implicitHeight + 12
                                    padding: 6
                                    background: Rectangle {
                                        color: Theme.bgElevated
                                        border.color: Theme.border
                                        radius: Theme.radiusMd
                                    }
                                    contentItem: ListView {
                                        clip: true
                                        implicitHeight: contentHeight
                                        model: regionCombo.popup.visible ? regionCombo.delegateModel : null
                                    }
                                }

                                delegate: ItemDelegate {
                                    width: regionCombo.width - 12
                                    implicitHeight: 34
                                    contentItem: Text {
                                        text: modelData
                                        color: Theme.textPrimary
                                        font.pixelSize: 13
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        radius: Theme.radiusSm
                                        color: highlighted ? Theme.bgButtonHover : "transparent"
                                    }
                                    highlighted: regionCombo.highlightedIndex === index
                                }
                            }

                            AdwField {
                                id: customUrlField
                                visible: regionCombo.currentIndex === 2
                                text: appController.savedCustomBaseUrl
                                placeholderText: "https://eu1-developer.deyecloud.com"
                            }
                        }

                        // App ID + App Secret
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                FieldLabel { text: "App ID" }
                                AdwField {
                                    id: appIdField
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
                                    spacing: 4
                                    AdwField {
                                        id: appSecretField
                                        text: appController.savedAppSecret
                                        placeholderText: "App Secret"
                                        echoMode: root.showAppSecret ? TextInput.Normal : TextInput.Password
                                    }
                                    Button {
                                        implicitWidth: 44
                                        implicitHeight: 36
                                        text: root.showAppSecret ? "Hide" : "Show"
                                        onClicked: root.showAppSecret = !root.showAppSecret
                                        contentItem: Text {
                                            text: parent.text
                                            color: Theme.textSecondary
                                            font.pixelSize: 11
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        background: Rectangle {
                                            radius: Theme.radiusSm
                                            color: parent.hovered ? Theme.bgButtonHover : Theme.bgButton
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Group 2: Account Credentials (AdwPreferencesGroup)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                GroupTitle { text: "Account" }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: accGroupCol.implicitHeight + 24
                    radius: Theme.radiusLg
                    color: Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        id: accGroupCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 10

                        // Adwaita ToggleGroup style login method switcher
                        Rectangle {
                            Layout.fillWidth: true
                            height: 34
                            radius: Theme.radiusMd
                            color: Theme.bgInput

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 3
                                spacing: 3

                                Repeater {
                                    model: ["Email", "Phone", "Username"]
                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: Theme.radiusSm
                                        color: root.loginMethod === index ? Theme.bgButtonHover : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            color: root.loginMethod === index ? Theme.textPrimary : Theme.textSecondary
                                            font.pixelSize: 12
                                            font.weight: root.loginMethod === index ? Font.DemiBold : Font.Normal
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.loginMethod = index
                                        }
                                    }
                                }
                            }
                        }

                        // Identifier fields
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            visible: root.loginMethod === 0
                            FieldLabel { text: "Email Address" }
                            AdwField {
                                id: emailField
                                text: appController.savedEmail
                                placeholderText: "you@example.com"
                                onAccepted: root.submitLogin()
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            visible: root.loginMethod === 1

                            ColumnLayout {
                                Layout.preferredWidth: 96
                                spacing: 4
                                FieldLabel { text: "Country Code" }
                                AdwField {
                                    id: countryCodeField
                                    text: appController.savedCountryCode
                                    placeholderText: "48"
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                FieldLabel { text: "Mobile Number" }
                                AdwField {
                                    id: mobileField
                                    text: appController.savedMobile
                                    placeholderText: "500600700"
                                    onAccepted: root.submitLogin()
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            visible: root.loginMethod === 2
                            FieldLabel { text: "Username" }
                            AdwField {
                                id: usernameField
                                text: appController.savedUsername
                                placeholderText: "Deye Cloud username"
                                onAccepted: root.submitLogin()
                            }
                        }

                        // Password
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            FieldLabel { text: "Password" }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                AdwField {
                                    id: passwordField
                                    text: appController.savedPassword
                                    placeholderText: "Password (hashed locally with SHA-256)"
                                    echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                                    onAccepted: root.submitLogin()
                                }
                                Button {
                                    implicitWidth: 44
                                    implicitHeight: 36
                                    text: root.showPassword ? "Hide" : "Show"
                                    onClicked: root.showPassword = !root.showPassword
                                    contentItem: Text {
                                        text: parent.text
                                        color: Theme.textSecondary
                                        font.pixelSize: 11
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        radius: Theme.radiusSm
                                        color: parent.hovered ? Theme.bgButtonHover : Theme.bgButton
                                    }
                                }
                            }
                        }

                        // Optional Company ID
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            FieldLabel { text: "Company ID (optional)" }
                            AdwField {
                                id: companyIdField
                                text: appController.savedCompanyId
                                placeholderText: "Leave empty for personal accounts"
                                onAccepted: root.submitLogin()
                            }
                        }

                        // Separator
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.separator
                        }

                        // AdwSwitchRow for Remember credentials
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            Text {
                                Layout.fillWidth: true
                                text: "Remember credentials"
                                color: Theme.textPrimary
                                font.pixelSize: 13
                            }
                            AdwSwitch {
                                id: rememberSwitch
                                checked: appController.savedRememberMe
                            }
                        }
                    }
                }
            }

            // Action Buttons (Adwaita pill suggested-action + flat secondary)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    enabled: !appController.busy
                    onClicked: root.submitLogin()

                    contentItem: Text {
                        text: appController.busy ? "Signing in..." : "Sign In"
                        color: "#FFFFFF"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: Theme.radiusPill
                        color: !parent.enabled ? Theme.bgButton
                             : parent.hovered ? Theme.accentHover : Theme.accent
                    }
                }

                Button {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    enabled: !appController.busy
                    onClicked: appController.loginDemo()

                    contentItem: Text {
                        text: "Preview Demo Mode"
                        color: Theme.textSecondary
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: Theme.radiusPill
                        color: parent.hovered ? Theme.bgButton : "transparent"
                    }
                }
            }
        }
    }
}

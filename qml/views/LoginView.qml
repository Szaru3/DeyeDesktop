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
            rememberCheck.checked
        )
    }

    component StyledLabel: Text {
        color: Theme.textSecondary
        font.pixelSize: 12
        font.weight: Font.Medium
    }

    component StyledField: TextField {
        Layout.fillWidth: true
        implicitHeight: 38
        color: Theme.textPrimary
        placeholderTextColor: Theme.textMuted
        font.pixelSize: 13
        leftPadding: 12
        rightPadding: 12
        selectionColor: Theme.accent
        selectedTextColor: Theme.bgPrimary
        background: Rectangle {
            radius: Theme.radiusSm
            color: Theme.bgInput
            border.color: parent.activeFocus ? Theme.borderFocus : Theme.border
            border.width: 1
        }
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: Math.max(height, cardWrapper.implicitHeight + 48)
        clip: true

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Item {
            id: cardWrapper
            width: parent.width
            implicitHeight: loginCard.implicitHeight
            anchors.centerIn: parent

            Rectangle {
                id: loginCard
                width: Math.min(480, parent.width - 40)
                implicitHeight: formLayout.implicitHeight + 56
                anchors.horizontalCenter: parent.horizontalCenter
                radius: Theme.radiusLg
                color: Theme.bgSurface
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    id: formLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 28
                    spacing: 14

                    // Header
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            spacing: 10
                            Rectangle {
                                width: 32
                                height: 32
                                radius: 8
                                color: Theme.solarSoft
                                border.color: Theme.solar
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "☀"
                                    color: Theme.solar
                                    font.pixelSize: 16
                                }
                            }
                            Text {
                                text: "DeyeDesktop"
                                color: Theme.textPrimary
                                font.pixelSize: 22
                                font.weight: Font.Bold
                            }
                        }

                        Text {
                            text: "Sign in with your Deye Cloud Developer Portal credentials"
                            color: Theme.textSecondary
                            font.pixelSize: 13
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    // Error Banner
                    Rectangle {
                        visible: appController.errorMessage.length > 0
                        Layout.fillWidth: true
                        implicitHeight: errText.implicitHeight + 18
                        radius: Theme.radiusSm
                        color: Theme.errorSoft
                        border.color: Theme.error
                        border.width: 1

                        Text {
                            id: errText
                            anchors.fill: parent
                            anchors.margins: 9
                            text: appController.errorMessage
                            color: "#FDA4AF"
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                    }

                    // Region Selector
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        StyledLabel { text: "Cloud Region" }

                        ComboBox {
                            id: regionCombo
                            Layout.fillWidth: true
                            implicitHeight: 38
                            model: appController.regionNames
                            currentIndex: Math.max(0, Math.min(appController.savedRegionIndex, count - 1))

                            contentItem: Text {
                                leftPadding: 12
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
                                border.width: 1
                            }

                            popup: Popup {
                                y: regionCombo.height + 4
                                width: regionCombo.width
                                implicitHeight: contentItem.implicitHeight + 8
                                padding: 4
                                background: Rectangle {
                                    color: Theme.bgElevated
                                    border.color: Theme.border
                                    radius: Theme.radiusSm
                                }
                                contentItem: ListView {
                                    clip: true
                                    implicitHeight: contentHeight
                                    model: regionCombo.popup.visible ? regionCombo.delegateModel : null
                                }
                            }

                            delegate: ItemDelegate {
                                width: regionCombo.width - 8
                                contentItem: Text {
                                    text: modelData
                                    color: Theme.textPrimary
                                    font.pixelSize: 13
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    radius: 4
                                    color: highlighted ? Theme.bgSurface : "transparent"
                                }
                                highlighted: regionCombo.highlightedIndex === index
                            }
                        }

                        StyledField {
                            id: customUrlField
                            visible: regionCombo.currentIndex === 2
                            text: appController.savedCustomBaseUrl
                            placeholderText: "https://eu1-developer.deyecloud.com"
                        }
                    }

                    // Developer App Credentials
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            StyledLabel { text: "App ID" }
                            StyledField {
                                id: appIdField
                                text: appController.savedAppId
                                placeholderText: "Developer App ID"
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            StyledLabel { text: "App Secret" }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                StyledField {
                                    id: appSecretField
                                    text: appController.savedAppSecret
                                    placeholderText: "Developer App Secret"
                                    echoMode: root.showAppSecret ? TextInput.Normal : TextInput.Password
                                }
                                Button {
                                    implicitWidth: 38
                                    implicitHeight: 38
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
                                        color: Theme.bgInput
                                        border.color: Theme.border
                                    }
                                }
                            }
                        }
                    }

                    // Account Login Method Tabs
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        StyledLabel { text: "Account Login Method" }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            radius: Theme.radiusSm
                            color: Theme.bgInput
                            border.color: Theme.border

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 3
                                spacing: 4

                                Repeater {
                                    model: ["Email", "Phone", "Username"]
                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 4
                                        color: root.loginMethod === index ? Theme.bgElevated : "transparent"
                                        border.color: root.loginMethod === index ? Theme.accent : "transparent"
                                        border.width: 1

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
                    }

                    // Dynamic Account Identifier Input
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        visible: root.loginMethod === 0
                        StyledLabel { text: "Email Address" }
                        StyledField {
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
                            Layout.preferredWidth: 100
                            spacing: 5
                            StyledLabel { text: "Country Code" }
                            StyledField {
                                id: countryCodeField
                                text: appController.savedCountryCode
                                placeholderText: "48"
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            StyledLabel { text: "Mobile Number" }
                            StyledField {
                                id: mobileField
                                text: appController.savedMobile
                                placeholderText: "500600700"
                                onAccepted: root.submitLogin()
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        visible: root.loginMethod === 2
                        StyledLabel { text: "Username" }
                        StyledField {
                            id: usernameField
                            text: appController.savedUsername
                            placeholderText: "Deye Cloud username"
                            onAccepted: root.submitLogin()
                        }
                    }

                    // Password + Optional Company ID
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        StyledLabel { text: "Password" }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            StyledField {
                                id: passwordField
                                text: appController.savedPassword
                                placeholderText: "Account password (hashed locally with SHA-256)"
                                echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                                onAccepted: root.submitLogin()
                            }
                            Button {
                                implicitWidth: 44
                                implicitHeight: 38
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
                                    color: Theme.bgInput
                                    border.color: Theme.border
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        StyledLabel { text: "Company ID (optional)" }
                        StyledField {
                            id: companyIdField
                            text: appController.savedCompanyId
                            placeholderText: "Leave empty for personal accounts"
                            onAccepted: root.submitLogin()
                        }
                    }

                    // Remember Me
                    CheckBox {
                        id: rememberCheck
                        checked: appController.savedRememberMe
                        text: "Remember credentials on this computer"
                        contentItem: Text {
                            leftPadding: rememberCheck.indicator.width + 8
                            text: rememberCheck.text
                            color: Theme.textSecondary
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                        }
                        indicator: Rectangle {
                            implicitWidth: 18
                            implicitHeight: 18
                            y: (parent.height - height) / 2
                            radius: 4
                            color: rememberCheck.checked ? Theme.accent : Theme.bgInput
                            border.color: rememberCheck.checked ? Theme.accent : Theme.border

                            Text {
                                anchors.centerIn: parent
                                visible: rememberCheck.checked
                                text: "✓"
                                color: Theme.bgPrimary
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }
                        }
                    }

                    // Action Buttons
                    Button {
                        Layout.fillWidth: true
                        implicitHeight: 42
                        enabled: !appController.busy
                        onClicked: root.submitLogin()

                        contentItem: Text {
                            text: appController.busy ? "Signing in..." : "Sign In"
                            color: Theme.bgPrimary
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: Theme.radiusSm
                            color: !parent.enabled ? Theme.textMuted
                                 : parent.hovered ? Theme.accentHover : Theme.accent
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        enabled: !appController.busy
                        onClicked: appController.loginDemo()

                        contentItem: Text {
                            text: "Preview Demo Mode (No Credentials Required)"
                            color: Theme.textSecondary
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: Theme.radiusSm
                            color: parent.hovered ? Theme.bgElevated : "transparent"
                            border.color: Theme.border
                            border.width: 1
                        }
                    }
                }
            }
        }
    }
}

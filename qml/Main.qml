import QtQuick
import QtQuick.Controls
import DeyeDesktop

ApplicationWindow {
    id: window
    width: 1080
    height: 760
    minimumWidth: 840
    minimumHeight: 620
    visible: true
    title: appController.loggedIn && appController.selectedStationName.length > 0
           ? ("DeyeDesktop — " + appController.selectedStationName)
           : "DeyeDesktop"
    color: Theme.bgPrimary

    Binding {
        target: I18n
        property: "lang"
        value: appController.language
    }

    LoginView {
        anchors.fill: parent
        visible: !appController.loggedIn
    }

    DashboardView {
        anchors.fill: parent
        visible: appController.loggedIn
    }
}

import QtQuick
import QtQuick.Controls
import DeyeDesktop

ApplicationWindow {
    id: window
    width: 1080
    height: 740
    minimumWidth: 820
    minimumHeight: 600
    visible: true
    title: appController.loggedIn && appController.selectedStationName.length > 0
           ? ("DeyeDesktop — " + appController.selectedStationName)
           : "DeyeDesktop"
    color: Theme.bgPrimary

    LoginView {
        anchors.fill: parent
        visible: !appController.loggedIn
    }

    DashboardView {
        anchors.fill: parent
        visible: appController.loggedIn
    }
}

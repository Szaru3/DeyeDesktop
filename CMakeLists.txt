cmake_minimum_required(VERSION 3.21)

project(DeyeDesktop VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(Qt6 6.5 REQUIRED COMPONENTS
    Core
    Gui
    Widgets
    Qml
    Quick
    QuickControls2
    Network
)

qt_standard_project_setup(REQUIRES 6.5)
if(COMMAND qt_policy)
    qt_policy(SET QTP0004 NEW)
endif()

add_library(deye_core STATIC
    src/api/DeyeModels.h
    src/api/DeyeModels.cpp
    src/api/DeyeApiClient.h
    src/api/DeyeApiClient.cpp
    src/storage/SettingsStore.h
    src/storage/SettingsStore.cpp
    src/viewmodel/StationListModel.h
    src/viewmodel/StationListModel.cpp
    src/viewmodel/DeviceListModel.h
    src/viewmodel/DeviceListModel.cpp
    src/viewmodel/AlertListModel.h
    src/viewmodel/AlertListModel.cpp
    src/viewmodel/InverterSettingsController.h
    src/viewmodel/InverterSettingsController.cpp
    src/viewmodel/AppController.h
    src/viewmodel/AppController.cpp
)

target_include_directories(deye_core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_libraries(deye_core PUBLIC
    Qt6::Core
    Qt6::Widgets
    Qt6::Network
)

if(UNIX AND NOT APPLE)
    find_package(Qt6 6.5 QUIET COMPONENTS DBus)
    if(Qt6DBus_FOUND)
        target_link_libraries(deye_core PUBLIC Qt6::DBus)
        target_compile_definitions(deye_core PRIVATE DEYE_HAS_DBUS=1)
    endif()
endif()

qt_add_executable(deye-desktop
    src/main.cpp
)

set_source_files_properties(qml/theme/Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

set_source_files_properties(qml/theme/I18n.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(deye-desktop
    URI DeyeDesktop
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/theme/Theme.qml
        qml/theme/I18n.qml
        qml/components/StatusBadge.qml
        qml/components/MetricCard.qml
        qml/components/PowerFlowDiagram.qml
        qml/components/PowerProfileChart.qml
        qml/components/EnergyHistoryChart.qml
        qml/views/LoginView.qml
        qml/views/DashboardView.qml
        qml/views/InverterSettingsDialog.qml
)

target_link_libraries(deye-desktop PRIVATE
    deye_core
    Qt6::Gui
    Qt6::Widgets
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
)

set_target_properties(deye-desktop PROPERTIES
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

include(CTest)
if(BUILD_TESTING)
    find_package(Qt6 6.5 QUIET COMPONENTS Test)
    if(Qt6Test_FOUND)
        add_subdirectory(tests)
    endif()
endif()

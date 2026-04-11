cmake_minimum_required(VERSION 3.20)
project(topdash LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)
find_package(LayerShellQt REQUIRED)

qt_add_executable(topdash
    src/main.cpp
    src/systeminfo.cpp
    src/appconfig.cpp
    src/configfiles.cpp
    src/mediainfo.cpp
)

qt_add_qml_module(topdash
    URI TopDash
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/CalendarView.qml
        qml/StatsCard.qml
        qml/TasksView.qml
        qml/ProfileCard.qml
        qml/MediaView.qml
        qml/PerformanceView.qml
        qml/WeatherView.qml
)

target_link_libraries(topdash PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    LayerShellQt::Interface
)

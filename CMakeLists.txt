cmake_minimum_required(VERSION 3.16)

project(journal VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS
    Core
    Gui
    Quick
    QuickControls2
    QuickDialogs2
)

qt_add_executable(journal
    main.cpp
    shamsi.cpp
    shamsi.h
    journalmodel.cpp
    journalmodel.h
    qml.qrc
)

# NO qt_add_qml_module — qml.qrc handles the resources on its own.
# This avoids the "module Journal not installed" class of errors.

target_link_libraries(journal PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::QuickDialogs2
)

set_target_properties(journal PROPERTIES
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE TRUE
)

install(TARGETS journal
    BUNDLE DESTINATION .
    RUNTIME DESTINATION bin
)

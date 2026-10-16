cmake_minimum_required(VERSION 3.25)
project(KLDE VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2)
qt_standard_project_setup(REQUIRES 6.8)
include(CTest)
include(GNUInstallDirs)

set_source_files_properties(qml/Tokens.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
set_source_files_properties(qml/Main.qml PROPERTIES QT_RESOURCE_ALIAS Main.qml)
set_source_files_properties(qml/Tokens.qml PROPERTIES QT_RESOURCE_ALIAS Tokens.qml)
qt_add_qml_module(klde_ui STATIC
    URI KLDE.Shell
    VERSION 1.0
    CLASS_NAME KldeShellPlugin
    RESOURCE_PREFIX /qt/qml
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml/KLDE/Shell"
    QML_FILES qml/Main.qml qml/Tokens.qml
)
target_link_libraries(klde_ui PUBLIC Qt6::Quick Qt6::QuickControls2)

qt_add_executable(klde-shell src/shell/main.cpp)
target_link_libraries(klde-shell PRIVATE klde_uiplugin Qt6::Quick Qt6::QuickControls2)
target_compile_definitions(klde-shell PRIVATE KLDE_VERSION="${PROJECT_VERSION}")
target_compile_options(klde-shell PRIVATE -Wall -Wextra -Wpedantic)

if(BUILD_TESTING)
    find_package(Qt6 6.8 REQUIRED COMPONENTS Test QuickTest)
    add_subdirectory(tests)
endif()

install(TARGETS klde-shell RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES packaging/org.klde.shell.preview.desktop
    DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/applications)
install(FILES LICENSE LICENSES/CC-BY-SA-4.0.txt
    DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/licenses/klde)

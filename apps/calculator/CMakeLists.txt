cmake_minimum_required(VERSION 3.25)
project(OwoCalculator VERSION 0.1.0 LANGUAGES C CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Test)
qt_standard_project_setup(REQUIRES 6.8)
include(CTest)
include(GNUInstallDirs)

set(OWODE_LINGMO_CALCULATOR_SOURCE_DIR "" CACHE PATH "Verified, patched upstream calculator source")
set(upstream "${OWODE_LINGMO_CALCULATOR_SOURCE_DIR}")
if(NOT EXISTS "${upstream}/.owode-upstream-commit")
    message(FATAL_ERROR "Run tools/fetch-lingmo-calculator.py in the cloud first; see apps/calculator/README.md")
endif()
file(READ "${upstream}/.owode-upstream-commit" upstream_revision)
string(STRIP "${upstream_revision}" upstream_revision)
if(NOT upstream_revision STREQUAL "c2fdb5c80049ce6ffb02571e4bbc64fca1c2366e")
    message(FATAL_ERROR "Unreviewed Lingmo Calculator source revision")
endif()
add_library(owode_calculator_engine STATIC
    "${upstream}/engine/constants.cpp"
    "${upstream}/engine/evaluator.cpp"
    "${upstream}/engine/functions.cpp"
    "${upstream}/engine/hmath.cpp"
    "${upstream}/engine/number.c")
target_include_directories(owode_calculator_engine PUBLIC "${upstream}/engine")
target_link_libraries(owode_calculator_engine PUBLIC Qt6::Core)

qt_add_executable(owode-calculator main.cpp)
set_source_files_properties(Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
set_source_files_properties(../../qml/MonetPalette.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE QT_RESOURCE_ALIAS MonetPalette.qml)
qt_add_qml_module(owode_calculator_ui STATIC
    URI OwoDE.Calculator VERSION 1.0 CLASS_NAME OwoCalculatorPlugin
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml/OwoDE/Calculator"
    QML_FILES Main.qml Theme.qml ../../qml/MonetPalette.qml
    SOURCES CalculatorController.h CalculatorController.cpp)
target_link_libraries(owode_calculator_ui PUBLIC owode_calculator_engine
    Qt6::Gui Qt6::Quick Qt6::QuickControls2)
target_include_directories(owode_calculator_ui PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
target_compile_options(owode_calculator_ui PRIVATE -Wall -Wextra -Wpedantic)
target_link_libraries(owode-calculator PRIVATE owode_calculator_ui owode_calculator_uiplugin)

if(BUILD_TESTING)
    qt_add_executable(owode-calculator-test test_calculator.cpp CalculatorController.cpp CalculatorController.h)
    target_link_libraries(owode-calculator-test PRIVATE owode_calculator_engine Qt6::Qml Qt6::Test)
    add_test(NAME calculator-engine COMMAND owode-calculator-test)
    set_tests_properties(calculator-engine PROPERTIES TIMEOUT 20)
    qt_add_executable(owode-calculator-ui-test test_calculator_ui.cpp)
    target_link_libraries(owode-calculator-ui-test PRIVATE owode_calculator_ui owode_calculator_uiplugin Qt6::Test)
    add_test(NAME calculator-keyboard-and-buttons COMMAND owode-calculator-ui-test)
    set_tests_properties(calculator-keyboard-and-buttons PROPERTIES TIMEOUT 30
        ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software;QT_QUICK_CONTROLS_STYLE=Basic")
endif()
install(TARGETS owode-calculator RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES org.owode.Calculator.desktop DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/applications)
set(notices "${CMAKE_INSTALL_DATAROOTDIR}/doc/owode-calculator")
install(FILES README.md ../../LICENSE DESTINATION "${notices}")
# Corresponding source travels with the binary: pinned upstream, modifications,
# the independent frontend and the shared palette. No source offer can expire.
install(DIRECTORY . DESTINATION "${notices}/source/apps/calculator")
install(FILES ../../qml/MonetPalette.qml DESTINATION "${notices}/source/qml")
install(FILES ../../LICENSE DESTINATION "${notices}/source")
install(FILES ../../tools/fetch-lingmo-calculator.py DESTINATION "${notices}/source/tools")
install(FILES "${upstream}/../lingmo-calculator-source.tar.gz" DESTINATION "${notices}/source")
set(CPACK_PACKAGE_NAME owode-calculator)
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set(CPACK_PACKAGE_CONTACT "owoDE contributors")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "owoDE-themed calculator using the Lingmo Calculator engine")
set(CPACK_PACKAGING_INSTALL_PREFIX /usr)
set(CPACK_RPM_PACKAGE_LICENSE "GPL-3.0-or-later")
set(CPACK_RPM_PACKAGE_AUTOREQPROV ON)
set(CPACK_RPM_PACKAGE_REQUIRES "qt6-qtdeclarative, qt6-qtbase")
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
set(CPACK_DEBIAN_PACKAGE_DEPENDS "qml6-module-qtquick, qml6-module-qtquick-controls, qml6-module-qtquick-layouts, qml6-module-qtquick-templates, qml6-module-qtquick-window, qml6-module-qtqml-workerscript")
include(CPack)

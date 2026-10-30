find_package(Python3 REQUIRED COMPONENTS Interpreter)
add_test(NAME native-protocol-parser COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/test_native_protocol.py")
set_tests_properties(native-protocol-parser PROPERTIES LABELS unit TIMEOUT 10)

qt_add_executable(klde-backend-test test_backends.cpp)
target_link_libraries(klde-backend-test PRIVATE klde_backends Qt6::Test)
add_test(NAME backend-contracts COMMAND klde-backend-test)
set_tests_properties(backend-contracts PROPERTIES LABELS unit TIMEOUT 30)

if(OWODE_HAVE_KDE_APPLICATIONS)
    find_program(DBUS_RUN_SESSION_EXECUTABLE dbus-run-session REQUIRED)
    qt_add_executable(owode-desktop-applications-test test_desktop_applications.cpp)
    target_link_libraries(owode-desktop-applications-test PRIVATE klde_backends klde_backendsplugin Qt6::Test)
    add_test(NAME desktop-applications COMMAND "${DBUS_RUN_SESSION_EXECUTABLE}" -- $<TARGET_FILE:owode-desktop-applications-test>)
    set_tests_properties(desktop-applications PROPERTIES LABELS unit TIMEOUT 30
        ENVIRONMENT "QT_QPA_PLATFORM=offscreen")
endif()

qt_add_executable(klde-startup-test test_startup.cpp)

qt_add_executable(klde-locale-input-test test_locale_input.cpp)
target_link_libraries(klde-locale-input-test PRIVATE klde_backends Qt6::Test)
add_test(NAME locale-input-contracts COMMAND klde-locale-input-test)
set_tests_properties(locale-input-contracts PROPERTIES LABELS unit TIMEOUT 30)

qt_add_executable(klde-power-scene-test test_power_scenes.cpp)
target_link_libraries(klde-power-scene-test PRIVATE klde_backends Qt6::Test)
add_test(NAME power-scene-contracts COMMAND klde-power-scene-test)
set_tests_properties(power-scene-contracts PROPERTIES LABELS unit TIMEOUT 30)

qt_add_executable(klde-shortcut-test test_shortcuts.cpp)
target_link_libraries(klde-shortcut-test PRIVATE klde_backends Qt6::Test)
add_test(NAME shortcut-contracts COMMAND klde-shortcut-test)
set_tests_properties(shortcut-contracts PROPERTIES LABELS unit TIMEOUT 30)

qt_add_executable(klde-weather-test test_weather.cpp)
target_link_libraries(klde-weather-test PRIVATE klde_backends Qt6::Test)
add_test(NAME weather-contracts COMMAND klde-weather-test)
set_tests_properties(weather-contracts PROPERTIES LABELS unit TIMEOUT 30)
target_link_libraries(klde-startup-test PRIVATE
    klde_ui klde_uiplugin Qt6::Quick Qt6::QuickControls2 Qt6::Test)
add_test(NAME shell-startup COMMAND klde-startup-test)
set_tests_properties(shell-startup PROPERTIES
    LABELS unit TIMEOUT 30
    ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software;QT_QUICK_CONTROLS_STYLE=Basic")

qt_add_executable(klde-qml-tests qml_test_main.cpp)
target_link_libraries(klde-qml-tests PRIVATE
    klde_uiplugin Qt6::QuickTest Qt6::QuickControls2)
target_compile_definitions(klde-qml-tests PRIVATE
    QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}/qml")
add_test(NAME qml-tokens COMMAND klde-qml-tests)
set_tests_properties(qml-tokens PROPERTIES
    LABELS qml TIMEOUT 30
    ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software;QT_QUICK_CONTROLS_STYLE=Basic")

qt_add_executable(klde-visual-lab-test test_visual_lab.cpp)
target_link_libraries(klde-visual-lab-test PRIVATE klde_backends Qt6::Test)
add_test(NAME visual-lab-contracts COMMAND klde-visual-lab-test)
set_tests_properties(visual-lab-contracts PROPERTIES LABELS unit TIMEOUT 30)

# Filesystem/QDS compatibility check, independent of every native/mock backend.
qt_add_executable(owode-design-workspace-test test_design_workspace.cpp)
target_link_libraries(owode-design-workspace-test PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Test)
target_compile_definitions(owode-design-workspace-test PRIVATE
    OWODE_DESIGN_DIR="${PROJECT_SOURCE_DIR}/design")
add_test(NAME design-workspace COMMAND owode-design-workspace-test)
set_tests_properties(design-workspace PROPERTIES LABELS "qml;design" TIMEOUT 60
    ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software;QT_QUICK_CONTROLS_STYLE=Basic")

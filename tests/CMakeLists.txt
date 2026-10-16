qt_add_executable(klde-startup-test test_startup.cpp)
target_link_libraries(klde-startup-test PRIVATE
    klde_uiplugin Qt6::Quick Qt6::QuickControls2 Qt6::Test)
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

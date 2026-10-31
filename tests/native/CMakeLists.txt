enable_language(C)
find_package(PkgConfig REQUIRED)
pkg_check_modules(WaylandClient REQUIRED IMPORTED_TARGET wayland-client)
find_program(WAYLAND_SCANNER_EXECUTABLE wayland-scanner REQUIRED)
find_package(Qt6 REQUIRED COMPONENTS Widgets)
set(protocol "${CMAKE_CURRENT_SOURCE_DIR}/protocols/fake-input.xml")
add_custom_command(OUTPUT fake-input-client-protocol.h fake-input-protocol.c
    COMMAND "${WAYLAND_SCANNER_EXECUTABLE}" client-header "${protocol}" fake-input-client-protocol.h
    COMMAND "${WAYLAND_SCANNER_EXECUTABLE}" private-code "${protocol}" fake-input-protocol.c
    DEPENDS "${protocol}" VERBATIM)
qt_add_executable(klde-native-session-test test_native_session.cpp fake-input-client-protocol.h fake-input-protocol.c)
target_include_directories(klde-native-session-test PRIVATE "${CMAKE_CURRENT_BINARY_DIR}")
target_link_libraries(klde-native-session-test PRIVATE klde_ui klde_uiplugin Qt6::QuickControls2 Qt6::Test PkgConfig::WaylandClient)
qt_add_executable(owode-native-test-client test_client.cpp)
target_link_libraries(owode-native-test-client PRIVATE Qt6::Widgets Qt6::DBus)
# Deliberately not an ordinary CTest entry: it requires the isolated KWin runner.

qt_add_executable(owode-native-capture capture.cpp)
target_link_libraries(owode-native-capture PRIVATE Qt6::Gui Qt6::DBus)

qt_add_qml_module(klde_backends STATIC
    URI KLDE.Backends
    VERSION 1.0
    CLASS_NAME KldeBackendsPlugin
    RESOURCE_PREFIX /qt/qml
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml/KLDE/Backends"
    SOURCES
        backends/PresentationBackends.h backends/PresentationBackends.cpp
        backends/WindowManagerBackend.h
        backends/MockWindowManagerBackend.h backends/MockWindowManagerBackend.cpp
        backends/SystemBackend.h
        backends/MockSystemBackend.h backends/MockSystemBackend.cpp
        backends/BlurBackend.h backends/BlurBackend.cpp
        models/ApplicationModel.h models/ApplicationModel.cpp
        models/PowerSceneController.h models/PowerSceneController.cpp
        shortcuts/ShortcutRegistry.h shortcuts/ShortcutRegistry.cpp
        weather/WeatherProvider.h weather/WeatherProvider.cpp
        weather/MockWeatherProvider.h weather/MockWeatherProvider.cpp
        weather/UApisCnWeatherProvider.h weather/UApisCnWeatherProvider.cpp
        weather/WeatherService.h weather/WeatherService.cpp
        i18n/LocaleVoiceModel.h i18n/LocaleVoiceModel.cpp
        input/InputMethodBackend.h input/Fcitx5Backend.h input/Fcitx5Backend.cpp
        platform/common/DisplayServerBackend.h platform/common/DisplayServerBackend.cpp
        platform/common/SessionRuntimeBackend.h platform/common/SessionRuntimeBackend.cpp
        platform/wayland/NativeSurfaceController.h platform/wayland/NativeSurfaceController.cpp
        mock/SystemStateModel.h mock/SystemStateModel.cpp
        models/NotificationModel.h models/NotificationModel.cpp
        status/StatusModuleRegistry.h status/StatusModuleRegistry.cpp
        ShellServices.h ShellServices.cpp
)
target_include_directories(klde_backends PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(klde_backends PUBLIC Qt6::Core Qt6::Gui Qt6::DBus Qt6::Network Qt6::Qml)
if(LOMODE_HAVE_LAYERSHELLQT)
    target_link_libraries(klde_backends PUBLIC LayerShellQt::Interface)
    target_compile_definitions(klde_backends PUBLIC LOMODE_HAVE_LAYERSHELLQT=1)
endif()
# qmltyperegistrar emits conditional includes by header basename.
target_include_directories(klde_backends PRIVATE
    backends models i18n input mock platform/common shortcuts status weather)
target_compile_options(klde_backends PRIVATE -Wall -Wextra -Wpedantic)

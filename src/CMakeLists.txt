qt_add_qml_module(klde_backends STATIC
    URI KLDE.Backends
    VERSION 1.0
    CLASS_NAME KldeBackendsPlugin
    RESOURCE_PREFIX /qt/qml
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml/KLDE/Backends"
    SOURCES
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
        ShellServices.h ShellServices.cpp
)
target_include_directories(klde_backends PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(klde_backends PUBLIC Qt6::Core Qt6::Gui Qt6::DBus Qt6::Network Qt6::Qml)
target_compile_options(klde_backends PRIVATE -Wall -Wextra -Wpedantic)

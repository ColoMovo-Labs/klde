qt_add_qml_module(klde_backends STATIC
    URI KLDE.Backends
    VERSION 1.0
    CLASS_NAME KldeBackendsPlugin
    RESOURCE_PREFIX /qt/qml
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml/KLDE/Backends"
    SOURCES
        applications/DesktopApplicationBackend.h applications/DesktopApplicationBackend.cpp
        models/ApplicationEntry.h
        backends/PresentationBackends.h backends/PresentationBackends.cpp
        backends/WindowManagerBackend.h
        backends/MockWindowManagerBackend.h backends/MockWindowManagerBackend.cpp
        backends/KWinWindowManagerBackend.h backends/KWinWindowManagerBackend.cpp
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
        settings/ShellSettings.h settings/ShellSettings.cpp
        models/NotificationModel.h models/NotificationModel.cpp
        status/StatusModuleRegistry.h status/StatusModuleRegistry.cpp
        live/HostTelemetrySource.h live/HostTelemetrySource.cpp
        live/UPowerBatterySource.h live/UPowerBatterySource.cpp
        live/LiveSystemBackend.h live/LiveSystemBackend.cpp
        live/BrightnessSource.h live/BrightnessSource.cpp
        live/PowerProfilesSource.h live/PowerProfilesSource.cpp
        live/MprisSource.h live/MprisSource.cpp
        ShellServices.h ShellServices.cpp
)
target_include_directories(klde_backends PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
qt_add_resources(klde_backends owode_kwin_scripts
    PREFIX /owode BASE backends
    FILES backends/kwin-state.js backends/kwin-command.js)
target_link_libraries(klde_backends PUBLIC Qt6::Core Qt6::Concurrent Qt6::Gui Qt6::DBus Qt6::Network Qt6::Qml Qt6::Quick)
if(OWODE_HAVE_KDE_APPLICATIONS)
    target_link_libraries(klde_backends PRIVATE KF6::Service KF6::KIOGui)
    target_compile_definitions(klde_backends PRIVATE OWODE_HAVE_KDE_APPLICATIONS=1)
endif()
if(OWODE_HAVE_NETWORKMANAGER)
    target_sources(klde_backends PRIVATE live/NetworkManagerSource.h live/NetworkManagerSource.cpp)
    target_link_libraries(klde_backends PRIVATE KF6::NetworkManagerQt)
    target_compile_definitions(klde_backends PRIVATE OWODE_HAVE_NETWORKMANAGER=1)
endif()
if(OWODE_HAVE_BLUEZ)
    target_sources(klde_backends PRIVATE live/BluetoothSource.h live/BluetoothSource.cpp)
    target_link_libraries(klde_backends PRIVATE KF6::BluezQt)
    target_compile_definitions(klde_backends PRIVATE OWODE_HAVE_BLUEZ=1)
endif()
if(OWODE_HAVE_PULSEAUDIO)
    target_sources(klde_backends PRIVATE live/PulseAudioSource.h live/PulseAudioSource.cpp)
    target_link_libraries(klde_backends PRIVATE KF6::PulseAudioQt)
    target_compile_definitions(klde_backends PRIVATE OWODE_HAVE_PULSEAUDIO=1)
endif()
if(OWODE_HAVE_KCONFIG)
    target_sources(klde_backends PRIVATE live/NightLightSource.h live/NightLightSource.cpp)
    target_link_libraries(klde_backends PRIVATE KF6::ConfigCore)
    target_compile_definitions(klde_backends PRIVATE OWODE_HAVE_KCONFIG=1)
endif()
if(OWODE_HAVE_LAYERSHELLQT)
    target_link_libraries(klde_backends PUBLIC LayerShellQt::Interface)
    target_compile_definitions(klde_backends PUBLIC OWODE_HAVE_LAYERSHELLQT=1)
endif()
# qmltyperegistrar emits conditional includes by header basename.
target_include_directories(klde_backends PRIVATE
    applications backends models i18n input mock platform/common settings shortcuts status weather)
target_compile_options(klde_backends PRIVATE -Wall -Wextra -Wpedantic)

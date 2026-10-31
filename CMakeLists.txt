cmake_minimum_required(VERSION 3.25)
project(KLDE VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui Concurrent DBus Network Qml Quick QuickControls2 ShaderTools)
qt_standard_project_setup(REQUIRES 6.8)
include(CTest)
option(OWODE_BUILD_NATIVE_TESTS "Build isolated KWin integration tools (cloud only)" OFF)
include(GNUInstallDirs)

# LayerShellQt is an optional runtime integration. The Visual Lab and ordinary
# preview stay buildable on hosts that do not ship it; native-surface mode is
# enabled only when the target provides the KDE interface package.
find_package(LayerShellQt 6.6 CONFIG QUIET)
if(TARGET LayerShellQt::Interface)
    set(OWODE_HAVE_LAYERSHELLQT ON)
else()
    set(OWODE_HAVE_LAYERSHELLQT OFF)
endif()
option(OWODE_REQUIRE_SYSTEM_APPLICATIONS "Require KDE desktop application integration" OFF)
find_package(KF6Service 6.0 CONFIG QUIET)
find_package(KF6KIO 6.0 CONFIG QUIET)
if(TARGET KF6::Service AND TARGET KF6::KIOGui)
    set(OWODE_HAVE_KDE_APPLICATIONS ON)
else()
    set(OWODE_HAVE_KDE_APPLICATIONS OFF)
    if(OWODE_REQUIRE_SYSTEM_APPLICATIONS)
        message(FATAL_ERROR "System applications require KF6 Service and KIO development packages")
    endif()
endif()
message(STATUS "owoDE system applications: ${OWODE_HAVE_KDE_APPLICATIONS}")
# Live system services. Optional so the Visual Lab builds anywhere; packaged
# sessions set OWODE_REQUIRE_SYSTEM_APPLICATIONS and therefore require them.
find_package(KF6NetworkManagerQt 6.0 CONFIG QUIET)
find_package(KF6BluezQt 6.0 CONFIG QUIET)
if(TARGET KF6::NetworkManagerQt)
    set(OWODE_HAVE_NETWORKMANAGER ON)
else()
    set(OWODE_HAVE_NETWORKMANAGER OFF)
endif()
if(TARGET KF6::BluezQt)
    set(OWODE_HAVE_BLUEZ ON)
else()
    set(OWODE_HAVE_BLUEZ OFF)
endif()
if(OWODE_REQUIRE_SYSTEM_APPLICATIONS AND (NOT OWODE_HAVE_NETWORKMANAGER OR NOT OWODE_HAVE_BLUEZ))
    message(FATAL_ERROR "Live sessions require KF6 NetworkManagerQt and BluezQt development packages")
endif()
message(STATUS "owoDE live network: ${OWODE_HAVE_NETWORKMANAGER}, bluetooth: ${OWODE_HAVE_BLUEZ}")
add_subdirectory(src)

add_subdirectory(design/Owo/Visuals)
set_source_files_properties(qml/Branding.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
set_source_files_properties(qml/I18n.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
set(klde_qml_files
    qml/Main.qml qml/I18n.qml qml/Branding.qml
    qml/components/RibbonGroup.qml qml/components/TelemetryCell.qml
    qml/components/TemporalCapsule.qml qml/components/TemporalLandscape.qml
    qml/components/SystemIsland.qml qml/components/WelcomeFlow.qml
    qml/components/SystemUiGallery.qml
    qml/components/TemporalStudy.qml qml/components/DisplayClock.qml
    qml/components/MaterialStudy.qml
    qml/components/GeometryDebugOverlay.qml
    qml/components/TemporalSettings.qml qml/components/WallpaperLayers.qml
    qml/components/WallpaperEffectsSettings.qml qml/components/LockScreenPreview.qml
    qml/components/LockScreenSurface.qml
    qml/components/WaydroidSettings.qml
    qml/components/StateSlider.qml
    qml/components/StateChoice.qml
    qml/components/PolicyControls.qml
    qml/components/NotificationCenter.qml
    qml/components/RibbonSettings.qml
    qml/components/MockLab.qml
    qml/components/AppSuitePreview.qml
    qml/components/StatusCapsule.qml
    qml/components/StatusModule.qml
    qml/components/StatusRibbonSection.qml
    qml/components/StatusRibbon.qml
    qml/components/LabPanel.qml
    qml/components/CandidatePreview.qml
    qml/components/StatusDashboard.qml
    qml/components/AmbientDesktop.qml
    qml/components/ApplicationShortcuts.qml
    qml/components/Icon.qml qml/components/Surface.qml qml/components/IconButton.qml
    qml/components/ShellPopup.qml qml/components/Dock.qml qml/components/Launcher.qml
    qml/components/WorkspaceIndicator.qml qml/components/ToggleTile.qml
    qml/components/SliderCard.qml qml/components/QuickSettings.qml qml/components/SessionMenu.qml
    qml/components/PowerSceneCard.qml qml/components/SceneSettings.qml
    qml/components/WeatherSettings.qml
    qml/components/ActionButton.qml qml/components/ChoiceBox.qml
    qml/components/LanguageInputSettings.qml qml/components/InputPopup.qml
    qml/widgets/WidgetHost.qml qml/widgets/WeatherWidget.qml
    qml/effects/OwnedBlurSample.qml qml/effects/BlurLab.qml qml/effects/OwnedBackdrop.qml
    qml/effects/MaterialBackdrop.qml
)
foreach(qml_file IN LISTS klde_qml_files)
    get_filename_component(qml_name "${qml_file}" NAME)
    set_source_files_properties("${qml_file}" PROPERTIES QT_RESOURCE_ALIAS "${qml_name}")
endforeach()
qt_add_qml_module(klde_ui STATIC
    URI KLDE.Shell
    VERSION 1.0
    CLASS_NAME KldeShellPlugin
    RESOURCE_PREFIX /qt/qml
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml/KLDE/Shell"
    IMPORT_PATH "${CMAKE_BINARY_DIR}/qml"
    DEPENDENCIES KLDE.Backends Owo.Visuals
    QML_FILES ${klde_qml_files}
)
target_link_libraries(klde_ui PUBLIC owode_visuals owode_visualsplugin klde_backends klde_backendsplugin Qt6::Quick Qt6::QuickControls2)

# Build-time shader packs for public ShaderEffect use (blur.md). Runtime
# packages need no shader compiler; the baked .qsb files are embedded.
qt_add_shaders(klde_ui klde_shaders
    PREFIX /shaders
    BASE qml/effects
    FILES qml/effects/material.frag
)

qt_add_resources(klde_backends klde_translations PREFIX / FILES
    translations/en.json translations/zh_CN.json
    translations/voices/cute/en.json translations/voices/cute/zh_CN.json)

qt_add_resources(klde_backends klde_mock_data PREFIX / FILES
    src/mock/scenarios.json src/status/modules.json)

set(klde_assets assets/branding/owode-logo.png assets/wallpapers/first-light.svg
    assets/wallpapers/depth-foreground.svg assets/wallpapers/soft-cache-study.svg
    assets/wallpapers/lock-cache-study.svg assets/fonts/comfortaa/Comfortaa-Bold.otf
    assets/welcome/klde-guide-placeholder.png assets/welcome/klde-guide-wave.png
    assets/welcome/klde-guide-hero-v2.png
    assets/welcome/klde-wordmark.svg
    assets/wallpapers/abstract.svg assets/wallpapers/quiet.svg assets/wallpapers/kemono.svg
    assets/fonts/glow-sans/GlowSansSC-Normal-Regular.otf
    assets/fonts/glow-sans/GlowSansSC-Normal-Medium.otf)
foreach(phase clear-morning cloudy-day sunset rainy-evening starry-night moonlit-night)
    foreach(size compact standard expanded)
        list(APPEND klde_assets "assets/temporal/${phase}-land-${size}.svg")
    endforeach()
endforeach()
foreach(stem abstract quiet kemono depth-foreground soft-cache-study lock-cache-study)
    list(APPEND klde_assets "assets/wallpapers/${stem}-night.svg")
endforeach()
list(APPEND klde_assets assets/temporal/moon.svg assets/wallpapers/first-night.svg
    "assets/fonts/rubik/Rubik[wght].ttf")
foreach(icon grid list minus klde folder globe terminal note music settings wifi bluetooth moon sun volume power leaf search close weather cpu memory microphone battery bell overview display info previous next thermometer weather-clear weather-partly-cloudy weather-cloudy weather-rain weather-snow weather-thunderstorm weather-fog weather-extreme-heat weather-extreme-cold)
    list(APPEND klde_assets "assets/icons/${icon}.svg")
    list(APPEND klde_assets "assets/icons/${icon}-light.svg")
endforeach()
qt_add_resources(klde_ui klde_assets PREFIX / FILES ${klde_assets})

qt_add_executable(klde-shell src/shell/main.cpp)
target_link_libraries(klde-shell PRIVATE klde_ui klde_uiplugin Qt6::Quick Qt6::QuickControls2)
target_compile_definitions(klde-shell PRIVATE KLDE_VERSION="${PROJECT_VERSION}")
target_compile_options(klde-shell PRIVATE -Wall -Wextra -Wpedantic)

if(OWODE_HAVE_LAYERSHELLQT)
    # Runtime smoke test used only inside an isolated Wayland/KWin session. It
    # is deliberately not part of the ordinary preview test matrix.
    add_executable(klde-layer-shell-smoke tests/native-layer-shell-smoke.cpp)
    target_link_libraries(klde-layer-shell-smoke PRIVATE klde_backends Qt6::Gui)
    target_compile_options(klde-layer-shell-smoke PRIVATE -Wall -Wextra -Wpedantic)
endif()

if(BUILD_TESTING)
    find_package(Qt6 6.8 REQUIRED COMPONENTS Test QuickTest)
    add_subdirectory(tests)
    if(OWODE_BUILD_NATIVE_TESTS)
        if(NOT OWODE_HAVE_LAYERSHELLQT)
            message(FATAL_ERROR "Native integration tests require LayerShellQt 6.6 or newer")
        endif()
        add_subdirectory(tests/native)
    endif()
endif()

install(TARGETS klde-shell RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(PROGRAMS packaging/owode-run DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES packaging/org.klde.shell.preview.desktop
    DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/applications)
install(FILES assets/icons/klde.svg DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/scalable/apps)
install(FILES assets/branding/owode-logo.png DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/pixmaps RENAME owode.png)
install(DIRECTORY assets/fcitx5/klde-expressive-light assets/fcitx5/klde-expressive-dark
    DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/fcitx5/themes)
install(FILES LICENSE LICENSES/CC-BY-SA-4.0.txt LICENSES/OFL-1.1.txt
    DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/licenses/klde)

include(cmake/Packaging.cmake)

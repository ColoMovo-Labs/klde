cmake_minimum_required(VERSION 3.25)
project(KLDE VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui DBus Network Qml Quick QuickControls2)
qt_standard_project_setup(REQUIRES 6.8)
include(CTest)
include(GNUInstallDirs)
add_subdirectory(src)

set_source_files_properties(qml/Tokens.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
set_source_files_properties(qml/Branding.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
set_source_files_properties(qml/I18n.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
set(klde_qml_files
    qml/Main.qml qml/Tokens.qml qml/I18n.qml qml/Branding.qml
    qml/components/RibbonGroup.qml qml/components/TelemetryCell.qml
    qml/components/TemporalCapsule.qml qml/components/TemporalLandscape.qml
    qml/components/SystemIsland.qml qml/components/WelcomeFlow.qml
    qml/components/SystemUiGallery.qml
    qml/components/TemporalStudy.qml qml/components/DisplayClock.qml
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
    qml/components/SliderCard.qml qml/components/QuickSettings.qml
    qml/components/PowerSceneCard.qml qml/components/SceneSettings.qml
    qml/components/WeatherSettings.qml
    qml/components/ActionButton.qml qml/components/ChoiceBox.qml
    qml/components/LanguageInputSettings.qml qml/components/InputPopup.qml
    qml/widgets/WidgetHost.qml qml/widgets/WeatherWidget.qml
    qml/effects/OwnedBlurSample.qml qml/effects/BlurLab.qml qml/effects/OwnedBackdrop.qml
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
    DEPENDENCIES KLDE.Backends
    QML_FILES ${klde_qml_files}
)
target_link_libraries(klde_ui PUBLIC klde_backends klde_backendsplugin Qt6::Quick Qt6::QuickControls2)

qt_add_resources(klde_backends klde_translations PREFIX / FILES
    translations/en.json translations/zh_CN.json
    translations/voices/cute/en.json translations/voices/cute/zh_CN.json)

qt_add_resources(klde_backends klde_mock_data PREFIX / FILES
    src/mock/scenarios.json src/status/modules.json)

set(klde_assets assets/wallpapers/first-light.svg
    assets/wallpapers/depth-foreground.svg assets/wallpapers/soft-cache-study.svg
    assets/wallpapers/lock-cache-study.svg assets/fonts/comfortaa/Comfortaa-Bold.otf
    assets/welcome/klde-guide-placeholder.png assets/welcome/klde-guide-wave.png
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
foreach(icon klde folder globe terminal note music settings wifi bluetooth moon sun volume power leaf search close weather cpu memory microphone battery bell overview display info previous next thermometer weather-clear weather-partly-cloudy weather-cloudy weather-rain weather-snow weather-thunderstorm weather-fog weather-extreme-heat weather-extreme-cold)
    list(APPEND klde_assets "assets/icons/${icon}.svg")
    list(APPEND klde_assets "assets/icons/${icon}-light.svg")
endforeach()
qt_add_resources(klde_ui klde_assets PREFIX / FILES ${klde_assets})

qt_add_executable(klde-shell src/shell/main.cpp)
target_link_libraries(klde-shell PRIVATE klde_ui klde_uiplugin Qt6::Quick Qt6::QuickControls2)
target_compile_definitions(klde-shell PRIVATE KLDE_VERSION="${PROJECT_VERSION}")
target_compile_options(klde-shell PRIVATE -Wall -Wextra -Wpedantic)

if(BUILD_TESTING)
    find_package(Qt6 6.8 REQUIRED COMPONENTS Test QuickTest)
    add_subdirectory(tests)
endif()

install(TARGETS klde-shell RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES packaging/org.klde.shell.preview.desktop
    DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/applications)
install(FILES assets/icons/klde.svg DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/scalable/apps)
install(DIRECTORY assets/fcitx5/klde-expressive-light assets/fcitx5/klde-expressive-dark
    DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/fcitx5/themes)
install(FILES LICENSE LICENSES/CC-BY-SA-4.0.txt LICENSES/OFL-1.1.txt
    DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/licenses/klde)

include(cmake/Packaging.cmake)

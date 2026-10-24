# SPDX-License-Identifier: GPL-3.0-or-later
set_source_files_properties(Tokens.qml MonetPalette.qml Assets.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
qt_add_qml_module(owode_visuals STATIC
    URI Owo.Visuals VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml/Owo/Visuals"
    QML_FILES
        ActionForm.ui.qml
        AnimatedAction.qml
        AppTile.qml
        AppTileForm.ui.qml
        Assets.qml
        BackgroundForm.ui.qml
        ChoiceAction.qml
        ChoicePageForm.ui.qml
        CompactSliderForm.ui.qml
        DesktopForm.ui.qml
        DockForm.ui.qml
        DockItem.qml
        DockItemForm.ui.qml
        Glyph.ui.qml
        LanguageForm.ui.qml
        LauncherForm.ui.qml
        LockCompositionForm.ui.qml
        MonetPalette.qml
        NotificationCardForm.ui.qml
        OsdForm.ui.qml
        PanelHeaderForm.ui.qml
        QuickSettingsForm.ui.qml
        RibbonForm.ui.qml
        SettingsForm.ui.qml
        SmallButton.qml
        SmallButtonForm.ui.qml
        StatusCapsuleForm.ui.qml
        SurfaceForm.ui.qml
        TelemetryCellForm.ui.qml
        TemporalLandscapeForm.ui.qml
        TemporalTextForm.ui.qml
        ThemeValues.ui.qml
        Tokens.qml
        WeatherForm.ui.qml
        WelcomeBrandForm.ui.qml
        WindowChromeForm.ui.qml
)
target_link_libraries(owode_visuals PUBLIC Qt6::Quick Qt6::QuickControls2)

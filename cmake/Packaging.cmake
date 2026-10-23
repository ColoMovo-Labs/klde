# SPDX-License-Identifier: GPL-3.0-or-later
# Distribution packages use system Qt; KLDE resources remain embedded in the binary.
set(CPACK_PACKAGE_NAME "klde-shell-preview")
set(CPACK_PACKAGE_VENDOR "KLDE contributors")
set(CPACK_PACKAGE_CONTACT "https://github.com/ColoMovo-Labs/klde/issues")
set(CPACK_PACKAGE_HOMEPAGE_URL "https://github.com/ColoMovo-Labs/klde")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Experimental KLDE desktop shell preview")
set(CPACK_PACKAGE_DESCRIPTION
    "Independent Qt Quick shell preview using mock system services.\n Runs in an ordinary window and does not replace a desktop session.")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set(CPACK_PACKAGING_INSTALL_PREFIX "/usr")
set(CPACK_STRIP_FILES TRUE)
set(CPACK_DEBIAN_PACKAGE_NAME "klde-shell-preview")
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "KLDE contributors")
set(CPACK_DEBIAN_PACKAGE_SECTION "x11")
set(CPACK_DEBIAN_PACKAGE_PRIORITY "optional")
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)
# These imports/plugins are loaded at runtime and cannot all be inferred from ELF.
set(CPACK_DEBIAN_PACKAGE_DEPENDS
    "qml6-module-qtqml, qml6-module-qtqml-models, qml6-module-qtqml-workerscript, qml6-module-qtquick, qml6-module-qtquick-controls, qml6-module-qtquick-effects, qml6-module-qtquick-layouts, qml6-module-qtquick-templates, qml6-module-qtquick-window, qt6-qpa-plugins, qt6-svg-plugins, qt6-wayland, fonts-dejavu-core, fonts-noto-cjk, fonts-noto-color-emoji")

# Fedora's cloud job also emits an experimental native RPM. The package keeps
# the technical klde-shell-preview name for compatibility while the installed
# desktop entry and UI use the public owoDE brand.
set(CPACK_RPM_PACKAGE_NAME "klde-shell-preview")
set(CPACK_RPM_PACKAGE_LICENSE "GPL-3.0-or-later")
set(CPACK_RPM_PACKAGE_GROUP "User Interface/Desktops")
set(CPACK_RPM_PACKAGE_REQUIRES
    "qt6-qtbase-gui, qt6-qtdeclarative, qt6-qtsvg, qt6-qtwayland, layer-shell-qt, dejavu-sans-fonts, google-noto-sans-cjk-vf-fonts, google-noto-color-emoji-fonts")
set(CPACK_RPM_FILE_NAME RPM-DEFAULT)

install(FILES "${CMAKE_SOURCE_DIR}/packaging/debian/copyright"
    DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/doc/klde-shell-preview")
install(FILES "${CMAKE_SOURCE_DIR}/packaging/README.md"
    DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/doc/klde-shell-preview"
    RENAME README.md)
install(FILES "${CMAKE_SOURCE_DIR}/LICENSE" "${CMAKE_SOURCE_DIR}/LICENSES/CC-BY-SA-4.0.txt" "${CMAKE_SOURCE_DIR}/LICENSES/OFL-1.1.txt"
    DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/doc/klde-shell-preview")
install(FILES "${CMAKE_SOURCE_DIR}/assets/fonts/comfortaa/OFL.txt"
    DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/doc/klde-shell-preview"
    RENAME Comfortaa-OFL.txt)
install(FILES "${CMAKE_SOURCE_DIR}/assets/fonts/rubik/OFL.txt"
    DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/doc/klde-shell-preview"
    RENAME Rubik-OFL.txt)
include(CPack)

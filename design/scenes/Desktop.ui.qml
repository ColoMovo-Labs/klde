// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Owo.Visuals
import ".."

DesktopForm {
    MockApplications {
        id: apps
    }
    applications: apps
}

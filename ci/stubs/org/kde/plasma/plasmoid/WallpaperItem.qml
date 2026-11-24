// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// A stand-in for Plasma's WallpaperItem (libplasma), for testing and
// linting the wallpaper package where Plasma isn't installed. It has what
// Plasma Login Manager gives a wallpaper: `configuration` and `pluginName`.
import QtQuick

Item {
    property var configuration: null
    property string pluginName: ""
}

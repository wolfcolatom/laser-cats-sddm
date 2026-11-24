// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats as a Plasma wallpaper: just the sky (the same sky/ as the SDDM
// theme, copied into the package by `make wallpaper`). For Plasma Login
// Manager's login screen, the Plasma desktop and the Plasma lock screen.
//
// A wallpaper doesn't know when a password goes in, so there is no
// explosion or warp; the cats float, the planet cats fire their lasers.
import QtQuick
import org.kde.plasma.plasmoid
import "sky"

WallpaperItem {
    id: wallpaper

    // Settings (contents/config/main.xml). `configuration` can be missing
    // where the host gives the wallpaper none. It is a property map whose
    // keys come from main.xml at run time, which the linter can't see.
    // qmllint disable missing-property
    readonly property bool calm: configuration ? configuration.Calm === true : false
    readonly property bool alwaysAnimate: configuration ? configuration.AlwaysAnimate === true : false
    // qmllint enable missing-property

    // Without GPU acceleration (Qt's software renderer) the animation can't
    // run smoothly: hold the sky still, as the login theme does.
    readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software

    // A maximised or fullscreen window covers the desktop: hold the sky
    // still, so nobody pays for an animation they can't see (unless
    // AlwaysAnimate). Held still, nothing in the sky draws a frame.
    property bool covered: coverMonitor.item ? (coverMonitor.item as CoverMonitor).covered : false
    readonly property bool paused: covered && !alwaysAnimate
    Loader {
        id: coverMonitor
        source: "CoverMonitor.qml"
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
    }
    Sky {
        objectName: "sky"
        anchors.fill: parent
        calm: wallpaper.calm
        frozen: wallpaper.softwareRendering || wallpaper.paused
    }
}

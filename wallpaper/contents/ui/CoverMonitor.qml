// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Whether the desktop is covered: a maximised or fullscreen window on this
// screen, and the desktop not being shown. The same test KDE's own picture
// wallpaper uses to pause animated pictures (org.kde.image,
// AnimatedImageComponent.qml).
//
// main.qml loads this with a Loader: where Plasma's image-wallpaper module
// or KWindowSystem isn't there (a login screen, a test), it fails to load
// on its own and the sky simply keeps running.
import QtQuick
import QtQuick.Window
import org.kde.plasma.wallpapers.image as PlasmaWallpaper
import org.kde.kwindowsystem

Item {
    id: root
    readonly property bool covered: monitor.count > 0 && !KWindowSystem.showingDesktop
    // the screen this wallpaper is on (Window.window needs an Item to ask)
    readonly property rect desktopRect: Window.window ? Qt.rect(Window.window.x, Window.window.y, Window.window.width, Window.window.height)
                                                      : Qt.rect(0, 0, 0, 0)

    PlasmaWallpaper.MaximizedWindowMonitor {
        id: monitor
        regionGeometry: root.desktopRect
    }
}

// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: the on-screen keyboard (Qt Virtual Keyboard), for touch
// screens. Only loaded when keyboard=true in theme.conf; it needs the
// qt6-virtualkeyboard package and InputMethod=qtvirtualkeyboard in SDDM's
// own settings (sddm.conf). It slides up from the bottom edge when shown
// and types into whatever has the focus; the login screen lifts its
// controls clear of it (panelHeight).
import QtQuick
import QtQuick.VirtualKeyboard

KeyboardPanel {
    id: root
    panelHeight: panel.height
    readonly property bool up: panel.y < root.height    // any of it on screen

    InputPanel {
        id: panel
        objectName: "inputPanel"
        // no wider than a real keyboard; its height follows from its width
        width: Math.min(root.width, 960)
        x: (root.width - width) / 2
        y: root.height                      // parked just below the screen
        visible: root.up
    }
    // only showing and hiding slide; laying it out doesn't
    states: State {
        name: "shown"
        when: root.shown
        PropertyChanges { panel.y: root.height - panel.height }
    }
    transitions: Transition {
        NumberAnimation { target: panel; property: "y"; duration: 200; easing.type: Easing.OutQuad }
    }
}

// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: the on-screen keyboard (Qt Virtual Keyboard), for touch
// screens. Only loaded when keyboard=true in theme.conf; it needs the
// qt6-virtualkeyboard package and InputMethod=qtvirtualkeyboard in SDDM's
// own settings (sddm.conf).
import QtQuick
import QtQuick.VirtualKeyboard

InputPanel {
    id: panel
    property bool shown: false              // set by the keyboard button
    visible: panel.y < panel.parent.height
    y: panel.shown ? panel.parent.height - panel.height : panel.parent.height
    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
}

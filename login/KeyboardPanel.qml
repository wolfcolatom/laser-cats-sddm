// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: what the login screen knows about an on-screen keyboard: it
// can be shown, and how much of the bottom of the screen it then takes.
// (VirtualKeyboard.qml is the real one; keeping this apart means the login
// screen loads even where Qt Virtual Keyboard isn't installed.)
import QtQuick

Item {
    property bool shown: false
    property real panelHeight: 0
}

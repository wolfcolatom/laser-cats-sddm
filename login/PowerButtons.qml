// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: the buttons in the corner: the on-screen keyboard (when there
// is one), Restart and Shut down (when the system allows them).
import QtQuick
import "../style"

Row {
    id: buttons
    required property Backend backend
    property bool keyboardAvailable: false
    property color accent: Theme.jade
    signal keyboardRequested()

    spacing: 10
    IconButton {
        objectName: "keyboardButton"
        visible: buttons.keyboardAvailable
        glyph: "../assets/keyboard.svg"; label: qsTr("On-screen keyboard"); accent: buttons.accent
        onClicked: buttons.keyboardRequested()
    }
    IconButton {
        objectName: "restartButton"
        visible: buttons.backend.canReboot
        glyph: "../assets/system-reboot.svg"; label: qsTr("Restart"); accent: buttons.accent
        onClicked: buttons.backend.reboot()
    }
    IconButton {
        objectName: "shutDownButton"
        visible: buttons.backend.canPowerOff
        glyph: "../assets/system-shutdown.svg"; label: qsTr("Shut down"); accent: buttons.accent
        onClicked: buttons.backend.powerOff()
    }
}

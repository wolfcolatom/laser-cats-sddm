// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: the password field: a PillField that hides what is typed.
import QtQuick

PillField {
    id: field
    property bool capsLock: false       // told to screen readers
    signal keyTyped()                   // any key, for the cats to react to

    echoMode: TextInput.Password
    passwordCharacter: "●"
    placeholderText: qsTr("Password")
    Accessible.name: qsTr("Password")
    Accessible.description: capsLock ? qsTr("Caps Lock is on") : ""

    Keys.onEscapePressed: text = ""
    Keys.onPressed: event => { field.keyTyped(); event.accepted = false }
}

// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: the password field: a dark pill inside a jade-to-amber edge
// that brightens with focus. shake() says no.
import QtQuick
import QtQuick.Controls.Basic
import "../style"

TextField {
    id: field
    property color accent: Theme.jade   // the edge starts with it
    property bool capsLock: false       // told to screen readers
    signal keyTyped()                   // any key, for the cats to react to
    readonly property real edge: activeFocus ? 0.6 : 0.36   // how strong the edge is

    function shake() { shaking.start() }

    width: 340; height: 54
    echoMode: TextInput.Password
    passwordCharacter: "●"
    horizontalAlignment: TextInput.AlignHCenter
    color: Theme.text
    placeholderText: qsTr("Password")
    placeholderTextColor: Theme.subtext
    font.pixelSize: 18
    Accessible.name: qsTr("Password")
    Accessible.description: capsLock ? qsTr("Caps Lock is on") : ""

    background: Rectangle {
        radius: height / 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.faded(field.accent, field.edge) }
            GradientStop { position: 1.0; color: Theme.faded(Theme.amberDeep, field.edge) }
        }
        Rectangle { anchors.fill: parent; anchors.margins: 1; radius: height / 2; color: Theme.surface }
    }
    Keys.onEscapePressed: text = ""
    Keys.onPressed: event => { field.keyTyped(); event.accepted = false }
    SequentialAnimation {
        id: shaking
        NumberAnimation { target: field; property: "x"; to: field.x - 10; duration: 50 }
        NumberAnimation { target: field; property: "x"; to: field.x + 10; duration: 50 }
        NumberAnimation { target: field; property: "x"; to: field.x; duration: 50 }
    }
}

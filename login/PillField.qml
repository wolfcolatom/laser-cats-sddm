// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: a text field as a dark pill inside a jade-to-amber edge that
// brightens with focus. shake() says no.
import QtQuick
import QtQuick.Controls.Basic
import "../style"

TextField {
    id: field
    property color accent: Theme.jade   // the edge starts with it
    readonly property real edge: activeFocus ? 0.6 : 0.36   // how strong the edge is

    function shake() { shaking.restart() }

    width: 340; height: 54
    horizontalAlignment: TextInput.AlignHCenter
    color: Theme.text
    placeholderTextColor: Theme.subtext
    font.pixelSize: 18

    background: Rectangle {
        radius: height / 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.faded(field.accent, field.edge) }
            GradientStop { position: 1.0; color: Theme.faded(Theme.amberDeep, field.edge) }
        }
        Rectangle { anchors.fill: parent; anchors.margins: 1; radius: height / 2; color: Theme.surface }
    }
    // the shake moves the drawing, not the field: its place stays the layout's
    transform: Translate { id: nudge }
    SequentialAnimation {
        id: shaking
        NumberAnimation { target: nudge; property: "x"; to: -10; duration: 50 }
        NumberAnimation { target: nudge; property: "x"; to: 10; duration: 50 }
        NumberAnimation { target: nudge; property: "x"; to: 0; duration: 50 }
    }
}

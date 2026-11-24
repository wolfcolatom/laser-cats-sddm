// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: a small square icon button on a solid dark fill; its name
// shows as a rounded tooltip on hover or keyboard focus.
import QtQuick
import QtQuick.Controls.Basic
import "../style"

Button {
    id: button
    required property url glyph         // the picture on it (Button has its own `icon`)
    required property string label
    property color accent: Theme.jade

    width: 40; height: 40
    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()
    Accessible.name: label
    contentItem: Image { source: button.glyph; sourceSize: Qt.size(20, 20); fillMode: Image.Pad }
    background: Rectangle {
        radius: 9
        color: button.hovered ? Theme.surfaceHover : Theme.surface
        border.width: button.visualFocus ? 2 : 1
        border.color: button.visualFocus ? button.accent : button.hovered ? Theme.outlineHover : Theme.outline
    }
    ToolTip {
        visible: button.hovered || button.visualFocus
        delay: 400
        y: -implicitHeight - 8
        x: (button.width - implicitWidth) / 2
        contentItem: Text { text: button.label; color: Theme.text; font.pixelSize: 14 }
        background: Rectangle { radius: 10; color: Theme.surface; border.width: 1; border.color: Theme.outlineHover }
        padding: 8; leftPadding: 12; rightPadding: 12
    }
}

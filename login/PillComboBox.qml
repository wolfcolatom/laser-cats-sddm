// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: a pill-shaped drop-down, for the account and session lists.
// The model needs a "name" role.
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import "../style"

ComboBox {
    id: picker
    property bool solid: true           // a dark fill, or see-through until hovered
    property bool centred: false        // text in the middle, or at the left
    property bool opensUp: false        // the list above it, or below
    property color accent: Theme.jade   // the keyboard-focus ring
    readonly property real labelWidth: label.implicitWidth

    textRole: "name"
    contentItem: Text {
        id: label
        leftPadding: picker.centred ? 0 : 18
        text: picker.displayText
        color: Theme.subtext
        font: picker.font
        horizontalAlignment: picker.centred ? Text.AlignHCenter : Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
    }
    indicator: Text {
        x: picker.width - width - 16; anchors.verticalCenter: parent.verticalCenter
        text: "▾"; color: Theme.subtext; font.pixelSize: 14
    }
    background: Rectangle {
        radius: height / 2
        color: picker.solid ? (picker.hovered ? Theme.surfaceHover : Theme.surface)
                            : (picker.hovered ? Theme.faintHover : "transparent")
        border.width: picker.visualFocus ? 2 : 1
        border.color: picker.visualFocus ? picker.accent
                    : picker.solid ? (picker.hovered ? Theme.outlineHover : Theme.outline)
                                   : (picker.hovered ? Theme.outline : "transparent")
    }
    // the list: a rounded panel
    popup: Popup {
        y: picker.opensUp ? -implicitHeight - 6 : picker.height + 6
        width: picker.width
        padding: 6
        implicitHeight: contentItem.implicitHeight + 12
        contentItem: ListView {
            clip: true
            spacing: 2
            implicitHeight: contentHeight
            model: picker.popup.visible ? picker.delegateModel : null
            currentIndex: picker.highlightedIndex
        }
        background: Rectangle { radius: 16; color: Theme.panel; border.width: 1; border.color: Theme.outline }
    }
    delegate: ItemDelegate {
        id: entry
        required property var model
        required property int index
        objectName: picker.objectName + "-" + index
        width: picker.width - 12
        text: model.name
        highlighted: picker.highlightedIndex === index
        contentItem: Text {
            text: entry.text; color: Theme.text; font: picker.font
            leftPadding: picker.centred ? 0 : 10
            horizontalAlignment: picker.centred ? Text.AlignHCenter : Text.AlignLeft
        }
        background: Rectangle { color: entry.highlighted ? Theme.surfaceHover : Theme.panel; radius: 10 }
    }
}

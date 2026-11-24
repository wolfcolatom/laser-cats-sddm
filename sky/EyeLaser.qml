// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: a laser fired from one of the warp cat's eyes: a flash in the
// eye, and a beam (white-hot at the eye, then its colour, with a soft halo)
// growing out toward the edge of the screen and swinging a little.
import QtQuick
import "../style"

Item {
    id: laser
    required property point eye         // where the eye is on screen
    required property color colour
    required property real angle        // the way it points at first (degrees, 0 = right)
    required property real sweep        // how far it swings as it fires (degrees)
    required property real progress     // 0 -> 1 as it fires
    required property real fade         // 1 -> 0 as the warp ends
    required property real reach        // its full length
    required property real catScale     // 1 on a 1080 px tall screen

    readonly property real thick: (6 + 12 * progress) * catScale
    readonly property real len: Math.sqrt(progress) * reach
    readonly property real turn: angle + sweep * progress
    readonly property real show: fade * Math.min(1, progress * 3)

    Rectangle {                         // the halo
        x: laser.eye.x; y: laser.eye.y - height / 2
        width: laser.len; height: laser.thick * 3.5; radius: height / 2
        transformOrigin: Item.Left; rotation: laser.turn
        opacity: laser.show * 0.3
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: laser.colour }
            GradientStop { position: 1.0; color: Theme.clear(laser.colour) }
        }
    }
    Rectangle {                         // the beam
        x: laser.eye.x; y: laser.eye.y - height / 2
        width: laser.len; height: laser.thick; radius: height / 2
        transformOrigin: Item.Left; rotation: laser.turn
        opacity: laser.show
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.white }
            GradientStop { position: 0.12; color: laser.colour }
            GradientStop { position: 1.0; color: Theme.clear(laser.colour) }
        }
    }
    Image {                             // the flash in the eye
        source: "../assets/glow.png"
        width: 150 * laser.catScale * (0.5 + laser.progress); height: width
        x: laser.eye.x - width / 2; y: laser.eye.y - height / 2
        opacity: laser.fade * Math.min(1, laser.progress * 4)
    }
}

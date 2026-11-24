// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: how the cats react to the keyboard: a little brighter for a
// moment on a key press (flash), washed amber on a wrong password (alarm).
// Used as a layer effect:
//   layer.enabled: flash > 0.01 || alarm > 0.01
//   layer.effect: FlashEffect { flash: ...; alarm: ... }
import QtQuick.Effects
import "../style"

MultiEffect {
    required property real flash        // 0-1
    required property real alarm        // 0-1
    brightness: flash * 0.25
    colorization: alarm * 0.75
    colorizationColor: Theme.amber
}

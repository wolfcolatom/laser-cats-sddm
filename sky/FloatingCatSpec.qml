// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: a cat floating across the sky (its lasers are in its picture).
import QtQml

QtObject {
    required property string file       // in assets/
    required property real size         // x the picture, on a 1080 px tall screen
    required property real lane         // how far down the screen it floats (0-1)
    required property real speed        // px a second
    required property real start        // where in its crossing it begins (0-1)
    property bool mirror: false         // facing the other way
    property int frame: 0               // first frame shown, so the cats don't move in step
}

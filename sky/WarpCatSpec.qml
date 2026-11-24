// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: the face in the warp. The picture is padded so the screen's
// centre falls between its eyes.
import QtQml

QtObject {
    required property string file       // in assets/
    required property real size         // its height at full warp, x the screen height
    // each eye's offset from the picture's centre, as a fraction of its size
    required property point leftEye
    required property point rightEye
}

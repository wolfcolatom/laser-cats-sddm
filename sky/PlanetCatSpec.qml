// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: the cat rising from behind each planet. Positions are in the
// picture's own pixels; x, y and scale place the picture in PlanetCat's
// 460 x 520 box (the planet is centred at 220, 330, radius 105).
import QtQml

QtObject {
    required property string file       // in assets/
    property bool animated: false
    required property real x            // where the picture's top-left goes
    required property real y
    property real scale: 1              // how big it is drawn
    // its paws, one point per frame of its animation (one point if it's still)
    required property list<point> leftPaw
    required property list<point> rightPaw
    required property list<BeamSpec> beams
    // a beam's half-width where it lands: base + length x growth
    required property real spreadBase
    required property real spreadGrowth
}

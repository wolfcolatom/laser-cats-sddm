// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: everything about the cat pictures, in one place: which file,
// how big it is drawn, and where its paws and eyes are, so the lasers line
// up with them (tests/tst_cats.qml checks they lie inside the pictures).
// Two sets: the theme's own cats, and the classic GIF cats get-cats.sh makes.
import QtQml

QtObject {
    readonly property CatSet own: CatSet {
        floaters: [
            FloatingCatSpec { file: "cat-front.webp";  size: 0.50; lane: 0.06; speed: 31; start: 0.48; frame: 2 },
            FloatingCatSpec { file: "cat-ginger.webp"; size: 0.52; lane: 0.55; speed: 21; start: 0.33; frame: 4 },
            FloatingCatSpec { file: "cat-leap.webp";   size: 0.50; lane: 0.82; speed: 30; start: 0.95; frame: 6; mirror: true }
        ]
        planetCat: PlanetCatSpec {
            file: "planet-cat-roar.webp"; animated: true
            x: 71; y: 45; scale: 0.76
            leftPaw: [ Qt.point(61, 204), Qt.point(58, 193), Qt.point(57, 181), Qt.point(54, 155), Qt.point(46, 118),
                       Qt.point(42, 89), Qt.point(48, 110), Qt.point(57, 169), Qt.point(60, 195) ]
            rightPaw: [ Qt.point(337, 215), Qt.point(339, 206), Qt.point(337, 209), Qt.point(348, 172), Qt.point(349, 115),
                        Qt.point(346, 88), Qt.point(344, 132), Qt.point(340, 199), Qt.point(333, 232) ]
            // each paw fires down its own side of the planet, so the beams miss its face
            beams: [
                BeamSpec { paw: 0; angle: 200; sweep: 9; speed: 0.9 },
                BeamSpec { paw: 0; angle: 228; sweep: 8; speed: 1.3 },
                BeamSpec { paw: 1; angle: 340; sweep: 9; speed: 1.1 },
                BeamSpec { paw: 1; angle: 312; sweep: 8; speed: 0.8 }
            ]
            spreadBase: 5; spreadGrowth: 0.05
        }
        warpCat: WarpCatSpec {
            file: "warp-cat.webp"; size: 1.7
            leftEye: Qt.point(-0.105, 0.049); rightEye: Qt.point(0.136, 0.046)
        }
    }

    readonly property CatSet classic: CatSet {
        floaters: [
            FloatingCatSpec { file: "cat-b-mint.webp"; size: 0.55; lane: 0.09; speed: 31; start: 0.48; frame: 13; mirror: true },
            FloatingCatSpec { file: "cat-a-jade.webp"; size: 0.58; lane: 0.57; speed: 21; start: 0.33; frame: 4 },
            FloatingCatSpec { file: "cat-a-jade.webp"; size: 0.54; lane: 0.84; speed: 30; start: 0.95; frame: 24; mirror: true }
        ]
        planetCat: PlanetCatSpec {
            file: "planet-cat.png"
            x: 60; y: 74
            leftPaw: [ Qt.point(16, 91) ]
            rightPaw: [ Qt.point(299, 34) ]
            // one beam down each paw's own side, one crossing over its body
            beams: [
                BeamSpec { paw: 0; angle: 205; sweep: 16; speed: 0.9 },
                BeamSpec { paw: 0; angle: 312; sweep: 14; speed: 1.3 },
                BeamSpec { paw: 1; angle: 330; sweep: 16; speed: 1.1 },
                BeamSpec { paw: 1; angle: 228; sweep: 14; speed: 0.8 }
            ]
            spreadBase: 7; spreadGrowth: 0.06
        }
        warpCat: WarpCatSpec {
            file: "spiral-cat.webp"; size: 1.6
            leftEye: Qt.point(-0.1367, -0.0065); rightEye: Qt.point(0.1628, 0)
        }
    }
}

// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: the starfield and nebula, drifting right in layers.
//
// A still backdrop holding most of the stars, and three thinner layers
// drifting right at the speeds measured from the original art (16 / 37 / 68
// px a second); behind them, faint nebula wisps drift slower still (7 / 11).
// Drawn by tools/make-stars.py and tools/make-haze.py.
pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: starfield
    anchors.fill: parent

    required property bool running      // shown and moving
    required property real clock        // seconds since the sky started
    property bool jadeNebula: true      // the jade nebula, or the olive haze

    Repeater {
        model: starfield.running ? [ { file: starfield.jadeNebula ? "haze-jade" : "haze-far", speed: 7 },
                                     { file: "haze-near", speed: 11 },
                                     { file: "stars-still", speed: 0 }, { file: "stars-far", speed: 16 },
                                     { file: "stars-mid", speed: 37 }, { file: "stars-near", speed: 68 } ] : []
        Item {
            id: band
            required property var modelData
            anchors.fill: parent
            // each layer is a 1920x1080 picture: scaled up to fill a taller
            // screen (never down, so the stars keep their size on smaller
            // ones), and repeated side by side to cover any width
            readonly property string file: modelData.file
            readonly property real s: Math.max(1, starfield.height / 1080)
            readonly property real tw: 1920 * s
            readonly property real th: 1080 * s
            readonly property real offset: (starfield.clock * modelData.speed * s) % tw
            Repeater {
                model: Math.ceil(starfield.width / band.tw) + 1
                Image {
                    required property int index
                    source: "assets/" + band.file + ".png"
                    asynchronous: true
                    smooth: band.s !== Math.round(band.s)   // crisp at 1x and 2x, soft in between
                    x: Math.round(band.offset + (index - 1) * band.tw); y: 0
                    width: band.tw; height: band.th
                }
            }
        }
    }
}

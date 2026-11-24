// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: the starfield and nebula, drifting right in layers.
pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: starfield
    anchors.fill: parent
    property var sky                    // the Sky it belongs to (sizes, state)

    // the starfield, measured from the GIF: a still backdrop holding most of
    // the stars, and three thinner layers drifting right at its speeds (16 /
    // 37 / 68 px a second); pre-drawn by a generator script. Behind them,
    // faint nebula wisps drift slower still (7 / 11).
    Repeater {
        model: starfield.sky.running ? [ { file: starfield.sky.jadeNebula ? "haze-jade" : "haze-far", speed: 7 }, { file: "haze-near", speed: 11 },
                               { file: "stars-still", speed: 0 }, { file: "stars-far", speed: 16 },
                               { file: "stars-mid", speed: 37 }, { file: "stars-near", speed: 68 } ] : []
        Item {
            required property var modelData
            id: band
            anchors.fill: parent
            // each layer is a 1920x1080 picture: scaled up to fill a taller
            // screen (never down, so the stars keep their size on smaller
            // ones), and repeated side by side to cover any width
            readonly property string file: modelData.file   // (inside the inner Repeater, modelData is the copy number)
            readonly property real s: Math.max(1, starfield.sky.height / 1080)
            readonly property real tw: 1920 * s
            readonly property real th: 1080 * s
            property real offset: 0
            onTwChanged: if (drift.running) drift.restart()
            NumberAnimation on offset {
                id: drift
                from: 0; to: band.tw; loops: Animation.Infinite
                running: band.modelData.speed > 0
                duration: band.tw / Math.max(band.modelData.speed * band.s, 1) * 1000
            }
            Repeater {
                model: Math.ceil(starfield.sky.width / band.tw) + 1
                Image {
                    required property int index
                    source: "assets/" + band.file + ".png"; asynchronous: true
                        smooth: band.s !== Math.round(band.s)   // crisp at 1x and 2x, soft in between
                        x: Math.round(band.offset + (index - 1) * band.tw); y: 0
                        width: band.tw; height: band.th }
            }
        }
    }
}

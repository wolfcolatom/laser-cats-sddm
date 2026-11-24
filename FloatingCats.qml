// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: the laser cats floating across the sky.
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import "Palette.js" as Palette

// the floating cats, in one layer so they can flash brighter on a key
// press and wash amber on a wrong password, all together
Item {
    id: catLayer
    required property bool running      // shown
    required property bool playing      // their animations play (off while held still)
    required property real clock        // seconds since the sky started
    required property real catScale     // 1 on a 1080 px tall screen
    required property real flash        // 0-1: brighter for a moment on a key press
    required property real alarm        // 0-1: washed amber on a wrong password
    required property real blast        // 0-1: the planets blowing up flings them away
    required property var cats          // the floating cats to show (Cats.js)
    anchors.fill: parent
    layer.enabled: flash > 0.01 || alarm > 0.01
    layer.effect: MultiEffect {
        brightness: catLayer.flash * 0.25
        colorization: catLayer.alarm * 0.75
        colorizationColor: Palette.amber
    }

    // single laser cats, floating right with the stars, one per lane,
    // starting spread around the loop so they pass rather than pile up; some
    // face the other way. Each bobs and turns a little; their lasers are
    // part of their animation.
    Repeater {
        model: catLayer.running ? catLayer.cats : []         // (lanes, sizes, speeds: Cats.js)
        AnimatedImage {
            required property var modelData
            required property int index
            asynchronous: true          // load in the background: the lock shows at once
            id: floater
            source: "assets/" + modelData.file
            width: sourceSize.width * modelData.s * catLayer.catScale; height: sourceSize.height * modelData.s * catLayer.catScale
            smooth: true
            mirror: modelData.mirror
            opacity: 0.95
            playing: catLayer.playing
            readonly property real t: catLayer.clock
            readonly property real baseX: (modelData.start * (catLayer.width + width) + floater.t * modelData.speed) % (catLayer.width + width) - width
            readonly property real baseY: modelData.y * catLayer.height + 9 * Math.sin(floater.t * 0.8 + modelData.frame)
            // the planets blowing up fling it off the screen: outward from
            // the middle, spinning (blast 0 -> 1 over the explosion)
            readonly property real gust: Math.max(0, catLayer.blast)          // steady, so you see them go
            readonly property real away: Math.atan2(baseY + height / 2 - catLayer.height / 2, baseX + width / 2 - catLayer.width / 2)
            readonly property real fling: gust * Math.max(catLayer.width, catLayer.height) * 1.4
            x: baseX + Math.cos(away) * fling
            y: baseY + Math.sin(away) * fling
            rotation: 8 * Math.sin(floater.t * 0.25 + modelData.frame) + gust * (index % 2 ? 540 : -540)
            onStatusChanged: if (status === AnimatedImage.Ready) currentFrame = modelData.frame % frameCount
        }
    }
}

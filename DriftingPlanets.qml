// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: the far-off planets drifting slowly behind everything.
pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: drifting
    anchors.fill: parent
    property var sky                    // the Sky it belongs to (sizes, state)

    // planets in jade and amber: a jade gas giant,
    // an amber ringed planet, a small mint moon; drifting right very slowly,
    // far behind the laser cats, each its own speed
    Repeater {
        model: drifting.sky.running ? [
            { file: "amber", y: 0.60, speed: 6, start: 0.72, opacity: 0.9 },
            { file: "moon",  y: 0.30, speed: 8, start: 0.47, opacity: 0.85 }
        ] : []
        Image {
            required property var modelData
            asynchronous: true          // load in the background: the lock shows at once
            id: planet
            source: "assets/planet-" + modelData.file + ".png"
            smooth: true
            opacity: modelData.opacity
            // sized for a 1080 px tall screen, like the cats
            width: sourceSize.width * drifting.sky.catScale; height: sourceSize.height * drifting.sky.catScale
            property real t: 0          // seconds it has been drifting
            FrameAnimation { running: true; onTriggered: planet.t += frameTime }
            x: (modelData.start * (drifting.sky.width + width) + planet.t * modelData.speed) % (drifting.sky.width + width) - width
            y: modelData.y * drifting.sky.height
        }
    }
}

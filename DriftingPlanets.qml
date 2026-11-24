// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: the far-off planets (an amber ringed planet, a small moon)
// drifting right very slowly behind everything, each at its own speed.
pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: drifting
    anchors.fill: parent

    required property bool running      // shown
    required property real clock        // seconds since the sky started
    required property real catScale     // 1 on a 1080 px tall screen

    Repeater {
        // y: height (fraction of the screen); speed: px a second; start:
        // where along its crossing it begins (0-1)
        model: drifting.running ? [
            { file: "amber", y: 0.60, speed: 6, start: 0.72, opacity: 0.9 },
            { file: "moon",  y: 0.30, speed: 8, start: 0.47, opacity: 0.85 }
        ] : []
        Image {
            id: planet
            required property var modelData
            asynchronous: true          // load in the background: the screen shows at once
            source: "assets/planet-" + modelData.file + ".png"
            smooth: true
            opacity: modelData.opacity
            width: sourceSize.width * drifting.catScale; height: sourceSize.height * drifting.catScale
            readonly property real span: drifting.width + width
            x: (modelData.start * span + drifting.clock * modelData.speed) % span - width
            y: modelData.y * drifting.height
        }
    }
}

// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: a tiny explosion where a laser hits the planet: a soft flash
// and a spray of sparks flying off the surface (away from the planet), with
// a few dim embers drifting a little further. go() sets one off.
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import "../style"
import "Rng.js" as Rng

Item {
    id: impact
    width: 0; height: 0
    visible: p < 1
    property real p: 1                      // 0 -> 1 over the burst
    property color colour: Theme.amber
    property real outward: 0                // direction off the surface (radians)
    property var dirs: []                   // each spark's direction and reach
    property var reach: []
    readonly property int durationMs: 520

    // at (px, py), in `c`, flying off the surface in direction `out` (radians)
    function go(px, py, c, out) {
        x = px; y = py; colour = c; outward = out
        let n = 8 + Math.floor(Rng.next() * 3), ds = [], rs = []
        for (let k = 0; k < n; k++) {
            ds.push(out + (Rng.next() - 0.5) * 2.4)      // a fan of about +/-70 degrees
            rs.push(12 + Rng.next() * 20)
        }
        dirs = ds; reach = rs
        pop.restart()
    }
    NumberAnimation { id: pop; target: impact; property: "p"; from: 0; to: 1; duration: impact.durationMs; easing.type: Easing.Linear }

    Rectangle {                             // the flash
        x: -width / 2; y: -height / 2
        width: 26 * (0.4 + impact.p); height: width; radius: width / 2
        color: impact.colour
        opacity: Math.max(0, 0.7 * (1 - impact.p * 2.2))
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 0.8; blurMax: 12 }
    }
    Rectangle {                             // its white-hot centre
        x: -4; y: -4; width: 8; height: 8; radius: 4
        color: Theme.white
        opacity: Math.max(0, 1 - impact.p * 3)
    }
    Repeater {                              // sparks
        model: impact.dirs.length
        Rectangle {
            required property int index
            readonly property real a: impact.dirs[index] || 0
            readonly property real d: (impact.reach[index] || 20) * (1 - Math.pow(1 - impact.p, 2.2))
            width: 2 + 7 * (1 - impact.p); height: 2; radius: 1
            x: Math.cos(a) * d - width / 2; y: Math.sin(a) * d - 1
            rotation: a * 180 / Math.PI
            color: index % 3 === 0 ? Theme.white : impact.colour
            opacity: Math.max(0, 1 - impact.p * 1.15)
        }
    }
    Repeater {                              // embers
        model: 3
        Rectangle {
            required property int index
            readonly property real a: impact.outward + (index - 1) * 0.7
            readonly property real d: 34 * impact.p
            width: 2; height: 2; radius: 1
            x: Math.cos(a) * d - 1; y: Math.sin(a) * d - 1 + 6 * impact.p * impact.p
            color: impact.colour
            opacity: Math.max(0, 0.6 * (1 - impact.p))
        }
    }
}

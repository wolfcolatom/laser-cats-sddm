// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: a planet blowing up: a quick blinding flash, bright streaks
// flung out from it, and a dozen glowing rocks tumbling away. (The fire,
// smoke and embers are PlanetFire's.) Fills the PlanetCat box.
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import "../style"

Item {
    id: explosion
    anchors.fill: parent
    required property point centre      // the planet's centre
    required property real radius       // and radius
    required property real boom         // 0 -> 1 over the explosion
    required property real e            // the same, eased (fast start)

    readonly property int streaks: 36
    readonly property int rocks: 14

    Rectangle {                         // the flash
        visible: explosion.boom > 0 && opacity > 0
        width: explosion.radius * 2 * (0.8 + explosion.e * 1.2); height: width; radius: width / 2
        x: explosion.centre.x - width / 2; y: explosion.centre.y - height / 2
        color: Theme.flare
        opacity: Math.max(0, 0.95 - explosion.e * 2.8)
        layer.enabled: visible
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 48 }
    }
    Repeater {                          // bright streaks
        model: explosion.boom > 0 ? explosion.streaks : 0
        Rectangle {
            required property int index
            readonly property real a: index / explosion.streaks * 2 * Math.PI + Math.sin(index * 5.7) * 0.15
            readonly property real d: explosion.radius * (0.6 + explosion.e * (2.2 + Math.abs(Math.sin(index * 2.3)) * 2.4))
            width: 18 + 40 * explosion.e * (1 - explosion.e) * 4; height: 2.5; radius: 1.25
            x: explosion.centre.x + Math.cos(a) * d - width / 2; y: explosion.centre.y + Math.sin(a) * d - 1
            rotation: a * 180 / Math.PI
            color: index % 3 === 0 ? Theme.white : index % 3 === 1 ? Theme.amber : Theme.flare
            opacity: Math.max(0, 1 - explosion.e * 1.1)
        }
    }
    Repeater {                          // rocks
        model: explosion.boom > 0 ? explosion.rocks : 0
        Image {
            required property int index
            asynchronous: true
            readonly property real a: index / explosion.rocks * 2 * Math.PI + Math.sin(index * 7.3) * 0.25
            readonly property real reach: 260 + 220 * Math.abs(Math.sin(index * 3.1))
            source: "../assets/rock-" + (index % 4 + 1) + ".png"
            smooth: true
            scale: 2.2 - (index % 4) * 0.35
            x: explosion.centre.x + Math.cos(a) * explosion.e * reach - width / 2
            y: explosion.centre.y + Math.sin(a) * explosion.e * reach - height / 2
            rotation: explosion.e * (index % 2 ? 1 : -1) * (200 + index * 25)
            opacity: Math.max(0, 1 - explosion.e * explosion.e)
        }
    }
}

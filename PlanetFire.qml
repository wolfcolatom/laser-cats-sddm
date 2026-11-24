// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: a planet on fire: flames and embers where each laser lands,
// smaller fires along its rim, fireballs, smoke and debris from the
// impacts, chips of rock knocked off it, and the blast when it explodes.
// Fills the PlanetCat box.
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Particles
import "Palette.js" as Palette

Item {
    id: fire
    anchors.fill: parent
    required property bool active       // particles moving (off while held still)
    required property bool burning      // the steady fires (they go out when it blows up)
    required property point centre      // the planet's centre
    required property real radius       // and radius
    required property Repeater beams    // the lasers (Beam), for where they land

    // a hit at (px, py), flying off the surface in direction `outward` (radians)
    function impact(px, py, outward) {
        impactAngle = outward * 180 / Math.PI
        impactBall.burst(18, px, py)
        impactCore.burst(6, px, py)
        impactSmoke.burst(4, px, py)
        impactDebris.burst(12, px, py)
    }
    // n chips of rock knocked off at (px, py), after impact() set the direction
    function chips(n, px, py) { impactChip.burst(n, px, py) }
    // the planet exploding: a fireball, smoke and embers
    function blast() { blastFire.burst(320); blastSmoke.burst(28); blastEmbers.burst(90) }

    ParticleSystem { id: blaze; anchors.fill: parent; running: fire.active }
    ImageParticle {
        anchors.fill: parent
        system: blaze; groups: ["smoke"]
        source: "assets/smoke.png"
        color: "#30302c"; colorVariation: 0.05
        alpha: 0.35; alphaVariation: 0.1
        entryEffect: ImageParticle.Fade
    }
    ImageParticle {
        anchors.fill: parent
        system: blaze; groups: ["fire"]
        source: "assets/glow.png"
        color: Palette.amber; colorVariation: 0.12
        redVariation: 0.05; greenVariation: 0.15
        alpha: 0.85
        entryEffect: ImageParticle.Scale
    }
    ImageParticle {                         // impact smoke, rolling out of the fireballs
        anchors.fill: parent
        system: blaze; groups: ["puff"]
        source: "assets/smoke.png"
        color: "#3b332b"; colorVariation: 0.06
        alpha: 0.45; alphaVariation: 0.1
        entryEffect: ImageParticle.Fade
    }
    ImageParticle {                         // the little flames
        anchors.fill: parent
        system: blaze; groups: ["flame"]
        source: "assets/flame.png"          // a teardrop pointing the way it moves
        autoRotation: true
        color: "#ff8a26"; colorVariation: 0.08
        alpha: 0.6; alphaVariation: 0.12
        entryEffect: ImageParticle.Scale
    }
    ImageParticle {                         // impact fireballs: orange
        anchors.fill: parent
        system: blaze; groups: ["ball"]
        source: "assets/glow.png"
        color: "#ff8a30"; colorVariation: 0.1
        redVariation: 0.04; greenVariation: 0.12
        alpha: 1.0
        entryEffect: ImageParticle.Fade
    }
    ImageParticle {                         // their white-hot middles
        anchors.fill: parent
        system: blaze; groups: ["ballcore"]
        source: "assets/glow.png"
        color: "#fff1c4"
        alpha: 0.95
        entryEffect: ImageParticle.Fade
    }
    ImageParticle {                         // chunks of planet chipped off by the lasers
        anchors.fill: parent
        system: blaze; groups: ["chip"]
        source: "assets/rock-2.png"
        color: "#8a7a6a"; colorVariation: 0.15
        rotationVariation: 180; rotationVelocityVariation: 260
        entryEffect: ImageParticle.None
    }
    ImageParticle {                         // hot debris thrown off the impacts
        anchors.fill: parent
        system: blaze; groups: ["debris"]
        source: "assets/glow.png"
        color: "#ffc874"; colorVariation: 0.1
        alpha: 0.95
    }
    ImageParticle {
        anchors.fill: parent
        system: blaze; groups: ["ember"]
        source: "assets/glow.png"
        color: Palette.flare; colorVariation: 0.1
        alpha: 0.9
    }
    // fire where each beam lands (follows the sweep), flying off the surface
    Repeater {
        model: fire.beams.count
        Emitter {
            id: hitFire
            required property int index
            readonly property Beam b: fire.beams.itemAt(index) as Beam
            readonly property real outward: b ? Math.atan2(b.to.y - fire.centre.y, b.to.x - fire.centre.x) * 180 / Math.PI : -90
            enabled: fire.burning
            system: blaze; group: "fire"
            x: (b ? b.to.x : 0) - 6; y: (b ? b.to.y : 0) - 6; width: 12; height: 12
            emitRate: 45; lifeSpan: 650; lifeSpanVariation: 250
            size: 16; endSize: 3; sizeVariation: 6
            velocity: AngleDirection { angle: hitFire.outward; angleVariation: 40; magnitude: 45; magnitudeVariation: 25 }
            acceleration: PointDirection { y: -30 }
        }
    }
    // a little real flame on top: teardrop flames licking up off each hit
    Repeater {
        model: fire.beams.count
        Emitter {
            id: hitFlame
            required property int index
            readonly property Beam b: fire.beams.itemAt(index) as Beam
            readonly property real outward: b ? Math.atan2(b.to.y - fire.centre.y, b.to.x - fire.centre.x) * 180 / Math.PI : -90
            enabled: fire.burning
            system: blaze; group: "flame"
            x: (b ? b.to.x : 0) - 5; y: (b ? b.to.y : 0) - 5; width: 10; height: 10
            emitRate: 26; lifeSpan: 420; lifeSpanVariation: 140
            size: 18; endSize: 8; sizeVariation: 5
            velocity: AngleDirection { angle: hitFlame.outward; angleVariation: 30; magnitude: 30; magnitudeVariation: 10 }
            acceleration: PointDirection { y: -70; xVariation: 15 }
        }
    }
    // smaller fires dotted along the upper rim
    Repeater {
        model: [-160, -128, -100, -78, -18, 12]
        Emitter {
            id: rimFire
            required property var modelData
            readonly property real a: modelData * Math.PI / 180
            enabled: fire.burning
            system: blaze; group: "fire"
            x: fire.centre.x + fire.radius * 0.97 * Math.cos(a) - 5; y: fire.centre.y + fire.radius * 0.97 * Math.sin(a) - 5
            width: 10; height: 10
            emitRate: 14; lifeSpan: 800; lifeSpanVariation: 300
            size: 11; endSize: 2; sizeVariation: 4
            velocity: AngleDirection { angle: rimFire.modelData; angleVariation: 30; magnitude: 22; magnitudeVariation: 10 }
            acceleration: PointDirection { y: -25 }
        }
    }
    // the blast's fire (fired once by the explosion)
    Emitter {
        id: blastFire
        system: blaze; group: "fire"
        x: fire.centre.x - fire.radius; y: fire.centre.y - fire.radius
        width: fire.radius * 2; height: fire.radius * 2
        shape: EllipseShape { fill: true }
        enabled: false
        lifeSpan: 550; lifeSpanVariation: 150         // a quick fireball that's gone fast
        size: 44; endSize: 10; sizeVariation: 18
        velocity: TargetDirection { targetX: fire.radius; targetY: fire.radius; proportionalMagnitude: true; magnitude: -2.6; magnitudeVariation: 1.6 }
    }
    Emitter {
        id: blastSmoke
        system: blaze; group: "smoke"
        x: fire.centre.x - fire.radius * 0.8; y: fire.centre.y - fire.radius * 0.8
        width: fire.radius * 1.6; height: fire.radius * 1.6
        shape: EllipseShape { fill: true }
        enabled: false
        lifeSpan: 2200; lifeSpanVariation: 600
        size: 70; endSize: 170; sizeVariation: 30
        velocity: TargetDirection { targetX: fire.radius * 0.8; targetY: fire.radius * 0.8; proportionalMagnitude: true; magnitude: -0.9; magnitudeVariation: 0.5 }
    }
    Emitter {
        id: blastEmbers
        system: blaze; group: "ember"
        x: fire.centre.x - fire.radius * 0.5; y: fire.centre.y - fire.radius * 0.5
        width: fire.radius; height: fire.radius
        enabled: false
        lifeSpan: 800; lifeSpanVariation: 250
        size: 5; endSize: 1; sizeVariation: 2
        velocity: AngleDirection { angle: 0; angleVariation: 180; magnitude: 260; magnitudeVariation: 140 }
    }

    // explosive impacts: where a beam hits, a fireball blooms with a white-hot
    // middle, rolls out into smoke and throws hot debris off the surface
    // (impact()); impactAngle is the direction off the surface for that hit
    property real impactAngle: -90
    Emitter {
        id: impactBall
        system: blaze; group: "ball"; width: 2; height: 2; enabled: false
        lifeSpan: 620; lifeSpanVariation: 160
        size: 26; endSize: 84; sizeVariation: 12
        velocity: AngleDirection { angle: fire.impactAngle; angleVariation: 55; magnitude: 44; magnitudeVariation: 22 }
    }
    Emitter {
        id: impactCore
        system: blaze; group: "ballcore"; width: 2; height: 2; enabled: false
        lifeSpan: 260; lifeSpanVariation: 60
        size: 18; endSize: 46; sizeVariation: 6
        velocity: AngleDirection { angle: fire.impactAngle; angleVariation: 30; magnitude: 12; magnitudeVariation: 6 }
    }
    Emitter {
        id: impactSmoke
        system: blaze; group: "puff"; width: 2; height: 2; enabled: false
        lifeSpan: 1700; lifeSpanVariation: 400
        size: 34; endSize: 110; sizeVariation: 12
        velocity: AngleDirection { angle: fire.impactAngle; angleVariation: 40; magnitude: 26; magnitudeVariation: 10 }
        acceleration: PointDirection { y: -12; xVariation: 6 }
    }
    Emitter {
        id: impactDebris
        system: blaze; group: "debris"; width: 2; height: 2; enabled: false
        lifeSpan: 650; lifeSpanVariation: 200
        size: 4; endSize: 1; sizeVariation: 2
        velocity: AngleDirection { angle: fire.impactAngle; angleVariation: 65; magnitude: 130; magnitudeVariation: 60 }
    }
    Emitter {
        id: impactChip
        system: blaze; group: "chip"; width: 2; height: 2; enabled: false
        // they keep tumbling outward until they leave the screen, rather than vanishing
        lifeSpan: 9000; lifeSpanVariation: 1500
        size: 10; endSize: 10; sizeVariation: 4
        velocity: AngleDirection { angle: fire.impactAngle; angleVariation: 45; magnitude: 110; magnitudeVariation: 40 }
    }
}

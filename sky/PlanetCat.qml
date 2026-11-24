// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: a cat rising from behind a burning planet, firing lasers from
// its paws that chip the planet, and the planet blowing up on login.
//
// The cat's picture, paws and beams come from Cats.js; the parts are
// ChippedPlanet (the planet and its bites), Beam (each laser), Impact (the
// little flash where a laser hits), PlanetFire (fire, smoke, debris) and
// Explosion. Everything is laid out in a 460 x 520 box; Sky.qml places and
// scales it.
pragma ComponentBehavior: Bound
import QtQuick
import "../style"
import "Rng.js" as Rng

Item {
    id: planetCat
    required property bool running      // shown
    required property bool active       // moving: lasers, fire, impacts (off while held still)
    required property real clock        // seconds since the sky started
    required property real boom         // 0 -> 1 when the right password goes in: the planet
                                        // blows apart and the cat is blasted away
    required property var cat           // its picture, paws and beams (Cats.js)
    property url planet: "../assets/planet-jade.png"   // or planet-earth.png
    property real homeX: 0              // where it floats around
    property real homeY: 0
    property real rhythm: 0             // gives each copy its own floating rhythm

    // tuning
    readonly property int fireballMinMs: 240        // a fireball every 0.24-0.76 s
    readonly property int fireballSpreadMs: 520
    readonly property real biteChance: 0.35         // about one hit in three chips the planet
    readonly property real amberChance: 0.6         // fireballs: amber, else mint
    readonly property list<color> colours: [Theme.jade, Theme.mint, Theme.amber]   // beams cycle through these

    // the planet: centre and radius in the box (the pictures' disc is 210 px)
    readonly property point centre: Qt.point(220, 330)
    readonly property real radius: 105

    readonly property real e: Math.sqrt(Math.max(0, Math.min(1, boom)))   // the blast, fast start
    visible: running
    width: 460; height: 520
    x: homeX + 22 * Math.sin(clock * 0.27 + rhythm)
    y: homeY + 16 * Math.sin(clock * 0.41 + 1.0 + rhythm * 1.7)
    rotation: 3 * Math.sin(clock * 0.19 + 0.5 + rhythm * 0.6)

    // its paws in the box, following them frame by frame if it's animated,
    // so the beams start from them as they move
    readonly property var paws: {
        const f = cat.paws[cat.animated ? catPic.currentFrame : 0] || cat.paws[0]
        return [Qt.point(cat.x + cat.scale * f[0][0], cat.y + cat.scale * f[0][1]),
                Qt.point(cat.x + cat.scale * f[1][0], cat.y + cat.scale * f[1][1])]
    }
    property int phase: 0               // beam colours step round every 0.9 s
    Timer { interval: 900; repeat: true; running: planetCat.active; onTriggered: planetCat.phase = (planetCat.phase + 1) % 3 }

    // no beams until the cat has loaded (or if its picture is missing)
    readonly property bool hasCat: cat.animated ? catPic.status === AnimatedImage.Ready : stillPic.status === Image.Ready

    // the cat, behind the planet: its face above it, its faded lower half
    // behind it; blasted up and away, tumbling, when the planet explodes.
    // A still picture or an animation, whichever Cats.js gives.
    Image {
        id: stillPic
        visible: !planetCat.cat.animated
        asynchronous: true
        source: planetCat.cat.animated ? "" : "../assets/" + planetCat.cat.file
        x: planetCat.cat.x; y: planetCat.cat.y - planetCat.e * 260
        width: sourceSize.width * planetCat.cat.scale; height: sourceSize.height * planetCat.cat.scale
        smooth: true
        rotation: -planetCat.e * 35
        opacity: 1 - planetCat.e * planetCat.e
    }
    AnimatedImage {
        id: catPic
        visible: planetCat.cat.animated
        asynchronous: true
        playing: planetCat.active
        source: planetCat.cat.animated ? "../assets/" + planetCat.cat.file : ""
        x: planetCat.cat.x; y: planetCat.cat.y - planetCat.e * 260
        width: sourceSize.width * planetCat.cat.scale; height: sourceSize.height * planetCat.cat.scale
        smooth: true
        rotation: -planetCat.e * 35
        opacity: 1 - planetCat.e * planetCat.e
    }

    ChippedPlanet {
        id: chipped
        source: planetCat.planet
        centre: planetCat.centre
        e: planetCat.e
    }
    Explosion {
        centre: planetCat.centre
        radius: planetCat.radius
        boom: planetCat.boom
        e: planetCat.e
    }

    Repeater {
        id: lasers
        model: planetCat.hasCat ? planetCat.cat.beams : []
        Beam {
            required property var modelData
            required property int index
            from: planetCat.paws[modelData.paw]
            centre: planetCat.centre
            radius: planetCat.radius
            angle: modelData.a
            sweep: modelData.sweep
            speed: modelData.speed
            phase: index
            clock: planetCat.clock
            colour: planetCat.colours[(index + planetCat.phase) % 3]
            spreadBase: planetCat.cat.beamSpread.base
            spreadGrowth: planetCat.cat.beamSpread.growth
            active: planetCat.active
            fade: planetCat.e
        }
    }
    Repeater {
        id: impacts
        model: 8
        Impact {}
    }
    PlanetFire {
        id: fire
        active: planetCat.active
        burning: planetCat.boom <= 0
        centre: planetCat.centre
        radius: planetCat.radius
        beams: lasers
    }

    onBoomChanged: {
        if (boom === 0) { blasted = false; chipped.heal() }
        else if (!blasted) { blasted = true; fire.blast() }
    }
    property bool blasted: false
    onRunningChanged: if (running) chipped.heal()

    // a hit where one of the beams is landing: a fireball there, an impact,
    // and sometimes (`bite`: always) a piece chipped off
    property int nextImpact: 0
    function hitBeam(colour, bite) {
        const b = lasers.itemAt(Math.floor(Rng.next() * lasers.count)) as Beam
        if (!b) return
        const outward = Math.atan2(b.to.y - centre.y, b.to.x - centre.x)
        const flash = impacts.itemAt(nextImpact) as Impact
        flash.go(b.to.x, b.to.y, colour, outward)
        nextImpact = (nextImpact + 1) % impacts.count
        fire.impact(b.to.x, b.to.y, outward)
        if (bite || Rng.next() < biteChance) {
            chipped.addBite(b.to.x, b.to.y, outward)
            fire.chips(bite ? 4 : 2 + Math.floor(Rng.next() * 2), b.to.x, b.to.y)
        }
    }
    // typing the password: every 2nd key (Sky.keyPressed) chips a piece off
    function keyChip() {
        if (active && boom <= 0) hitBeam(Theme.amber, true)
    }
    // and on its own, a fireball now and then
    Timer {
        interval: 160; repeat: true; running: planetCat.active && planetCat.boom <= 0
        onTriggered: {
            interval = planetCat.fireballMinMs + Rng.next() * planetCat.fireballSpreadMs
            planetCat.hitBeam(Rng.next() < planetCat.amberChance ? Theme.amber : Theme.mint, false)
        }
    }
}

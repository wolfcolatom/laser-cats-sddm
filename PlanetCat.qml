// Laser Cats: a cat rising from behind a burning planet, firing lasers
// from its paws that chip the planet, and the planet blowing up on login.
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import QtQuick.Particles
import "Palette.js" as Palette

// The cat (its picture, paws and beams come from Cats.js) rises from behind
// the planet; two beams from each paw sweep across the planet's surface,
// with tiny explosions where they hit. Beam colours rotate jade -> mint ->
// amber. The group floats gently in place.
Item {
    id: planetCat
    property var sky                    // the Sky it belongs to (sizes, state)
    property var cat                    // its picture and paw/beam data (Cats.js)
    visible: live
    width: 460; height: 520
    property real t: 0                  // seconds it has been floating
    FrameAnimation { running: planetCat.live; onTriggered: planetCat.t += frameTime }
    // floats gently around its spot (set by each copy: homeX, homeY) like
    // the centre cats; `seed` gives each copy its own rhythm
    property bool live: true
    property real homeX: 0
    property real homeY: 0
    property real seed: 0
    property string planet: "assets/planet-jade.png"   // or planet-earth.png
    // 0 -> 1 when the right password goes in (set by each copy from the
    // warp): the planet blows apart and the cat is blasted away
    property real boom: 0
    readonly property real e: Math.sqrt(Math.max(0, Math.min(1, boom)))   // fast start
    x: homeX + 22 * Math.sin(planetCat.t * 0.27 + seed)
    y: homeY + 16 * Math.sin(planetCat.t * 0.41 + 1.0 + seed * 1.7)
    rotation: 3 * Math.sin(planetCat.t * 0.19 + 0.5 + seed * 0.6)
    readonly property real cx: 220      // planet centre and radius (planet-jade.png: 210 px disc)
    readonly property real cy: 330
    readonly property real pr: 105
    // its paws in this box, following them frame by frame if it's animated,
    // so the beams start from them as they move
    readonly property var paws: {
        let f = cat.paws[cat.animated ? catPic.currentFrame : 0] || cat.paws[0]
        return [Qt.point(cat.x + cat.scale * f[0][0], cat.y + cat.scale * f[0][1]),
                Qt.point(cat.x + cat.scale * f[1][0], cat.y + cat.scale * f[1][1])]
    }
    readonly property var colours: [Palette.jade, Palette.mint, Palette.amber]
    property int phase: 0
    Timer { interval: 900; repeat: true; running: planetCat.live; onTriggered: planetCat.phase = (planetCat.phase + 1) % 3 }

    // no beams until the cat has loaded (or if its picture is missing)
    readonly property bool hasCat: cat.animated ? catPic.status === AnimatedImage.Ready : stillPic.status === Image.Ready
    // the cat, behind the planet: its face above it, its faded lower half
    // behind it. A still picture or an animation, whichever Cats.js gives.
    Image {
        id: stillPic
        visible: !planetCat.cat.animated
        asynchronous: true          // load in the background: the lock shows at once
        source: planetCat.cat.animated ? "" : "assets/" + planetCat.cat.file
        x: planetCat.cat.x; y: planetCat.cat.y - planetCat.e * 260      // blasted up and away...
        width: sourceSize.width * planetCat.cat.scale; height: sourceSize.height * planetCat.cat.scale
        smooth: true
        rotation: -planetCat.e * 35                      // ...tumbling
        opacity: 1 - planetCat.e * planetCat.e
    }
    AnimatedImage {
        id: catPic
        visible: planetCat.cat.animated
        asynchronous: true
        source: planetCat.cat.animated ? "assets/" + planetCat.cat.file : ""
        x: planetCat.cat.x; y: planetCat.cat.y - planetCat.e * 260
        width: sourceSize.width * planetCat.cat.scale; height: sourceSize.height * planetCat.cat.scale
        smooth: true
        rotation: -planetCat.e * 35
        opacity: 1 - planetCat.e * planetCat.e
    }
    // the planet, hiding the cat's lower half. Drawn on a canvas so the
    // lasers can chip it away: each bite is cut out of the planet with a
    // charred, glowing edge around it (bites: addBite(), from the impacts)
    Canvas {
        id: planetCanvas
        width: 357; height: 357                 // planet-*.png
        x: planetCat.cx - width / 2; y: planetCat.cy - height / 2
        opacity: 1 - Math.min(1, planetCat.e * 2.2)      // gone as it shatters
        scale: 1 + planetCat.e * 0.25
        readonly property url src: Qt.resolvedUrl(planetCat.planet)
        Component.onCompleted: loadImage(src)
        onImageLoaded: requestPaint()
        onPaint: {
            let c = getContext("2d")
            c.reset()
            if (!isImageLoaded(src)) return
            c.globalCompositeOperation = "source-over"
            c.drawImage(src, 0, 0, width, height)
            let bites = planetCat.bites
            // char and a hot glowing edge around each bite, only on the planet itself
            c.globalCompositeOperation = "source-atop"
            for (let i = 0; i < bites.length; i++) {
                let b = bites[i], R = b.r * 2.3
                let g = c.createRadialGradient(b.x, b.y, 0, b.x, b.y, R)
                g.addColorStop(0.0, "rgba(255, 170, 60, 1)")
                g.addColorStop(0.42, "rgba(255, 110, 25, 0.95)")     // glowing rim of the bite
                g.addColorStop(0.55, "rgba(70, 28, 10, 0.85)")      // charred ring
                g.addColorStop(1.0, "rgba(30, 15, 8, 0)")
                c.fillStyle = g
                c.beginPath(); c.arc(b.x, b.y, R, 0, 2 * Math.PI); c.fill()
            }
            // then cut the bites out: jagged chunks, so it looks chipped
            c.globalCompositeOperation = "destination-out"
            c.fillStyle = "#000"
            for (let j = 0; j < bites.length; j++) {
                let d = bites[j], n = d.k.length
                c.beginPath()
                for (let v = 0; v < n; v++) {
                    let a = v / n * 2 * Math.PI + d.rot, rr = d.r * d.k[v]
                    if (v === 0) c.moveTo(d.x + Math.cos(a) * rr, d.y + Math.sin(a) * rr)
                    else c.lineTo(d.x + Math.cos(a) * rr, d.y + Math.sin(a) * rr)
                }
                c.closePath(); c.fill()
            }
        }
    }
    // bites chipped out so far (planet-canvas coordinates), at most maxBites
    // Once there are maxBites, each new bite makes the oldest one heal:
    // it shrinks away over about 2 s (healTimer), so on a long lock the
    // damage keeps moving instead of freezing.
    property var bites: []
    readonly property int maxBites: 90
    function addBite(px, py, outwardRad) {
        let open = 0
        for (let b = 0; b < bites.length; b++) if (!bites[b].healing) open++
        if (open >= maxBites) {
            for (let o = 0; o < bites.length; o++)
                if (!bites[o].healing) { bites[o].healing = true; bites[o].r0 = bites[o].r; break }
            healTimer.start()
        }
        let depth = 2 + Math.random() * 8 + Math.min(1, bites.length / maxBites) * 12   // later bites dig deeper
        let bx = px - Math.cos(outwardRad) * depth - planetCanvas.x
        let by = py - Math.sin(outwardRad) * depth - planetCanvas.y
        let k = []
        let n = 7 + Math.floor(Math.random() * 3)
        for (let i = 0; i < n; i++) k.push(0.7 + Math.random() * 0.5)
        let list = bites.slice()
        list.push({ x: bx, y: by, r: 6 + Math.random() * 7, k: k, rot: Math.random() * 6.28 })
        bites = list
        planetCanvas.requestPaint()
        return true
    }
    function healPlanet() { healTimer.stop(); bites = []; planetCanvas.requestPaint() }
    Timer {
        id: healTimer
        interval: 100; repeat: true
        onTriggered: {
            let list = [], any = false
            for (let i = 0; i < planetCat.bites.length; i++) {
                let b = planetCat.bites[i]
                if (b.healing) { b.r -= b.r0 / 20; if (b.r <= 0.5) continue; any = true }
                list.push(b)
            }
            planetCat.bites = list
            planetCanvas.requestPaint()
            if (!any) stop()
        }
    }
    onLiveChanged: if (live) healPlanet()
    // the explosion: a quick blinding flash, a fireball of flame with smoke
    // and embers, the planet in a dozen glowing pieces, bright streaks
    Rectangle {
        visible: planetCat.boom > 0 && opacity > 0
        width: planetCat.pr * 2 * (0.8 + planetCat.e * 1.2); height: width; radius: width / 2
        x: planetCat.cx - width / 2; y: planetCat.cy - height / 2
        color: Palette.flare
        opacity: Math.max(0, 0.95 - planetCat.e * 2.8)
        layer.enabled: visible
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 48 }
    }
    // a spray of bright streaks flung out from the planet
    Repeater {
        model: planetCat.boom > 0 ? 36 : 0
        Rectangle {
            required property int index
            readonly property real a: index / 36 * 2 * Math.PI + Math.sin(index * 5.7) * 0.15
            readonly property real d: planetCat.pr * (0.6 + planetCat.e * (2.2 + Math.abs(Math.sin(index * 2.3)) * 2.4))
            width: 18 + 40 * planetCat.e * (1 - planetCat.e) * 4; height: 2.5; radius: 1.25
            x: planetCat.cx + Math.cos(a) * d - width / 2; y: planetCat.cy + Math.sin(a) * d - 1
            rotation: a * 180 / Math.PI
            color: index % 3 === 0 ? Palette.white : index % 3 === 1 ? Palette.amber : Palette.flare
            opacity: Math.max(0, 1 - planetCat.e * 1.1)
        }
    }
    Repeater {
        model: planetCat.boom > 0 ? 14 : 0
        Image {
            required property int index
            asynchronous: true          // load in the background: the lock shows at once
            readonly property real a: index / 14 * 2 * Math.PI + Math.sin(index * 7.3) * 0.25
            readonly property real reach: 260 + 220 * Math.abs(Math.sin(index * 3.1))
            source: "assets/rock-" + (index % 4 + 1) + ".png"
            smooth: true
            scale: 2.2 - (index % 4) * 0.35
            x: planetCat.cx + Math.cos(a) * planetCat.e * reach - width / 2
            y: planetCat.cy + Math.sin(a) * planetCat.e * reach - height / 2
            rotation: planetCat.e * (index % 2 ? 1 : -1) * (200 + index * 25)
            opacity: Math.max(0, 1 - planetCat.e * planetCat.e)
        }
    }
    onBoomChanged: if (boom === 0) { blasted = false; healPlanet() } else if (!blasted) { blasted = true; blastFire.burst(320); blastSmoke.burst(28); blastEmbers.burst(90) }
    property bool blasted: false

    // the beams (paw, where they land, sweep, speed: see Cats.js)
    Repeater {
        id: beams
        model: planetCat.hasCat ? planetCat.cat.beams : []
        Item {
            required property var modelData
            required property int index
            id: beam
            readonly property point from: planetCat.paws[modelData.paw]
            property real s: 0
            NumberAnimation on s { from: 0; to: 2 * Math.PI; duration: 6000 / beam.modelData.speed; loops: Animation.Infinite; running: planetCat.live }
            readonly property real ang: (modelData.a + modelData.sweep * Math.sin(s + index)) * Math.PI / 180
            readonly property point to: Qt.point(planetCat.cx + planetCat.pr * Math.cos(ang), planetCat.cy + planetCat.pr * Math.sin(ang))
            readonly property real len: Math.sqrt(Math.pow(to.x - from.x, 2) + Math.pow(to.y - from.y, 2))
            readonly property color col: planetCat.colours[(index + planetCat.phase) % 3]
            readonly property real spread: planetCat.cat.beamSpread.base + len * planetCat.cat.beamSpread.growth   // half-width at the far end
            property real shimmer: 1
            Timer { interval: 70; repeat: true; running: planetCat.live; onTriggered: beam.shimmer = 0.8 + Math.random() * 0.2 }
            // laid along x from the paw; the item is as tall as the widest end, so
            // the soft-edge blur has room
            width: len; height: spread * 2 + 12
            x: from.x; y: from.y - height / 2
            transformOrigin: Item.Left
            rotation: Math.atan2(to.y - from.y, to.x - from.x) * 180 / Math.PI
            opacity: shimmer * (1 - Math.min(1, planetCat.e * 4))
            layer.enabled: true
            layer.effect: MultiEffect { blurEnabled: true; blur: 0.35; blurMax: 10 }
            Shape {                         // a widening, see-through beam, like the other cats'
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: "transparent"
                    fillGradient: LinearGradient {
                        x1: 0; y1: 0; x2: beam.len; y2: 0
                        GradientStop { position: 0.0; color: Qt.rgba(0.95, 0.96, 0.95, 0.95) }
                        GradientStop { position: 0.18; color: Qt.rgba(beam.col.r, beam.col.g, beam.col.b, 0.8) }
                        GradientStop { position: 0.75; color: Qt.rgba(beam.col.r, beam.col.g, beam.col.b, 0.5) }
                        GradientStop { position: 1.0; color: Qt.rgba(beam.col.r, beam.col.g, beam.col.b, 0.0) }   // fades into the surface
                    }
                    startX: 0; startY: beam.height / 2 - 2
                    PathLine { x: beam.len; y: beam.height / 2 - beam.spread }
                    PathLine { x: beam.len; y: beam.height / 2 + beam.spread }
                    PathLine { x: 0; y: beam.height / 2 + 2 }
                    PathLine { x: 0; y: beam.height / 2 - 2 }
                }
            }
            Rectangle {                     // bright core
                x: 0; y: beam.height / 2 - 1; width: beam.len; height: 2; radius: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Palette.white }
                    GradientStop { position: 0.6; color: Qt.rgba(1, 1, 1, 0.35) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
        }
    }

    // tiny explosions where the beams hit the planet: a soft flash and a
    // spray of sparks flying off the surface (away from the planet), with
    // a few dim embers drifting a little further
    Repeater {
        id: booms
        model: 8
        Item {
            id: boom
            width: 0; height: 0
            visible: p < 1
            property real p: 1                      // 0 -> 1 over the burst
            property color col: Palette.amber
            property real out: 0                    // direction off the surface (rad)
            property var dirs: []
            property var reach: []
            Rectangle {                             // the flash
                x: -width / 2; y: -height / 2
                width: 26 * (0.4 + boom.p); height: width; radius: width / 2
                color: boom.col
                opacity: Math.max(0, 0.7 * (1 - boom.p * 2.2))
                layer.enabled: true
                layer.effect: MultiEffect { blurEnabled: true; blur: 0.8; blurMax: 12 }
            }
            Rectangle {                             // its white-hot centre
                x: -4; y: -4; width: 8; height: 8; radius: 4
                color: Palette.white
                opacity: Math.max(0, 1 - boom.p * 3)
            }
            Repeater {                              // sparks
                model: boom.dirs.length
                Rectangle {
                    required property int index
                    readonly property real a: boom.dirs[index] || 0
                    readonly property real d: (boom.reach[index] || 20) * (1 - Math.pow(1 - boom.p, 2.2))
                    width: 2 + 7 * (1 - boom.p); height: 2; radius: 1
                    x: Math.cos(a) * d - width / 2; y: Math.sin(a) * d - 1
                    rotation: a * 180 / Math.PI
                    color: index % 3 === 0 ? Palette.white : boom.col
                    opacity: Math.max(0, 1 - boom.p * 1.15)
                }
            }
            Repeater {                              // embers
                model: 3
                Rectangle {
                    required property int index
                    readonly property real a: boom.out + (index - 1) * 0.7
                    readonly property real d: 34 * boom.p
                    width: 2; height: 2; radius: 1
                    x: Math.cos(a) * d - 1; y: Math.sin(a) * d - 1 + 6 * boom.p * boom.p
                    color: boom.col
                    opacity: Math.max(0, 0.6 * (1 - boom.p))
                }
            }
            function go(px, py, c, outward) {
                x = px; y = py; col = c; out = outward
                let n = 8 + Math.floor(Math.random() * 3), ds = [], rs = []
                for (let k = 0; k < n; k++) {
                    ds.push(outward + (Math.random() - 0.5) * 2.4)      // a fan of about +/-70 degrees
                    rs.push(12 + Math.random() * 20)
                }
                dirs = ds; reach = rs
                pop.restart()
            }
            NumberAnimation { id: pop; target: boom; property: "p"; from: 0; to: 1; duration: 520; easing.type: Easing.Linear }
        }
    }
    // the planet is burning: fire and embers where each laser lands, smaller
    // fires along the rim, a big fire and smoke in the blasted crater, and
    // rock fragments breaking off it and tumbling away
    readonly property point crater: Qt.point(cx + 0.93 * pr * Math.cos(-50 * Math.PI / 180),
                                             cy + 0.93 * pr * Math.sin(-50 * Math.PI / 180))
    ParticleSystem { id: blaze; anchors.fill: parent; running: planetCat.live }
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
        model: beams.count
        Emitter {
            id: hitFire
            required property int index
            readonly property var b: beams.itemAt(index)
            readonly property real outward: b ? Math.atan2(b.to.y - planetCat.cy, b.to.x - planetCat.cx) * 180 / Math.PI : -90
            enabled: planetCat.boom <= 0        // the fires go out when it blows up
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
        model: beams.count
        Emitter {
            id: hitFlame
            required property int index
            readonly property var b: beams.itemAt(index)
            readonly property real outward: b ? Math.atan2(b.to.y - planetCat.cy, b.to.x - planetCat.cx) * 180 / Math.PI : -90
            enabled: planetCat.boom <= 0        // the fires go out when it blows up
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
            enabled: planetCat.boom <= 0        // the fires go out when it blows up
            system: blaze; group: "fire"
            x: planetCat.cx + planetCat.pr * 0.97 * Math.cos(a) - 5; y: planetCat.cy + planetCat.pr * 0.97 * Math.sin(a) - 5
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
        x: planetCat.cx - planetCat.pr; y: planetCat.cy - planetCat.pr
        width: planetCat.pr * 2; height: planetCat.pr * 2
        shape: EllipseShape { fill: true }
        enabled: false
        lifeSpan: 550; lifeSpanVariation: 150         // a quick fireball that's gone fast
        size: 44; endSize: 10; sizeVariation: 18
        velocity: TargetDirection { targetX: planetCat.pr; targetY: planetCat.pr; proportionalMagnitude: true; magnitude: -2.6; magnitudeVariation: 1.6 }
    }
    Emitter {
        id: blastSmoke
        system: blaze; group: "smoke"
        x: planetCat.cx - planetCat.pr * 0.8; y: planetCat.cy - planetCat.pr * 0.8
        width: planetCat.pr * 1.6; height: planetCat.pr * 1.6
        shape: EllipseShape { fill: true }
        enabled: false
        lifeSpan: 2200; lifeSpanVariation: 600
        size: 70; endSize: 170; sizeVariation: 30
        velocity: TargetDirection { targetX: planetCat.pr * 0.8; targetY: planetCat.pr * 0.8; proportionalMagnitude: true; magnitude: -0.9; magnitudeVariation: 0.5 }
    }
    Emitter {
        id: blastEmbers
        system: blaze; group: "ember"
        x: planetCat.cx - planetCat.pr * 0.5; y: planetCat.cy - planetCat.pr * 0.5
        width: planetCat.pr; height: planetCat.pr
        enabled: false
        lifeSpan: 800; lifeSpanVariation: 250
        size: 5; endSize: 1; sizeVariation: 2
        velocity: AngleDirection { angle: 0; angleVariation: 180; magnitude: 260; magnitudeVariation: 140 }
    }

    // explosive impacts: where a beam hits, a fireball blooms with a white-hot
    // middle, rolls out into smoke and throws hot debris off the surface.
    // Fired by the timer below with burst(); impactAngle is the direction
    // off the surface for that hit.
    property real impactAngle: -90
    Emitter {
        id: impactBall
        system: blaze; group: "ball"; width: 2; height: 2; enabled: false
        lifeSpan: 620; lifeSpanVariation: 160
        size: 26; endSize: 84; sizeVariation: 12
        velocity: AngleDirection { angle: planetCat.impactAngle; angleVariation: 55; magnitude: 44; magnitudeVariation: 22 }
    }
    Emitter {
        id: impactCore
        system: blaze; group: "ballcore"; width: 2; height: 2; enabled: false
        lifeSpan: 260; lifeSpanVariation: 60
        size: 18; endSize: 46; sizeVariation: 6
        velocity: AngleDirection { angle: planetCat.impactAngle; angleVariation: 30; magnitude: 12; magnitudeVariation: 6 }
    }
    Emitter {
        id: impactSmoke
        system: blaze; group: "puff"; width: 2; height: 2; enabled: false
        lifeSpan: 1700; lifeSpanVariation: 400
        size: 34; endSize: 110; sizeVariation: 12
        velocity: AngleDirection { angle: planetCat.impactAngle; angleVariation: 40; magnitude: 26; magnitudeVariation: 10 }
        acceleration: PointDirection { y: -12; xVariation: 6 }
    }
    Emitter {
        id: impactDebris
        system: blaze; group: "debris"; width: 2; height: 2; enabled: false
        lifeSpan: 650; lifeSpanVariation: 200
        size: 4; endSize: 1; sizeVariation: 2
        velocity: AngleDirection { angle: planetCat.impactAngle; angleVariation: 65; magnitude: 130; magnitudeVariation: 60 }
    }
    Emitter {
        id: impactChip
        system: blaze; group: "chip"; width: 2; height: 2; enabled: false
        // they keep tumbling outward until they leave the screen, rather than vanishing
        lifeSpan: 9000; lifeSpanVariation: 1500
        size: 10; endSize: 10; sizeVariation: 4
        velocity: AngleDirection { angle: planetCat.impactAngle; angleVariation: 45; magnitude: 110; magnitudeVariation: 40 }
    }
    function impact(px, py, outwardRad, bite) {
        impactAngle = outwardRad * 180 / Math.PI
        impactBall.burst(18, px, py)
        impactCore.burst(6, px, py)
        impactSmoke.burst(4, px, py)
        impactDebris.burst(12, px, py)
        // about one hit in three takes a chunk out of the planet
        if ((bite || Math.random() < 0.35) && addBite(px, py, outwardRad)) impactChip.burst(bite ? 4 : 2 + Math.floor(Math.random() * 2), px, py)
    }
    // a hit where one of the beams is landing: a fireball there and an
    // impact; `bite` always chips a piece off. (The beams and booms come out
    // of Repeaters, which the type checker only knows as plain Items, so it
    // can't see their own `to` and `go`.)
    property int nextBoom: 0
    function hitBeam(colour, bite) {
        // qmllint disable missing-property
        const b = beams.itemAt(Math.floor(Math.random() * beams.count))
        if (!b) return
        const outward = Math.atan2(b.to.y - cy, b.to.x - cx)
        booms.itemAt(nextBoom).go(b.to.x, b.to.y, colour, outward)
        nextBoom = (nextBoom + 1) % booms.count
        impact(b.to.x, b.to.y, outward, bite)
        // qmllint enable missing-property
    }
    // typing the password: every 2nd key (sky.keyPressed) chips a piece off
    function keyChip() {
        if (live && boom <= 0) hitBeam(Palette.amber, true)
    }
    // and on its own, a fireball every 0.24-0.76 s
    Timer {
        interval: 160; repeat: true; running: planetCat.live && planetCat.boom <= 0
        onTriggered: {
            interval = 240 + Math.random() * 520
            planetCat.hitBeam(Math.random() < 0.6 ? Palette.amber : Palette.mint, false)
        }
    }
}

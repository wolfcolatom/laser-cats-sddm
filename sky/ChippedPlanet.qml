// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: a planet the lasers chip away. Drawn on a canvas: each bite
// is cut out of the planet with a charred, glowing edge around it. Once
// there are maxBites, each new bite makes the oldest heal (it shrinks away
// over about 2 s), so on a long lock the damage keeps moving instead of
// freezing.
pragma ComponentBehavior: Bound
import QtQuick

Canvas {
    id: planet
    required property url source        // planet-*.png
    required property point centre      // where its middle goes (in the parent)
    required property real e            // 0-1: the explosion (it fades and swells)
    required property Rng rng
    readonly property int maxBites: 90

    width: 357; height: 357             // the planet pictures' size
    x: centre.x - width / 2; y: centre.y - height / 2
    opacity: 1 - Math.min(1, e * 2.2)   // gone as it shatters
    scale: 1 + e * 0.25

    property var bites: []              // in the canvas' own coordinates

    // a bite where a laser hits at (px, py) in the parent, `outward` (radians)
    // pointing off the surface; later bites dig deeper
    function addBite(px: real, py: real, outward: real) {
        let open = 0
        for (let b = 0; b < bites.length; b++) if (!bites[b].healing) open++
        if (open >= maxBites) {
            for (let o = 0; o < bites.length; o++)
                if (!bites[o].healing) { bites[o].healing = true; bites[o].r0 = bites[o].r; break }
            healTimer.start()
        }
        const depth = 2 + rng.next() * 8 + Math.min(1, bites.length / maxBites) * 12
        const k = []
        const n = 7 + Math.floor(rng.next() * 3)
        for (let i = 0; i < n; i++) k.push(0.7 + rng.next() * 0.5)
        const list = bites.slice()
        list.push({ x: px - Math.cos(outward) * depth - x, y: py - Math.sin(outward) * depth - y,
                    r: 6 + rng.next() * 7, k: k, rot: rng.next() * 6.28 })
        bites = list
        requestPaint()
    }
    // whole again (after the explosion rewinds, or when shown again)
    function heal() { healTimer.stop(); bites = []; requestPaint() }

    Timer {
        id: healTimer
        interval: 100; repeat: true
        onTriggered: {
            let list = [], any = false
            for (let i = 0; i < planet.bites.length; i++) {
                const b = planet.bites[i]
                if (b.healing) { b.r -= b.r0 / 20; if (b.r <= 0.5) continue; any = true }
                list.push(b)
            }
            planet.bites = list
            planet.requestPaint()
            if (!any) stop()
        }
    }

    Component.onCompleted: loadImage(source)
    onImageLoaded: requestPaint()
    onPaint: {
        const c = getContext("2d")
        c.reset()
        if (!isImageLoaded(source)) return
        c.globalCompositeOperation = "source-over"
        c.drawImage(source, 0, 0, width, height)
        // char and a hot glowing edge around each bite, only on the planet itself
        c.globalCompositeOperation = "source-atop"
        for (const b of bites) {
            const R = b.r * 2.3
            const g = c.createRadialGradient(b.x, b.y, 0, b.x, b.y, R)
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
        for (const d of bites) {
            const n = d.k.length
            c.beginPath()
            for (let v = 0; v < n; v++) {
                const a = v / n * 2 * Math.PI + d.rot, rr = d.r * d.k[v]
                if (v === 0) c.moveTo(d.x + Math.cos(a) * rr, d.y + Math.sin(a) * rr)
                else c.lineTo(d.x + Math.cos(a) * rr, d.y + Math.sin(a) * rr)
            }
            c.closePath(); c.fill()
        }
    }
}

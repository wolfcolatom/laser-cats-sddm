// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: a cat-head constellation drifting across the sky.
pragma ComponentBehavior: Bound
import QtQuick
import "Palette.js" as Palette

// a cat constellation: a few stars joined by faint jade lines in the
// shape of a cat's head (ears, cheeks, chin, eyes, nose), drifting slowly
Canvas {
    id: constellation
    property var sky                    // the Sky it belongs to (sizes, state)
    visible: sky.running
    width: 220; height: 200
    transform: Scale { xScale: constellation.sky.catScale; yScale: constellation.sky.catScale }
    property real t: 0                  // seconds it has been moving
    FrameAnimation { running: constellation.sky.running; onTriggered: constellation.t += frameTime }
    x: (0.10 * (sky.width + width) + constellation.t * 5) % (sky.width + width) - width
    y: sky.height * 0.52
    opacity: 0.85
    onPaint: {
        let c = getContext("2d")
        let head = [[40,95],[60,25],[95,62],[130,62],[165,25],[185,95],[170,150],[112,178],[55,150]]
        let face = [[85,105],[140,105],[112,130]]
        c.clearRect(0, 0, width, height)
        c.strokeStyle = "rgba(67, 175, 156, 0.38)"
        c.lineWidth = 1.2
        c.beginPath()
        c.moveTo(head[0][0], head[0][1])
        for (let i = 1; i < head.length; i++) c.lineTo(head[i][0], head[i][1])
        c.closePath()
        c.stroke()
        c.beginPath(); c.moveTo(85,105); c.lineTo(112,130); c.lineTo(140,105); c.stroke()
        let stars = head.concat(face)
        for (let j = 0; j < stars.length; j++) {
            let x = stars[j][0], y = stars[j][1], big = (j === 1 || j === 4 || j >= head.length) ? 2.2 : 1.6
            let g = c.createRadialGradient(x, y, 0, x, y, big * 4)
            g.addColorStop(0, "rgba(196, 236, 228, 0.55)"); g.addColorStop(1, "rgba(141, 210, 198, 0)")
            c.fillStyle = g; c.beginPath(); c.arc(x, y, big * 4, 0, 2 * Math.PI); c.fill()
            c.fillStyle = Palette.white; c.beginPath(); c.arc(x, y, big, 0, 2 * Math.PI); c.fill()
        }
    }
}

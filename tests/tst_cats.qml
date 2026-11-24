// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// The cat data in Cats.js: the theme's own cats load, and every paw and eye
// position lies inside its picture (in every frame), so the lasers line up.
import QtQuick
import QtTest
import "../sky/Cats.js" as Cats

Item {
    id: host
    width: 200; height: 200

    Component { id: animated; AnimatedImage { playing: false } }

    TestCase {
        name: "Cats"
        when: windowShown

        function picture(file) {
            const img = createTemporaryObject(animated, host, { source: "../assets/" + file })
            tryVerify(() => img.status === AnimatedImage.Ready || img.status === AnimatedImage.Error, 5000)
            compare(img.status, AnimatedImage.Ready, file + " loads")
            return img
        }

        function test_floatingCatsLoad() {
            verify(Cats.own.floaters.length > 0)
            for (const f of Cats.own.floaters) {
                picture(f.file)
                verify(f.s > 0 && f.y >= 0 && f.y <= 1 && f.start >= 0 && f.start <= 1, f.file + " lane")
            }
        }
        function test_planetCatPawsInsideThePicture() {
            const c = Cats.own.planetCat
            const img = picture(c.file)
            compare(c.paws.length, img.frameCount, "a paw pair for every frame")
            for (let i = 0; i < c.paws.length; i++)
                for (const p of c.paws[i])
                    verify(p[0] >= 0 && p[0] <= img.sourceSize.width && p[1] >= 0 && p[1] <= img.sourceSize.height,
                           "frame " + i + " paw " + p + " inside " + img.sourceSize)
        }
        function test_beamsAreSane() {
            for (const set of [Cats.own, Cats.classic])
                for (const b of set.planetCat.beams) {
                    verify(b.paw === 0 || b.paw === 1)
                    verify(b.a >= 0 && b.a < 360 && b.sweep > 0 && b.speed > 0)
                }
        }
        function test_warpCatEyes() {
            picture(Cats.own.warpCat.file)
            for (const set of [Cats.own, Cats.classic]) {
                compare(set.warpCat.eyes.length, 2)
                verify(set.warpCat.eyes[0].x < 0 && set.warpCat.eyes[1].x > 0, "left eye, then right")
                for (const e of set.warpCat.eyes) verify(Math.abs(e.x) < 0.5 && Math.abs(e.y) < 0.5)
            }
        }
        function test_classicSetHasTheSameShape() {
            compare(Object.keys(Cats.classic).sort().join(), Object.keys(Cats.own).sort().join())
            compare(Cats.classic.floaters.length, Cats.own.floaters.length)
        }
    }
}

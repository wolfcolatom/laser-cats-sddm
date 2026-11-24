// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// The cat data (sky/CatSets.qml): the theme's own cats load, and every paw
// and eye position lies inside its picture (in every frame), so the lasers
// line up; and the warp cat's lasers really start at its eyes.
pragma ComponentBehavior: Bound
import QtQuick
import QtTest
import "../sky"

Item {
    id: host
    width: 800; height: 600

    CatSets { id: sets }
    Component { id: animated; AnimatedImage { playing: false } }
    Component {
        id: warp
        Warp { anchors.fill: parent; warp: 0.7; blast: 1; catScale: 1; playing: false; seed: 1; cat: sets.own.warpCat }
    }

    TestCase {
        name: "Cats"
        when: windowShown

        function picture(file) {
            const img = createTemporaryObject(animated, host, { source: "../assets/" + file })
            tryVerify(() => img.status === AnimatedImage.Ready || img.status === AnimatedImage.Error, 5000)
            compare(img.status, AnimatedImage.Ready, file + " loads")
            return img
        }
        function inside(p, img) { return p.x >= 0 && p.x <= img.sourceSize.width && p.y >= 0 && p.y <= img.sourceSize.height }

        function test_floatingCatsLoad() {
            verify(sets.own.floaters.length > 0)
            for (const f of sets.own.floaters) {
                picture(f.file)
                verify(f.size > 0 && f.lane >= 0 && f.lane <= 1 && f.start >= 0 && f.start <= 1 && f.speed > 0, f.file)
            }
        }
        function test_planetCatPawsInsideThePicture() {
            const c = sets.own.planetCat
            const img = picture(c.file)
            compare(c.leftPaw.length, img.frameCount, "a left paw for every frame")
            compare(c.rightPaw.length, img.frameCount, "a right paw for every frame")
            for (let i = 0; i < img.frameCount; i++) {
                verify(inside(c.leftPaw[i], img), "frame " + i + " left paw " + c.leftPaw[i])
                verify(inside(c.rightPaw[i], img), "frame " + i + " right paw " + c.rightPaw[i])
                verify(c.leftPaw[i].x < c.rightPaw[i].x, "frame " + i + ": left paw is on the left")
            }
        }
        function test_beams_data() {
            return [{ tag: "own", set: sets.own }, { tag: "classic", set: sets.classic }]
        }
        function test_beams(d) {
            const c = d.set.planetCat
            verify(c.beams.length > 0)
            for (const b of c.beams) {
                verify(b.paw === 0 || b.paw === 1)
                verify(b.angle >= 0 && b.angle < 360 && b.sweep > 0 && b.speed > 0)
            }
            verify(c.leftPaw.length > 0 && c.rightPaw.length === c.leftPaw.length)
        }
        function test_warpCatEyes_data() { return test_beams_data() }
        function test_warpCatEyes(d) {
            const w = d.set.warpCat
            verify(w.size > 0)
            verify(w.leftEye.x < 0 && w.rightEye.x > 0, "left eye, then right")
            for (const e of [w.leftEye, w.rightEye]) verify(Math.abs(e.x) < 0.5 && Math.abs(e.y) < 0.5)
        }
        function test_warpLasersStartAtTheEyes() {
            const scene = createTemporaryObject(warp, host)
            const cat = findChild(scene, "warpCat")
            tryCompare(cat, "status", AnimatedImage.Ready, 5000)
            const size = cat.height * cat.scale, turn = cat.rotation * Math.PI / 180
            for (const [name, eye] of [["leftEyeLaser", sets.own.warpCat.leftEye], ["rightEyeLaser", sets.own.warpCat.rightEye]]) {
                const laser = findChild(scene, name)
                // the eye, from the picture's centre, turned and scaled as the cat is
                const dx = eye.x * size, dy = eye.y * size
                fuzzyCompare(laser.eye.x, host.width / 2 + dx * Math.cos(turn) - dy * Math.sin(turn), 0.5)
                fuzzyCompare(laser.eye.y, host.height / 2 + dx * Math.sin(turn) + dy * Math.cos(turn), 0.5)
                // and the eye is inside the cat's picture on screen
                const inPicture = cat.mapFromItem(scene, laser.eye.x, laser.eye.y)
                verify(inPicture.x > 0 && inPicture.x < cat.width && inPicture.y > 0 && inPicture.y < cat.height, name)
                verify(laser.len > 0, name + " is firing at warp 0.7")
            }
        }
        function test_bothSetsAreComplete() {
            compare(sets.classic.floaters.length, sets.own.floaters.length)
            for (const set of [sets.own, sets.classic]) {
                verify(set.planetCat.file !== "" && set.warpCat.file !== "")
                for (const f of set.floaters) verify(f.file !== "")
            }
        }
    }
}

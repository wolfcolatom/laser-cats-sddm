// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: a small seeded random number generator (mulberry32). Each
// part of the sky that needs chance owns one, seeded from the sky's seed,
// so the same seed always plays out the same way (the screenshot tests
// rely on it) and no part's numbers depend on another's.
import QtQml

QtObject {
    id: rng
    property int seed: 1
    onSeedChanged: reseed()
    Component.onCompleted: reseed()

    // The state lives in a plain object rather than a property, so a binding
    // that calls next() doesn't come to depend on it (and re-run forever).
    readonly property var box: ({ state: 1 })

    function reseed() { box.state = (seed >>> 0) || 1 }

    // a number from 0 (inclusive) to 1 (exclusive), like Math.random()
    function next(): real {
        box.state = (box.state + 0x6D2B79F5) >>> 0
        let t = box.state
        t = Math.imul(t ^ (t >>> 15), t | 1)
        t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296
    }
}

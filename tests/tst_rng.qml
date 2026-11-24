// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// The seeded random numbers (sky/Rng.qml) the sky uses.
import QtQuick
import QtTest
import "../sky"

TestCase {
    name: "Rng"

    Rng { id: a }
    Rng { id: b }

    function draw(rng, seed, n) {
        rng.seed = seed
        rng.reseed()
        const out = []
        for (let i = 0; i < n; i++) out.push(rng.next())
        return out
    }
    function test_sameSeedSameNumbers() { compare(draw(a, 42, 50), draw(b, 42, 50)) }
    function test_differentSeedsDiffer() { verify(draw(a, 1, 10).join() !== draw(b, 2, 10).join()) }
    function test_generatorsAreIndependent() {
        const alone = draw(a, 7, 20)
        a.seed = 7; a.reseed(); b.seed = 99; b.reseed()
        const mixed = []
        for (let i = 0; i < 20; i++) { mixed.push(a.next()); b.next() }
        compare(mixed, alone, "drawing from one doesn't disturb another")
    }
    function test_range() {
        for (const v of draw(a, 7, 10000)) verify(v >= 0 && v < 1)
    }
}

// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// The seeded random numbers (Rng.js) the sky uses.
import QtQuick
import QtTest
import "../sky/Rng.js" as Rng

TestCase {
    name: "Rng"

    function draw(seed, n) {
        Rng.seed(seed)
        const out = []
        for (let i = 0; i < n; i++) out.push(Rng.next())
        return out
    }
    function test_sameSeedSameNumbers() { compare(draw(42, 50), draw(42, 50)) }
    function test_differentSeedsDiffer() { verify(draw(1, 10).join() !== draw(2, 10).join()) }
    function test_range() {
        for (const v of draw(7, 10000)) verify(v >= 0 && v < 1)
    }
    function test_spread() {
        const v = draw(3, 10000)
        const mean = v.reduce((a, b) => a + b, 0) / v.length
        verify(Math.abs(mean - 0.5) < 0.02, "mean " + mean)
    }
}

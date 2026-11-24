.pragma library
// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// A small seeded random number generator (mulberry32) for everything random
// in the sky, so a given seed always plays out the same way (the screenshot
// tests rely on it). Sky.qml seeds it once at start.

let state = 1

function seed(n) {
    state = (n >>> 0) || 1
}

// a number from 0 (inclusive) to 1 (exclusive), like Math.random()
function next() {
    state = (state + 0x6D2B79F5) >>> 0
    let t = state
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
}

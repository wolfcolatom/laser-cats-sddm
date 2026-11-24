// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Text contrast, by the WCAG 2 formula: the login screen's text colours
// against the darkest backing they sit on. 4.5:1 is the bar for small
// text (AA); the clock and date are large text (3:1).
import QtQuick
import QtTest
import "../style"

TestCase {
    name: "Contrast"

    function channel(c) { return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4) }
    function luminance(c: color): real {
        return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b)
    }
    function ratio(fg, bg) {
        const a = luminance(fg), b = luminance(bg)
        return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05)
    }
    // [what, text colour, background, minimum]
    readonly property var pairs: [
        ["password text on the field", Theme.text, Theme.surface, 4.5],
        ["placeholder / names on the field", Theme.subtext, Theme.surface, 4.5],
        ["user name on the sky", Theme.subtext, Theme.backdrop, 4.5],
        ["Caps Lock warning", Theme.amber, Theme.backdrop, 4.5],
        ["SDDM message", Theme.text, Theme.backdrop, 4.5],
        ["session picker text", Theme.subtext, Theme.surfaceHover, 4.5],
        ["list entries", Theme.text, Theme.surfaceHover, 4.5],
        ["clock (large)", Theme.white, Theme.backdrop, 3],
        ["date (large)", Theme.mint, Theme.backdrop, 3]
    ]
    function test_contrast_data() { return pairs.map(p => ({ tag: p[0], fg: p[1], bg: p[2], min: p[3] })) }
    function test_contrast(d) {
        const r = ratio(d.fg, d.bg)
        verify(r >= d.min, d.tag + ": " + r.toFixed(2) + ":1, needs " + d.min + ":1")
    }
}

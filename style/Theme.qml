// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: the theme's colours, in one place.
pragma Singleton
import QtQuick

QtObject {
    // the sky
    readonly property color jade: "#43af9c"         // lasers, constellation lines
    readonly property color mint: "#8dd2c6"         // lasers, star trails, glows, the date
    readonly property color amber: "#dfa33a"        // lasers, fire, warnings, the wrong-password wash
    readonly property color white: "#f2f4f3"        // stars, beam cores, text
    readonly property color flare: "#ffe2a8"        // explosion flashes and embers

    // the burning planets
    readonly property color smoke: "#30302c"
    readonly property color impactSmoke: "#3b332b"
    readonly property color flame: "#ff8a26"
    readonly property color fireball: "#ff8a30"
    readonly property color fireCore: "#fff1c4"     // a fireball's white-hot middle
    readonly property color rock: "#8a7a6a"         // chips knocked off a planet
    readonly property color debris: "#ffc874"

    // the login controls
    readonly property color text: white
    readonly property color subtext: "#8a958e"      // names, placeholders
    readonly property color backdrop: "#000000"
    readonly property color panel: "#0a0b0a"        // drop-down lists
    readonly property color surface: "#121513"      // the password field, buttons
    readonly property color surfaceHover: "#1f2421"
    readonly property color faintHover: "#161917"   // hover on a see-through control
    readonly property color outline: "#1f2421"
    readonly property color outlineHover: "#2a302d"

    // `colour`, fully see-through (for a gradient's far end)
    function clear(colour: color): color { return Qt.rgba(colour.r, colour.g, colour.b, 0) }
}

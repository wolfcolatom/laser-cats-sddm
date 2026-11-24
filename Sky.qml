// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats sky (used by Main.qml): a drifting starfield and nebula,
// floating laser cats, two cats bursting out of burning planets, shooting
// stars, and the explosion and warp played when you log in.
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import "Cats.js" as Cats
import "Palette.js" as Palette
import "Rng.js" as Rng

Item {
    id: root
    // the cats are drawn for a 1080 px tall screen; this scales them so they
    // keep the same share of the screen on any monitor
    readonly property real catScale: height > 0 ? height / 1080 : 1
    // the two planet cats are drawn a bit bigger again on top of that
    readonly property real planetScale: catScale * 1.25
    property bool running: visible
    // the clock everything drifts and floats by: seconds since the sky started
    property real clock: 0
    // hold still (for the screenshot tests): no clock, no random events, no
    // animated pictures; set clock, blast and warp by hand
    property bool frozen: false
    readonly property bool live: running && !frozen
    FrameAnimation { running: root.live; onTriggered: root.clock += frameTime }
    // the random seed: a new one each time, or fixed for repeatable tests
    property int seed: Math.floor(Math.random() * 2147483647)
    Component.onCompleted: {
        Rng.seed(seed)
        // switch the flash effect on, invisibly faint, for a moment at the
        // start, so Qt prepares it before the first key press rather than
        // stuttering on it
        if (!frozen) { flash = 0.02; warmUp.start() }
    }
    Timer { id: warmUp; interval: 500; onTriggered: if (!flashAnim.running) root.flash = 0 }
    // calm: no flashing on key presses, no shooting stars or comet (and the
    // login screen skips the explosion and warp)
    property bool calm: false
    // "classic" cats: the original GIF cats (made from GIPHY GIFs on this
    // computer by get-cats.sh, which sets classic=true in theme.conf.user),
    // with their own layout; otherwise the theme's own cats
    property bool classic: false
    // the cat set in use: pictures, sizes, paw and eye spots (Cats.js)
    readonly property var cats: classic ? Cats.classic : Cats.own
    // the jade nebula (in jade) instead of the olive haze
    property bool jadeNebula: false

    // reactions (called by the login screen):
    //   keyPressed()    the cats and lasers flash a little brighter; every
    //                   2nd key chips a piece off each planet
    //   wrongPassword() they wash amber for a moment (amber = needs attention)
    //   warpOut()       the planets blow up (1.3 s), then warp speed: star
    //                   streaks rush out from the centre (0.9 s)
    //   rewind()        the login screen blows up before it knows the password
    //                   is right; if it was wrong, everything flies back
    //                   together, washed amber
    property real flash: 0
    property real alarm: 0
    property real warp: 0
    property real blast: 0          // the planets blowing up, before the warp
    property int keyCount: 0
    function keyPressed() {
        if (calm) return
        flashAnim.restart()
        keyCount++
        if (keyCount % 2 === 0) { planetLeft.keyChip(); planetRight.keyChip() }
    }
    function wrongPassword() { alarmAnim.restart() }
    function warpOut() { rewindAnim.stop(); warpAnim.restart() }
    function rewind() { warpAnim.stop(); rewindAnim.restart(); alarmAnim.restart() }
    function showComet() { comet.show() }     // (for testing)
    NumberAnimation { id: flashAnim; target: root; property: "flash"; from: 1; to: 0; duration: 380; easing.type: Easing.OutQuad }
    SequentialAnimation {
        id: alarmAnim
        NumberAnimation { target: root; property: "alarm"; to: 1; duration: 120 }
        PauseAnimation { duration: 450 }
        NumberAnimation { target: root; property: "alarm"; to: 0; duration: 700; easing.type: Easing.InOutQuad }
    }
    SequentialAnimation {
        id: warpAnim
        NumberAnimation { target: root; property: "blast"; from: 0; to: 1; duration: 1300; easing.type: Easing.Linear }
        NumberAnimation { target: root; property: "warp"; from: 0; to: 1; duration: 900; easing.type: Easing.InQuad }
    }
    ParallelAnimation {
        id: rewindAnim
        NumberAnimation { target: root; property: "warp"; to: 0; duration: 450; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "blast"; to: 0; duration: 1200; easing.type: Easing.InOutCubic }
    }
    clip: true

    // the parts, back to front (each in its own file)
    Starfield { running: root.running; clock: root.clock; jadeNebula: root.jadeNebula }
    DriftingPlanets { running: root.running; clock: root.clock; catScale: root.catScale }
    // two planet cats: the big one upper left, a smaller mirrored one upper
    // right; in front of the floating cats, comet and shooting stars
    PlanetCat {
        id: planetLeft
        z: 5
        running: root.running; active: root.live; clock: root.clock
        boom: root.blast
        cat: root.cats.planetCat
        // flashes on key presses / goes amber on a wrong password, like the floating cats
        layer.enabled: root.flash > 0.01 || root.alarm > 0.01
        layer.effect: MultiEffect { brightness: root.flash * 0.25; colorization: root.alarm * 0.75; colorizationColor: Palette.amber }
        homeX: root.width * 0.05; homeY: root.height * 0.01
        transform: Scale { xScale: root.planetScale; yScale: root.planetScale }
    }
    PlanetCat {
        id: planetRight
        z: 5
        running: root.running; active: root.live; clock: root.clock
        boom: root.blast
        cat: root.cats.planetCat
        layer.enabled: root.flash > 0.01 || root.alarm > 0.01
        layer.effect: MultiEffect { brightness: root.flash * 0.25; colorization: root.alarm * 0.75; colorizationColor: Palette.amber }
        rhythm: 2.3
        planet: "assets/planet-earth.png"       // an Earth-style planet on this side
        // 60% size and mirrored (faces the other way): mirror about its middle,
        // then shrink from its top-left corner, so it covers homeX .. homeX + 276
        // (times planetScale)
        homeX: root.width * 0.95 - width * 0.6 * root.planetScale; homeY: root.height * 0.04
        transform: [ Scale { origin.x: 230; xScale: -1 }, Scale { xScale: 0.6 * root.planetScale; yScale: 0.6 * root.planetScale } ]
    }
    Constellation {
        running: root.running; clock: root.clock; catScale: root.catScale
        areaWidth: root.width; areaHeight: root.height
    }
    FloatingCats {
        running: root.running; playing: !root.frozen; clock: root.clock; catScale: root.catScale
        flash: root.flash; alarm: root.alarm; blast: root.blast
        cats: root.cats.floaters
    }
    ShootingStars { running: root.running && !root.calm; active: root.live && !root.calm }
    Comet {
        id: comet
        running: root.running && !root.calm; active: root.live && !root.calm
        areaWidth: root.width; areaHeight: root.height
    }
    Warp {
        warp: root.warp; blast: root.blast; catScale: root.catScale
        playing: !root.frozen
        cat: root.cats.warpCat
    }
}

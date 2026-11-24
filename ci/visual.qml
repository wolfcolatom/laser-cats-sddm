// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Visual regression: renders the sky held still with a fixed random seed at
// a few exact moments, and saves each as a PNG to compare against the
// approved pictures in ci/golden/ (ci/compare.sh does the comparing).
//   QT_QPA_PLATFORM=offscreen qml ci/visual.qml -- OUTDIR
import QtQuick
import QtQuick.Window
import ".."

Window {
    id: win
    width: 1280; height: 720
    visible: true
    color: "black"

    readonly property string outDir: Qt.application.arguments[Qt.application.arguments.length - 1]
    // [name, clock (s), blast (0-1), warp (0-1)]
    readonly property var moments: [
        ["idle", 12.0, 0, 0],
        ["explosion", 12.0, 0.45, 0],
        ["warp", 12.0, 1, 0.7]
    ]
    property int step: -1

    // the sky over black, as the login screen shows it (its layers are
    // see-through). Note: Qt's software renderer can't draw the warp cat's
    // glow effect, so the warp cat itself is missing from these pictures.
    Rectangle {
        id: stage
        anchors.fill: parent
        color: "black"
        Sky {
            id: sky
            anchors.fill: parent
            frozen: true
            seed: 1234
            jadeNebula: true
        }
    }

    // give the pictures time to load, then step through the moments
    Timer { interval: 3000; running: true; onTriggered: win.next() }
    Timer { id: settle; interval: 400; onTriggered: win.shoot() }
    function next() {
        step++
        if (step >= moments.length) { Qt.exit(0); return }
        const m = moments[step]
        sky.clock = m[1]; sky.blast = m[2]; sky.warp = m[3]
        settle.start()
    }
    function shoot() {
        const name = moments[step][0]
        stage.grabToImage(result => {
            if (!result.saveToFile(outDir + "/" + name + ".png")) { console.error("visual: could not save " + name); Qt.exit(1); return }
            console.log("visual: " + name)
            win.next()
        })
    }
}

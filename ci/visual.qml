// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Visual regression: renders the sky and the login screen, held still with a
// fixed random seed, clock and font, at a few exact moments, and saves each
// as a PNG to compare against the approved pictures in ci/golden/
// (ci/compare.sh does the comparing).
//   QT_QPA_PLATFORM=offscreen qml ci/visual.qml -- OUTDIR
//
// Headless, Qt draws with its software renderer, which can't draw the warp
// cat's glow, so the warp cat itself is missing from the warp picture
// (tests/tst_cats.qml checks its lasers start at its eyes instead).
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import "../sky"
import "../login"
import "../tests"

Window {
    id: win
    width: 1280; height: 720
    visible: true
    color: "black"

    readonly property string outDir: Qt.application.arguments[Qt.application.arguments.length - 1]
    readonly property int seed: 1234
    readonly property date when: new Date(2026, 0, 2, 9, 41, 0)

    // the sky on its own: [name, clock (s), blast (0-1), warp (0-1)]
    readonly property var skyMoments: [
        ["idle", 12.0, 0, 0],
        ["explosion", 12.0, 0.45, 0],
        ["warp", 12.0, 1, 0.7]
    ]
    // the login screen: [name, set-up]
    readonly property var loginMoments: [
        ["login", () => {}],
        ["login-alerts", () => { fake.capsLock = true; fake.informationMessage("Your password expires in 3 days") }],
        ["login-several-users", () => { fake.users = several; fake.lastUser = "grace"; fake.lastUserIndex = 1 }],
        ["login-nobody-listed", () => { fake.users = nobody; fake.lastUser = "" }]
    ]
    property int step: -1

    Rectangle {                         // the sky over black, as the login screen shows it
        id: stage
        anchors.fill: parent
        color: "black"
        Sky { id: sky; anchors.fill: parent; frozen: true; seed: win.seed }
    }

    FakeBackend { id: fake }
    ListModel {
        id: several
        ListElement { name: "ada" }
        ListElement { name: "grace" }
    }
    ListModel { id: nobody }
    Component { id: loginScreen; LoginScreen { anchors.fill: parent; backend: fake } }
    property LoginScreen loginView: null

    function find(item: Item, name: string): QtObject {
        if (item.objectName === name) return item
        for (const child of item.children) { const found = find(child, name); if (found) return found }
        return null
    }

    // give the pictures time to load, then step through the moments
    Timer { interval: 3000; running: true; onTriggered: win.next() }
    Timer { id: settle; interval: 600; onTriggered: win.shoot() }
    function next() {
        step++
        if (step < skyMoments.length) {
            const m = skyMoments[step]
            sky.clock = m[1]; sky.blast = m[2]; sky.warp = m[3]
        } else if (step < skyMoments.length + loginMoments.length) {
            stage.visible = false
            if (loginView) loginView.destroy()
            fake.reset()
            // calm=auto: headless there's no GPU, so the screen holds its sky still
            fake.settings = { calm: "auto", timeFormat: "h:mm AP", dateFormat: "dddd, MMMM d" }
            loginView = loginScreen.createObject(win.contentItem) as LoginScreen
            // the same sky as above and a fixed time
            const itsSky = find(loginView, "sky") as Sky
            itsSky.seed = seed; itsSky.clock = 12
            const itsClock = find(loginView, "clockBlock") as Clock
            itsClock.ticking = false; itsClock.now = when
            loginMoments[step - skyMoments.length][1]()
            // (the text cursor blinks: take the focus away for the picture)
            loginView.forceActiveFocus()
        } else {
            Qt.exit(0)
            return
        }
        settle.start()
    }
    function shoot() {
        const login = step >= skyMoments.length
        const name = login ? loginMoments[step - skyMoments.length][0] : skyMoments[step][0]
        const target = login ? loginView : stage
        target.grabToImage(result => {
            if (!result.saveToFile(outDir + "/" + name + ".png")) { console.error("visual: could not save " + name); Qt.exit(1); return }
            console.log("visual: " + name)
            win.next()
        })
    }
}

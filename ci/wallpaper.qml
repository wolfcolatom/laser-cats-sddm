// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Loads the built Plasma wallpaper package the way Plasma Login Manager does
// (its main script, created with `configuration` and `pluginName`), lets it
// run, and checks the sky is there and moving. Saves a picture if OUTDIR is
// given. Exits 0 if all is well.
//   qml -I ci/stubs ci/wallpaper.qml -- PACKAGE_DIR [calm] [OUTDIR]
//   qml ci/wallpaper.qml -- PACKAGE_DIR plasma
// `plasma`: with the real Plasma (libplasma) instead of the stand-in. Its
// `configuration` is a KConfigPropertyMap, which QML can't make, so none is
// given: the wallpaper must then run on its defaults.
import QtQuick
import QtQuick.Window

Window {
    id: win
    width: 1280; height: 720
    visible: true
    color: "black"

    readonly property var args: Qt.application.arguments.slice(Qt.application.arguments.indexOf("--") + 1)
    readonly property string packageDir: args[0]
    readonly property bool calm: args.indexOf("calm") >= 0
    readonly property bool plasma: args.indexOf("plasma") >= 0
    readonly property string outDir: args.length > 1 && ["calm", "plasma"].indexOf(args[args.length - 1]) < 0 ? args[args.length - 1] : ""

    property Item wallpaper: null
    // the wallpaper's sky: the package carries its own copy of sky/, a type
    // QML can't name from here, so it is held untyped
    property var sky: null
    property real clockAtStart: -1

    function find(item: Item, name: string): Item {
        if (item.objectName === name) return item
        for (const child of item.children) { const found = find(child, name); if (found) return found }
        return null
    }
    function fail(message: string) { console.error("wallpaper: " + message); Qt.exit(1) }

    Component.onCompleted: {
        const component = Qt.createComponent("file://" + packageDir + "/contents/ui/main.qml")
        if (component.status !== Component.Ready) { fail("did not load: " + component.errorString()); return }
        const properties = { pluginName: "org.wolfcolatom.lasercats" }
        if (!win.plasma) properties.configuration = { Calm: win.calm }
        wallpaper = component.createObject(win.contentItem, properties) as Item
        if (!wallpaper) { fail("could not be created: " + component.errorString()); return }
        wallpaper.width = win.width; wallpaper.height = win.height
        start.start()
    }
    Timer {
        id: start
        interval: 1500
        onTriggered: {
            win.sky = win.find(win.wallpaper, "sky")
            const sky = win.sky
            if (!sky) { win.fail("no sky"); return }
            if (sky.calm !== win.calm) { win.fail("calm is " + sky.calm + ", wanted " + win.calm); return }
            win.clockAtStart = sky.clock
            check.start()
        }
    }
    Timer {
        id: check
        interval: 1500
        onTriggered: {
            const sky = win.sky
            const software = sky.GraphicsInfo.api === GraphicsInfo.Software
            // held still without a GPU; otherwise its clock must have moved on
            if (!software && !(sky.clock > win.clockAtStart)) { win.fail("the sky isn't moving"); return }
            if (software && !sky.frozen) { win.fail("software rendering, but the sky isn't held still"); return }
            const done = () => { console.log("wallpaper: ok" + (win.calm ? " (calm)" : "") + (software ? " (held still: software renderer)" : "")); Qt.exit(0) }
            if (win.outDir === "") { done(); return }
            win.wallpaper.grabToImage(r => { r.saveToFile(win.outDir + "/wallpaper" + (win.calm ? "-calm" : "") + ".png"); done() })
        }
    }
}

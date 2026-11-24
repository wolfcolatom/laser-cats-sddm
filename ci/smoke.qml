// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// CI smoke test: loads the theme the way SDDM does (Main.qml, with stand-ins
// for the context objects SDDM provides, so SddmBackend.qml is exercised),
// types a password, presses Enter and waits for the login to go through.
// Exits 0 if the theme loaded and SDDM was asked to log in, 1 otherwise.
// QML errors are caught by the workflow from the log.
//   QT_QPA_PLATFORM=offscreen qml ci/smoke.qml [-- calm | keyboard | gl]
import QtQuick
import QtQuick.Window
import QtTest

Window {
    id: win
    width: 1280; height: 720
    visible: true
    color: "black"

    readonly property bool calmMode: Qt.application.arguments.indexOf("calm") >= 0
    readonly property bool keyboardMode: Qt.application.arguments.indexOf("keyboard") >= 0
    // gl: the run must be drawn with a GPU API (see `make smoke-gl`), as on a real login screen
    readonly property bool glMode: Qt.application.arguments.indexOf("gl") >= 0

    // what SDDM gives a theme
    QtObject { id: config; property string accent: "#43af9c"; property string calm: win.calmMode ? "true" : "false"
                           property string keyboard: win.keyboardMode ? "true" : "false" }
    QtObject { id: keyboard; property bool capsLock: false }
    ListModel {
        id: userModel
        property string lastUser: "user"
        property int lastIndex: 0
        ListElement { name: "user" }
    }
    ListModel {
        id: sessionModel
        property int lastIndex: 0
        ListElement { name: "Plasma (Wayland)" }
    }
    QtObject {
        id: sddm
        property bool canReboot: true
        property bool canPowerOff: true
        property int logins: 0
        property string lastPassword: ""
        signal loginSucceeded()
        signal loginFailed()
        signal informationMessage(string message)
        function login(user, password, session) { logins++; lastPassword = password; ok.start() }
        function reboot() {}
        function powerOff() {}
    }
    Timer { id: ok; interval: 200; onTriggered: sddm.loginSucceeded() }

    Loader { id: theme; anchors.fill: parent; source: "../Main.qml" }
    TestCase { id: keys; when: false; name: "smoke" }

    Timer {
        interval: 2500; running: true
        onTriggered: {
            if (theme.status !== Loader.Ready) { console.error("smoke: theme did not load"); Qt.exit(1); return }
            for (const c of "meow") keys.keyClick(c)
            keys.keyClick(Qt.Key_Return)
            finish.start()
        }
    }
    Timer {
        id: finish
        interval: 4000          // the explosion and warp take 2.2 s before the login
        onTriggered: {
            if (sddm.logins !== 1) { console.error("smoke: login was not sent (" + sddm.logins + ")"); Qt.exit(1); return }
            if (sddm.lastPassword !== "meow") { console.error("smoke: what was typed is not what was sent"); Qt.exit(1); return }
            const software = theme.GraphicsInfo.api === GraphicsInfo.Software
            if (win.glMode && software) { console.error("smoke: drawn by the software renderer, not a GPU API"); Qt.exit(1); return }
            console.log("smoke: ok" + (win.calmMode ? " (calm)" : "") + (software ? "" : " (drawn with a GPU API)"))
            Qt.exit(0)
        }
    }
}

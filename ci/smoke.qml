// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// CI smoke test: loads the theme with a stand-in for what SDDM provides,
// types a password, presses Enter and waits for the login to go through.
// Exits 0 if the theme loaded and SDDM was asked to log in, 1 otherwise.
// QML errors are caught by the workflow from the log.
//   QT_QPA_PLATFORM=offscreen qml ci/smoke.qml [-- calm]
import QtQuick
import QtQuick.Window
import QtTest

Window {
    id: win
    width: 1280; height: 720
    visible: true
    color: "black"

    readonly property bool calmMode: Qt.application.arguments.indexOf("calm") >= 0

    // what SDDM gives a theme
    QtObject { id: config; property string accent: "#43af9c"; property string calm: win.calmMode ? "true" : "false" }
    QtObject { id: keyboard; property bool capsLock: false }
    QtObject {
        id: userModel
        property string lastUser: "user"
        property int lastIndex: 0
        function index(r, c) { return r }
        function data(i, role) { return "user" }
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
        signal loginSucceeded()
        signal loginFailed()
        function login(user, password, session) { logins++; ok.start() }
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
            console.log("smoke: ok" + (win.calmMode ? " (calm)" : ""))
            Qt.exit(0)
        }
    }
}

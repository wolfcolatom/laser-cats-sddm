// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: the login itself, with no user interface.
//
// SDDM closes the login screen the moment a password is accepted, so the
// explosion has to play before the password is sent:
//
//   Idle ── submit() ──▶ Exploding ── explosionFinished() ──▶ Waiting
//     ▲                  (skipped when calm)                     │
//     └────── loginFailed / no answer in time ◀──────────────────┘
//
// A right password never comes back from Waiting: SDDM starts the session.
// The password is held only while Exploding and dropped as it is sent.
import QtQml

QtObject {
    id: controller

    required property Backend backend
    property string user: ""
    property int session: 0
    property bool calm: false           // no explosion: send the password at once
    property int watchdogMs: 15000      // how long to wait for an answer

    enum Stage { Idle, Exploding, Waiting }
    property int stage: LoginController.Stage.Idle
    readonly property bool busy: stage !== LoginController.Stage.Idle
    property bool rejected: false       // the last password was wrong
    property string message: ""         // the latest message from the display manager

    signal explosionRequested()         // play it, then call explosionFinished()
    signal failed()                     // wrong password: rewind, shake, ask again
    signal timedOut()                   // no answer: rewind and ask again

    // false if it was ignored (already logging in, or nothing typed)
    function submit(password: string): bool {
        if (busy || password === "" || user === "") return false
        message = ""
        rejected = false
        // who and where are fixed now: a list changed while the explosion
        // plays must not send this password as somebody else
        pendingUser = user
        pendingSession = session
        if (calm) {
            send(password)
        } else {
            pending = password
            stage = LoginController.Stage.Exploding
            explosionRequested()
        }
        return true
    }
    function explosionFinished() {
        if (stage !== LoginController.Stage.Exploding) return
        const password = pending
        pending = ""
        send(password)
    }
    function clearMessage() { message = "" }

    // ---- internals
    property string pending: ""
    property string pendingUser: ""
    property int pendingSession: 0
    function send(password: string) {
        stage = LoginController.Stage.Waiting
        watchdog.start()
        backend.login(pendingUser, password, pendingSession)
    }
    readonly property Timer watchdog: Timer {
        interval: controller.watchdogMs
        onTriggered: {
            if (controller.stage !== LoginController.Stage.Waiting) return
            controller.stage = LoginController.Stage.Idle
            controller.timedOut()
        }
    }
    readonly property Connections fromBackend: Connections {
        target: controller.backend
        // accepted: the display manager closes the screen; nothing more to do
        function onLoginSucceeded() { controller.watchdog.stop() }
        function onLoginFailed() {
            // an answer after the wait was given up: the field is already
            // back, and what has been typed since must not be thrown away
            if (!controller.busy) return
            controller.watchdog.stop()
            controller.pending = ""
            controller.stage = LoginController.Stage.Idle
            controller.rejected = true
            controller.failed()
        }
        function onInformationMessage(message) { controller.message = message }
    }
}

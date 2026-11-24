// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// A stand-in display manager for the tests: it records what the login
// screen asks for, and answers logins with success or failure (or not at
// all) after a moment.
import QtQuick
import "../login"

Backend {
    id: fake

    users: ListModel { ListElement { name: "user" } }
    sessions: ListModel {
        ListElement { name: "Plasma (Wayland)" }
        ListElement { name: "niri" }
    }
    lastUser: "user"
    canReboot: true
    canPowerOff: true
    settings: ({ calm: "false" })

    // how it answers a login
    property bool accept: true
    property bool answers: true
    property int answerMs: 50

    // what it was asked
    property var logins: []             // [{ user, password, session }]
    property int reboots: 0
    property int powerOffs: 0

    onLoginRequested: (user, password, session) => {
        logins = logins.concat([{ user: user, password: password, session: session }])
        if (answers) reply.start()
    }
    onRebootRequested: reboots++
    onPowerOffRequested: powerOffs++
    readonly property Timer reply: Timer {
        interval: fake.answerMs
        onTriggered: fake.accept ? fake.loginSucceeded() : fake.loginFailed()
    }

    function reset() {
        reply.stop()
        logins = []; reboots = 0; powerOffs = 0
        accept = true; answers = true
        capsLock = false; primary = true
        canReboot = true; canPowerOff = true
        lastUser = "user"; lastUserIndex = 0; lastSession = 0
        settings = { calm: "false" }
    }
}

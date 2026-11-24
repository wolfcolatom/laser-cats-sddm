// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: the Backend filled in from SDDM. SDDM hands a theme `sddm`,
// `userModel`, `sessionModel`, `keyboard`, `config` and `primaryScreen` as
// context objects, which the QML linter can't see; this is the only file
// that touches them:
// qmllint disable unqualified
import QtQml

Backend {
    id: backend

    users: userModel
    sessions: sessionModel
    lastUser: userModel.lastUser
    lastUserIndex: userModel.lastIndex
    lastSession: sessionModel.lastIndex
    canReboot: sddm.canReboot
    canPowerOff: sddm.canPowerOff
    capsLock: keyboard.capsLock
    // older SDDMs don't say which screen is primary: then this is the only one
    primary: typeof primaryScreen === "undefined" || primaryScreen
    settings: config

    onLoginRequested: (user, password, session) => sddm.login(user, password, session)
    onRebootRequested: sddm.reboot()
    onPowerOffRequested: sddm.powerOff()

    readonly property Connections fromSddm: Connections {
        target: sddm
        function onLoginSucceeded() { backend.loginSucceeded() }
        function onLoginFailed() { backend.loginFailed() }
        function onInformationMessage(message) { backend.informationMessage(message) }
    }
}

// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: what the login screen needs from the display manager, and
// nothing more. SddmBackend.qml fills it in from SDDM; the tests use a fake
// (tests/FakeBackend.qml). The login screen only ever talks to this.
import QtQml

QtObject {
    id: backend

    // who can log in and to what: models with a "name" role
    property var users: null
    property var sessions: null
    property string lastUser: ""        // who logged in last ("" if nobody yet)
    property int lastUserIndex: 0
    property int lastSession: 0

    property bool canReboot: false
    property bool canPowerOff: false
    property bool capsLock: false
    property bool primary: true         // on the primary screen (the theme is shown once per screen)
    property var settings: ({})         // theme.conf, as SDDM gives it (see Settings.qml)

    // from the display manager
    signal loginSucceeded()
    signal loginFailed()
    signal informationMessage(string message)   // an account locked, a password expiring...

    // to the display manager: call these; an implementation handles the
    // matching ...Requested signal
    function login(user: string, password: string, session: int) { loginRequested(user, password, session) }
    function reboot() { rebootRequested() }
    function powerOff() { powerOffRequested() }
    signal loginRequested(string user, string password, int session)
    signal rebootRequested()
    signal powerOffRequested()
}

// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// The login logic on its own (login/LoginController.qml), with no user
// interface: what is sent to the display manager, and when.
import QtQuick
import QtTest
import "../login"

TestCase {
    id: test
    name: "LoginController"

    FakeBackend { id: fake }
    LoginController { id: login; backend: fake; user: "user"; session: 1 }
    SignalSpy { id: explosions; target: login; signalName: "explosionRequested" }
    SignalSpy { id: failures; target: login; signalName: "failed" }
    SignalSpy { id: timeouts; target: login; signalName: "timedOut" }

    function init() {
        fake.reset()
        login.calm = false; login.watchdogMs = 15000
        // back to Idle whatever the last test left behind
        login.watchdog.stop(); login.pending = ""; login.stage = LoginController.Stage.Idle
        login.rejected = false; login.message = ""
        explosions.clear(); failures.clear(); timeouts.clear()
    }

    function test_explosionFirstThenThePassword() {
        verify(login.submit("meow"))
        compare(login.stage, LoginController.Stage.Exploding)
        compare(explosions.count, 1)
        compare(fake.logins.length, 0, "nothing sent while the explosion plays")
        login.explosionFinished()
        compare(login.stage, LoginController.Stage.Waiting)
        compare(fake.logins, [{ user: "user", password: "meow", session: 1 }])
        compare(login.pending, "", "the password is dropped as it is sent")
    }
    function test_calmSendsAtOnce() {
        login.calm = true
        verify(login.submit("meow"))
        compare(explosions.count, 0)
        compare(fake.logins.length, 1)
        compare(login.stage, LoginController.Stage.Waiting)
    }
    function test_emptyIsIgnored() {
        verify(!login.submit(""))
        compare(login.stage, LoginController.Stage.Idle)
        compare(explosions.count, 0)
    }
    function test_busyIgnoresAnotherSubmit() {
        verify(login.submit("meow"))
        verify(!login.submit("again"), "while exploding")
        login.explosionFinished()
        verify(!login.submit("again"), "while waiting")
        compare(fake.logins.length, 1)
    }
    function test_wrongPassword() {
        fake.accept = false
        login.calm = true
        login.submit("nope")
        tryCompare(failures, "count", 1)
        compare(login.stage, LoginController.Stage.Idle)
        verify(login.rejected)
        verify(login.submit("meow"), "can try again")
        verify(!login.rejected, "the flag clears on the next try")
    }
    function test_noAnswerTimesOut() {
        fake.answers = false
        login.watchdogMs = 100
        login.calm = true
        login.submit("meow")
        tryCompare(timeouts, "count", 1)
        compare(login.stage, LoginController.Stage.Idle)
        verify(!login.rejected, "not a wrong password")
    }
    function test_rightPasswordStaysWaiting() {
        login.calm = true
        login.submit("meow")
        wait(200)
        compare(login.stage, LoginController.Stage.Waiting, "the session is starting; nothing more to do")
        compare(failures.count, 0)
    }
    function test_explosionFinishedOnlyCountsWhileExploding() {
        login.explosionFinished()
        compare(fake.logins.length, 0)
        compare(login.stage, LoginController.Stage.Idle)
    }
    function test_failureWhileExplodingDropsThePassword() {
        login.submit("meow")
        fake.loginFailed()
        compare(login.pending, "")
        login.explosionFinished()
        compare(fake.logins.length, 0, "a late explosion sends nothing")
    }
    function test_messages() {
        fake.informationMessage("Your password expires in 3 days")
        compare(login.message, "Your password expires in 3 days")
        login.clearMessage()
        compare(login.message, "")
        fake.informationMessage("Account locked")
        login.calm = true
        login.submit("meow")
        compare(login.message, "", "cleared by the next attempt")
    }
}

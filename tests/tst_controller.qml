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
        login.user = "user"; login.session = 1
        // back to Idle whatever the last test left behind
        login.watchdog.stop(); login.pending = ""; login.pendingUser = ""; login.stage = LoginController.Stage.Idle
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
    function test_emptyPasswordIsSentToo() {
        // accounts without a password, and fingerprint readers, log in with Enter alone
        login.calm = true
        verify(login.submit(""))
        compare(fake.logins, [{ user: "user", password: "", session: 1 }])
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
    function test_staleFailureDuringTheNextTryIsIgnored() {
        // nothing has been sent yet, so a failure now answers an older try
        login.submit("meow")
        fake.loginFailed()
        compare(failures.count, 0)
        compare(login.stage, LoginController.Stage.Exploding)
        login.explosionFinished()
        compare(fake.logins, [{ user: "user", password: "meow", session: 1 }])
    }
    function test_nobodyToLogInIsIgnored() {
        login.user = ""
        verify(!login.submit("meow"))
        compare(explosions.count, 0)
    }
    function test_whoAndWhereAreFixedAtSubmit() {
        login.submit("meow")
        login.user = "somebody-else"; login.session = 0      // a list changed while the explosion plays
        login.explosionFinished()
        compare(fake.logins, [{ user: "user", password: "meow", session: 1 }])
    }
    function test_lateFailureAfterGivingUpIsIgnored() {
        fake.answers = false
        login.watchdogMs = 100
        login.calm = true
        login.submit("meow")
        tryCompare(timeouts, "count", 1)
        fake.loginFailed()                                    // the answer turns up after all
        compare(failures.count, 0)
        verify(!login.rejected)
        compare(login.stage, LoginController.Stage.Idle)
    }
    function test_rightPasswordStopsTheWait() {
        login.watchdogMs = 150
        login.calm = true
        login.submit("meow")                                  // (the fake accepts after 50 ms)
        wait(400)
        compare(timeouts.count, 0, "no time-out after a yes")
        compare(login.stage, LoginController.Stage.Waiting)
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

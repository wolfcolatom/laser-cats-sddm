// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// The login screen (login/LoginScreen.qml) driven like a person would,
// against a fake display manager (FakeBackend.qml).
//   make test
pragma ComponentBehavior: Bound
import QtQuick
import QtTest
import "../login"
import "../sky"

Item {
    id: host
    width: 1280; height: 720

    FakeBackend { id: fake }
    ListModel {
        id: twoUsers
        ListElement { name: "ada" }
        ListElement { name: "grace" }
    }
    Component { id: oneUser; ListModel { ListElement { name: "user" } } }
    ListModel { id: nobody }
    Component {
        id: screenComponent
        LoginScreen { anchors.fill: parent; backend: fake }
    }

    TestCase {
        name: "Login"
        when: windowShown

        property LoginScreen screen: null
        property var users: null

        // a fresh screen, with these theme.conf settings
        function load(settings) {
            if (screen) screen.destroy()
            fake.settings = Object.assign({ calm: "false" }, settings || {})
            screen = screenComponent.createObject(host)
            verify(screen)
            return screen
        }
        function init() {
            fake.reset()
            users = oneUser.createObject(host)
            fake.users = users
            load()
        }
        function cleanup() {
            if (screen) { screen.destroy(); screen = null }
            if (users) { users.destroy(); users = null }
        }
        function part(name) {
            const item = findChild(screen, name)
            verify(item, name + " exists")
            return item
        }
        function field() { return part("password") }
        function sky(): Sky { return part("sky") as Sky }
        function controller(): LoginController { return part("login") as LoginController }
        function type(text) {
            field().forceActiveFocus()
            for (const c of text) keyClick(c)
        }
        function submit(text) { type(text); keyClick(Qt.Key_Return) }

        // ---- logging in
        function test_rightPasswordLogsInAfterTheExplosion() {
            submit("meow")
            compare(fake.logins.length, 0, "not sent before the explosion")
            compare(field().text, "", "field emptied at once")
            compare(controller().stage, LoginController.Stage.Exploding)
            tryVerify(() => sky().blast > 0, 1000, "the explosion is playing")
            tryVerify(() => fake.logins.length === 1, 4000)
            compare(fake.logins[0], { user: "user", password: "meow", session: 0 })
            compare(controller().pending, "", "password not kept after it was sent")
        }
        function test_wrongPasswordRewinds() {
            fake.accept = false
            submit("nope")
            tryVerify(() => fake.logins.length === 1, 4000)
            tryVerify(() => !controller().busy, 1000)
            compare(field().text, "")
            compare(field().placeholderText, "Wrong password")
            verify(field().activeFocus, "ready for another try")
            tryVerify(() => sky().blast === 0, 3000)
        }
        function test_enterAloneLogsInToo() {
            // accounts without a password, and fingerprint readers
            load({ calm: "true" })
            submit("")
            compare(fake.logins, [{ user: "user", password: "", session: 0 }])
        }
        function test_secondEnterDoesNotSendTwice() {
            submit("meow")
            keyClick(Qt.Key_Return)
            tryVerify(() => fake.logins.length === 1, 4000)
            wait(200)
            compare(fake.logins.length, 1)
        }
        function test_fieldIsLockedWhileLoggingIn() {
            submit("meow")
            verify(!field().enabled)
        }
        function test_calmLogsInStraightAway() {
            load({ calm: "true" })
            submit("meow")
            compare(fake.logins.length, 1, "no explosion delay in calm mode")
            compare(sky().blast, 0)
            verify(sky().calm)
        }
        function test_calmAutoFollowsTheRenderer() {
            load({ calm: "auto" })
            const software = screen.softwareRendering
            submit("meow")
            compare(fake.logins.length, software ? 1 : 0, software ? "no GPU: straight in" : "GPU: the explosion first")
            compare(sky().frozen, software)
        }
        function test_noAnswerGivesTheFieldBack() {
            fake.answers = false
            controller().watchdogMs = 300
            submit("meow")
            tryVerify(() => fake.logins.length === 1, 4000)
            tryVerify(() => !controller().busy, 2000)
            verify(field().activeFocus)
            compare(field().placeholderText, "Password", "not called a wrong password")
        }
        function test_chosenSessionIsSent() {
            load({ calm: "true" })
            const picker = part("sessionPicker")
            picker.currentIndex = 1
            picker.activated(1)
            submit("meow")
            compare(fake.logins[0].session, 1)
        }

        // ---- who is logging in
        function test_oneUserShowsJustTheName() {
            verify(!part("userPicker").visible)
            compare(controller().user, "user")
        }
        function test_firstUserWhenNobodyLoggedInBefore() {
            fake.lastUser = ""
            load()
            compare(controller().user, "user")
        }
        function test_severalUsersGetAList() {
            fake.users = twoUsers
            fake.lastUser = "grace"; fake.lastUserIndex = 1
            load({ calm: "true" })
            const picker = part("userPicker")
            verify(picker.visible)
            compare(picker.count, 2)
            compare(picker.displayText, "grace")
            compare(controller().user, "grace")
            type("half")
            picker.currentIndex = 0
            picker.activated(0)
            compare(controller().user, "ada")
            compare(field().text, "", "switching user clears what was typed")
            submit("meow")
            compare(fake.logins[0].user, "ada")
        }
        function test_listsLockWhileLoggingIn() {
            fake.users = twoUsers
            load()
            submit("meow")                      // (the explosion is playing)
            verify(!part("userPicker").enabled)
            verify(!part("sessionPicker").enabled)
        }
        function test_nobodyListedAsksForAName() {
            fake.users = nobody; fake.lastUser = ""
            load({ calm: "true" })
            const name = part("username")
            verify(name.visible)
            verify(!part("userPicker").visible)
            verify(name.activeFocus, "the name comes first")
            for (const c of " ada ") keyClick(c)
            keyClick(Qt.Key_Return)
            verify(field().activeFocus, "Enter moves on to the password")
            for (const c of "meow") keyClick(c)
            keyClick(Qt.Key_Return)
            compare(fake.logins, [{ user: "ada", password: "meow", session: 0 }])
        }
        function test_lastTypedNameIsFilledIn() {
            fake.users = nobody; fake.lastUser = "grace"
            load({ calm: "true" })
            compare(part("username").text, "grace")
            verify(field().activeFocus, "straight to the password")
        }
        function test_noNameNoLogin() {
            fake.users = nobody; fake.lastUser = ""
            load({ calm: "true" })
            submit("meow")
            compare(fake.logins.length, 0)
            compare(field().text, "meow", "what was typed is kept")
            verify(part("username").activeFocus, "and the name is asked for")
        }
        function test_nameFieldOnlyWhenNobodyIsListed() {
            verify(!part("username").visible)
        }
        function test_askUsernameReplacesTheList() {
            fake.users = twoUsers
            fake.lastUser = "grace"; fake.lastUserIndex = 1
            load({ calm: "true", askUsername: "true" })
            verify(part("username").visible)
            verify(!part("userPicker").visible)
            compare(part("username").text, "grace", "the last one to log in is filled in")
            part("username").text = "someone-on-the-network"
            submit("meow")
            compare(fake.logins[0].user, "someone-on-the-network")
        }
        function test_listsShowNames() {
            const picker = part("sessionPicker")
            compare(picker.displayText, "Plasma (Wayland)")
            picker.popup.open()
            tryVerify(() => picker.popup.opened, 2000)
            tryVerify(() => findChild(picker.popup.contentItem, "sessionPicker-1") !== null, 2000)
            compare(findChild(picker.popup.contentItem, "sessionPicker-0").text, "Plasma (Wayland)")
            compare(findChild(picker.popup.contentItem, "sessionPicker-1").text, "niri")
            picker.popup.close()
        }

        // ---- warnings and messages
        function test_capsLockWarning() {
            const warning = part("capsWarning")
            verify(!warning.visible)
            fake.capsLock = true
            verify(warning.visible)
            compare(field().Accessible.description, "Caps Lock is on")
        }
        function test_messageShowsAndClears() {
            const message = part("message")
            verify(!message.visible)
            fake.informationMessage("Your password expires in 3 days")
            verify(message.visible)
            compare(message.text, "Your password expires in 3 days")
            type("x")
            verify(!message.visible, "cleared once you type")
        }
        function test_fieldStaysCentredUnderALongMessage() {
            const centre = () => field().mapToItem(screen, field().width / 2, 0).x
            compare(centre(), screen.width / 2)
            fake.informationMessage("Your account has been locked after too many attempts; ask an administrator to unlock it")
            verify(part("message").width > field().width, "the message is wider than the field")
            wait(100)                           // (the column lays itself out on the next frame)
            compare(centre(), screen.width / 2)
        }
        function test_shakeLeavesTheFieldInPlace() {
            const x = field().x
            fake.accept = false
            load({ calm: "true" })
            submit("nope")
            tryVerify(() => field().placeholderText === "Wrong password")
            wait(250)                           // (the shake is 150 ms)
            compare(field().x, x)
        }
        function test_escapeClearsTheField() {
            type("ab")
            compare(field().text, "ab")
            keyClick(Qt.Key_Escape)
            compare(field().text, "")
        }

        // ---- power buttons
        function test_powerButtons() {
            mouseClick(part("restartButton"))
            compare(fake.reboots, 1)
            mouseClick(part("shutDownButton"))
            compare(fake.powerOffs, 1)
        }
        function test_powerButtonsHideWhenNotAllowed() {
            fake.canReboot = false
            verify(!part("restartButton").visible)
            verify(part("shutDownButton").visible)
        }
        function test_keyboardButtonOnlyWhenAsked() {
            verify(!part("keyboardButton").visible, "no on-screen keyboard button by default")
        }

        // ---- keyboard use and screen readers
        function test_tabOrder() {
            field().forceActiveFocus()
            keyClick(Qt.Key_Tab)
            verify(part("sessionPicker").activeFocus, "password -> session list")
            keyClick(Qt.Key_Tab)
            verify(part("restartButton").activeFocus, "-> restart")
            keyClick(Qt.Key_Tab)
            verify(part("shutDownButton").activeFocus, "-> shut down")
            keyClick(Qt.Key_Tab)
            verify(field().activeFocus, "and round to the password")
        }
        function test_enterPressesAFocusedButton() {
            part("restartButton").forceActiveFocus()
            keyClick(Qt.Key_Return)
            compare(fake.reboots, 1)
        }
        function test_screenReaderNames() {
            compare(field().Accessible.name, "Password")
            compare(part("sessionPicker").Accessible.name, "Session")
            compare(part("userPicker").Accessible.name, "User")
            compare(part("restartButton").Accessible.name, "Restart")
            compare(part("shutDownButton").Accessible.name, "Shut down")
            compare(part("capsWarning").Accessible.role, Accessible.AlertMessage)
            compare(part("message").Accessible.role, Accessible.AlertMessage)
            verify(part("clockBlock").Accessible.name.length > 0)
        }

        // ---- screens and settings
        function test_controlsOnlyOnThePrimaryScreen() {
            fake.primary = false
            load()
            verify(!part("sessionPicker").visible)
            verify(!field().visible)
            verify(!part("restartButton").visible)
            verify(part("clockBlock").visible, "the clock shows on every screen")
        }
        function test_timeFormatSetting() {
            load({ timeFormat: "HH:mm" })
            verify(/^\d\d:\d\d$/.test(part("clock").text), part("clock").text)
            verify(part("clockColon").visible)
        }
        function test_timeWithoutAColon() {
            load({ timeFormat: "HH.mm" })
            verify(!part("clockColon").visible, "no stray colon")
        }
        function test_dateHasNoYear() {
            const year = String(new Date().getFullYear())
            verify(part("date").text.indexOf(year) < 0, part("date").text)
        }
    }
}

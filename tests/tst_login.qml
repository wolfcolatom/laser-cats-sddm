// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// The login flow, with stand-ins for what SDDM gives a theme.
//   QT_QPA_PLATFORM=offscreen qmltestrunner -input tests
// (The tests read the theme's own properties through a Loader, which the
// linter only knows as a plain object:)
// qmllint disable missing-property
import QtQuick
import QtTest

Item {
    id: host
    width: 1280; height: 720
    // SDDM tells each copy of the theme whether it's on the primary screen
    property bool primaryScreen: true

    // what SDDM provides
    QtObject {
        id: config
        property string accent: "#43af9c"
        property string calm: "false"
        property string classic: "false"
        property string timeFormat: ""
        property string dateFormat: ""
    }
    QtObject { id: keyboard; property bool capsLock: false }
    QtObject {
        id: userModel
        property string lastUser: "user"
        property int lastIndex: 0
        function index(r, c) { return r }
        function data(i, role) { return "user" }
    }
    ListModel { id: sessionModel; property int lastIndex: 0; ListElement { name: "Plasma (Wayland)" } }
    QtObject {
        id: sddm
        property bool canReboot: true
        property bool canPowerOff: true
        property var calls: []
        property bool accept: true          // answer with success (or failure)
        property bool answers: true         // answer at all
        signal loginSucceeded()
        signal loginFailed()
        signal informationMessage(string message)
        function login(user, password, session) {
            calls = calls.concat([{ user: user, password: password, session: session }])
            if (answers) reply.start()
        }
        function reboot() {}
        function powerOff() {}
    }
    Timer { id: reply; interval: 50; onTriggered: sddm.accept ? sddm.loginSucceeded() : sddm.loginFailed() }

    Loader { id: theme; anchors.fill: parent }

    TestCase {
        name: "Login"
        when: windowShown

        function load(calm) {
            config.calm = calm ? "true" : "false"
            theme.source = ""
            theme.source = "../Main.qml"
            tryCompare(theme, "status", Loader.Ready)
        }
        function init() {
            keyboard.capsLock = false
            host.primaryScreen = true
            config.timeFormat = ""; config.dateFormat = ""
            sddm.calls = []; sddm.accept = true; sddm.answers = true
            load(false)
        }
        function field() { return findChild(theme.item, "password") }
        function submit(text) {
            field().forceActiveFocus()
            for (const c of text) keyClick(c)
            keyClick(Qt.Key_Return)
        }

        function test_rightPasswordLogsInAfterTheExplosion() {
            submit("meow")
            compare(sddm.calls.length, 0, "not sent before the explosion")
            compare(field().text, "", "field emptied at once")
            tryVerify(() => sddm.calls.length === 1, 4000)
            compare(sddm.calls[0].password, "meow")
            compare(sddm.calls[0].user, "user")
            compare(sddm.calls[0].session, 0)
            compare(theme.item.pending, "", "password not kept after it was sent")
        }
        function test_wrongPasswordRewinds() {
            sddm.accept = false
            submit("nope")
            tryVerify(() => sddm.calls.length === 1, 4000)
            tryVerify(() => !theme.item.launching, 1000)
            compare(field().text, "")
            compare(field().placeholderText, "Wrong password")
            tryVerify(() => findChild(theme.item, "sky").blast === 0, 3000)
        }
        function test_emptyPasswordIsIgnored() {
            submit("")
            wait(300)
            compare(sddm.calls.length, 0)
            verify(!theme.item.launching)
        }
        function test_secondEnterDoesNotSendTwice() {
            submit("meow")
            keyClick(Qt.Key_Return)
            tryVerify(() => sddm.calls.length === 1, 4000)
            wait(300)
            compare(sddm.calls.length, 1)
        }
        function test_calmDoesNotSendTwice() {
            load(true)
            submit("meow")
            submit("meow")
            compare(sddm.calls.length, 1)
        }
        function test_passwordNotKeptAfterSending() {
            submit("meow")
            tryVerify(() => sddm.calls.length === 1, 4000)
            compare(theme.item.pending, "")
        }
        function test_calmLogsInStraightAway() {
            load(true)
            submit("meow")
            compare(sddm.calls.length, 1, "no explosion delay in calm mode")
            compare(sddm.calls[0].password, "meow")
            compare(findChild(theme.item, "sky").blast, 0)
        }
        function test_watchdogGivesTheFieldBack() {
            sddm.answers = false
            theme.item.watchdogMs = 300
            submit("meow")
            tryVerify(() => sddm.calls.length === 1, 4000)
            tryVerify(() => !theme.item.launching, 2000)
            verify(field().activeFocus)
        }
        function test_capsLockWarning() {
            const warning = findChild(theme.item, "capsWarning")
            verify(!warning.visible)
            keyboard.capsLock = true
            verify(warning.visible)
        }
        function test_escapeClearsTheField() {
            field().forceActiveFocus()
            keyClick("a"); keyClick("b")
            compare(field().text, "ab")
            keyClick(Qt.Key_Escape)
            compare(field().text, "")
        }
    
        function test_sddmMessageShowsAndClears() {
            const msg = findChild(theme.item, "message")
            verify(!msg.visible)
            sddm.informationMessage("Your password expires in 3 days")
            verify(msg.visible)
            compare(msg.text, "Your password expires in 3 days")
            field().forceActiveFocus()
            keyClick("x")
            verify(!msg.visible, "cleared once you type")
        }
        function test_sessionListShowsNames() {
            const picker = findChild(theme.item, "sessionPicker")
            compare(picker.displayText, "Plasma (Wayland)")
            picker.popup.open()
            tryVerify(() => picker.popup.opened, 2000)
            tryVerify(() => findChild(picker.popup.contentItem, "session-0") !== null, 2000)
            compare(findChild(picker.popup.contentItem, "session-0").text, "Plasma (Wayland)")
            picker.popup.close()
        }
        function test_controlsOnlyOnThePrimaryScreen() {
            host.primaryScreen = false
            load(false)
            verify(!findChild(theme.item, "sessionPicker").visible)
            verify(!field().visible)
            verify(findChild(theme.item, "clock").visible, "the clock shows on every screen")
        }
        function test_timeFormatSetting() {
            config.timeFormat = "HH:mm"
            load(false)
            verify(/^\d\d:\d\d$/.test(findChild(theme.item, "clock").text), findChild(theme.item, "clock").text)
            verify(findChild(theme.item, "clockColon").visible)
        }
        function test_timeWithoutAColon() {
            config.timeFormat = "HH.mm"
            load(false)
            verify(!findChild(theme.item, "clockColon").visible, "no stray colon")
        }
        function test_dateHasNoYear() {
            const year = String(new Date().getFullYear())
            verify(findChild(theme.item, "date").text.indexOf(year) < 0, findChild(theme.item, "date").text)
        }
        function test_screenReaderNames() {
            compare(field().Accessible.name, "Password")
            compare(findChild(theme.item, "sessionPicker").Accessible.name, "Session")
            compare(findChild(theme.item, "power-1").Accessible.name, "Restart")
            compare(findChild(theme.item, "power-2").Accessible.name, "Shut down")
            compare(findChild(theme.item, "capsWarning").Accessible.role, Accessible.AlertMessage)
            verify(findChild(theme.item, "clock").Accessible.name.length > 0)
        }
        function test_calmAutoFollowsTheRenderer() {
            config.calm = "auto"
            theme.source = ""; theme.source = "../Main.qml"
            tryCompare(theme, "status", Loader.Ready)
            const software = theme.item.softwareRendering
            submit("meow")
            compare(sddm.calls.length, software ? 1 : 0,
                    software ? "no GPU: straight in" : "GPU: the explosion first")
            compare(findChild(theme.item, "sky").frozen, software)
        }
        function test_keyboardButtonOnlyWhenAsked() {
            verify(!findChild(theme.item, "power-0").visible, "no keyboard button by default")
        }
    }
}

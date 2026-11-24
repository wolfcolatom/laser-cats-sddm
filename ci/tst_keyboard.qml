// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// The on-screen keyboard (keyboard=true). Run on its own, because Qt only
// offers the virtual keyboard when the program starts with
// QT_IM_MODULE=qtvirtualkeyboard (`make test` does that when
// qt6-virtualkeyboard is installed).
pragma ComponentBehavior: Bound
import QtQuick
import QtTest
import "../login"
import "../tests"

Item {
    id: host
    width: 1280; height: 720

    FakeBackend { id: fake; settings: ({ calm: "true", keyboard: "true" }) }
    LoginScreen { id: screen; anchors.fill: parent; backend: fake }

    TestCase {
        name: "OnScreenKeyboard"
        when: windowShown

        function test_buttonRaisesTheKeyboard() {
            const loader = findChild(screen, "keyboardPanel")
            tryCompare(loader, "status", Loader.Ready, 5000)
            const button = findChild(screen, "keyboardButton")
            verify(button.visible, "the button appears once the keyboard has loaded")
            compare(button.Accessible.name, "On-screen keyboard")
            const keyboard = loader.item
            const panel = findChild(keyboard, "inputPanel")
            const field = findChild(screen, "password")
            verify(!keyboard.up && !panel.visible, "hidden until asked for")
            verify(panel.height > 100 && panel.height < host.height * 0.6, "a keyboard-sized panel, not the whole screen: " + panel.height)

            mouseClick(button)
            tryVerify(() => panel.visible && panel.y <= host.height - panel.height + 1, 2000, "it slides up from the bottom edge")
            verify(field.activeFocus, "and types into the password field")
            // the screen makes room: nothing it needs is under the keyboard
            const top = panel.mapToItem(host, 0, 0).y
            tryVerify(() => field.mapToItem(host, 0, field.height).y <= top, 2000, "the password field is clear of it")
            tryVerify(() => button.mapToItem(host, 0, button.height).y <= top, 2000, "and so is the button that hides it")

            mouseClick(button)
            tryVerify(() => !keyboard.up && !panel.visible, 2000, "and away again")
            tryVerify(() => button.mapToItem(host, 0, button.height).y > host.height - 40, 2000, "the button back in its corner")
        }
    }
}

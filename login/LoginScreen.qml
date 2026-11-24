// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: the login screen. The animated sky (sky/), the clock, who is
// logging in, the password field, the session list and the power buttons,
// all talking to a Backend (SDDM's, or a fake in the tests). The login
// logic is LoginController's; the settings are Settings'.
pragma ComponentBehavior: Bound
import QtQuick
import "../sky"
import "../style"

Rectangle {
    id: screen
    required property Backend backend

    color: Theme.backdrop
    // right-to-left languages: the layout mirrors
    LayoutMirroring.enabled: Qt.locale().textDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    Settings { id: settings; source: screen.backend.settings }

    // Without GPU acceleration (Qt's software renderer) the animation can't
    // run: the sky is held still and the login is calm, unless calm=false.
    readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software
    readonly property bool stillSky: softwareRendering && settings.calm !== Settings.Calm.Never
    readonly property bool calm: settings.calm === Settings.Calm.Always || stillSky
    // SDDM shows the theme on every screen; the controls go on the primary one
    readonly property bool primary: backend.primary

    LoginController {
        id: login
        objectName: "login"
        backend: screen.backend
        calm: screen.calm
        user: screen.backend.lastUser   // (the user list below picks the first one if nobody has logged in yet)
        session: screen.backend.lastSession
        onExplosionRequested: sky.warpOut()
        onFailed: screen.askAgain(true)
        onTimedOut: screen.askAgain(false)
    }
    function askAgain(wrongPassword: bool) {
        sky.rewind()                    // everything flies back, washed amber
        password.text = ""
        password.forceActiveFocus()
        if (wrongPassword) password.shake()
    }

    Sky {
        id: sky
        objectName: "sky"
        anchors.fill: parent
        calm: screen.calm
        frozen: screen.stillSky
        classic: settings.classicCats
        onWarpFinished: login.explosionFinished()
    }
    // the clock and password clear away as the planets blow up, leaving the
    // middle to the warp cat
    readonly property real clear: 1 - Math.min(1, Math.max(sky.blast * 1.6, sky.warp * 4))

    // soft dark patches under the clock and password, and the session list,
    // so the stars don't get in the way of reading them
    Image {
        opacity: screen.clear
        source: "../assets/text-shade.png"
        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: clock.bottom; verticalCenterOffset: 20 }
    }
    Image {
        source: "../assets/corner-shade.png"
        anchors { left: parent.left; bottom: parent.bottom; leftMargin: -40; bottomMargin: -16 }
    }

    Clock {
        id: clock
        objectName: "clockBlock"
        opacity: screen.clear
        timeFormat: settings.timeFormat
        dateFormat: settings.dateFormat
        // the time ends just above the middle of the screen
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - 30 - timeBottom
        width: implicitWidth; height: implicitHeight
    }

    Column {
        id: form
        visible: screen.primary
        opacity: screen.clear
        anchors { horizontalCenter: parent.horizontalCenter; top: clock.bottom; topMargin: 80 }
        spacing: 14

        // who's logging in: with one account just the name; with several, a
        // list to pick from
        Text {
            visible: userPicker.count <= 1
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.subtext
            font { pixelSize: 18; weight: Font.DemiBold }
            text: login.user
        }
        PillComboBox {
            id: userPicker
            objectName: "userPicker"
            Accessible.name: qsTr("User")
            visible: count > 1
            anchors.horizontalCenter: parent.horizontalCenter
            solid: false; centred: true; accent: settings.accent
            model: screen.backend.users
            currentIndex: Math.max(0, screen.backend.lastUserIndex)
            width: Math.max(160, labelWidth + 64); height: 34
            font { pixelSize: 18; weight: Font.DemiBold }
            Component.onCompleted: if (currentText !== "") login.user = currentText
            onActivated: { login.user = currentText; password.text = ""; password.forceActiveFocus() }
        }
        PasswordField {
            id: password
            objectName: "password"
            focus: true
            enabled: !login.busy
            accent: settings.accent
            capsLock: screen.backend.capsLock
            placeholderText: login.rejected ? qsTr("Wrong password") : qsTr("Password")
            // the field is emptied at once: the password lives on only in the controller
            onAccepted: { const typed = text; if (login.submit(typed)) text = "" }
            onTextChanged: if (text !== "") login.clearMessage()
            onKeyTyped: sky.keyPressed()
        }
        // Caps Lock warning: amber (it needs attention), only while it's on
        Text {
            objectName: "capsWarning"
            anchors.horizontalCenter: parent.horizontalCenter
            visible: screen.backend.capsLock
            text: qsTr("Caps Lock is on")
            color: Theme.amber
            font.pixelSize: 15
            Accessible.role: Accessible.AlertMessage
            Accessible.name: text
        }
        // a message from the display manager, word-wrapped under the field
        Text {
            objectName: "message"
            anchors.horizontalCenter: parent.horizontalCenter
            visible: login.message !== ""
            width: Math.min(implicitWidth, 420)
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            text: login.message
            color: Theme.text
            font.pixelSize: 15
            Accessible.role: Accessible.AlertMessage
            Accessible.name: text
        }
    }

    // bottom-left: which desktop to start
    PillComboBox {
        id: sessionPicker
        objectName: "sessionPicker"
        Accessible.name: qsTr("Session")
        visible: screen.primary
        anchors { left: parent.left; bottom: parent.bottom; margins: 28 }
        width: 220; height: 40
        opensUp: true; accent: settings.accent
        model: screen.backend.sessions
        currentIndex: login.session
        onActivated: login.session = currentIndex
        font.pixelSize: 15
    }
    // bottom-right: on-screen keyboard, restart, shut down
    PowerButtons {
        visible: screen.primary
        anchors { right: parent.right; bottom: parent.bottom; margins: 28 }
        backend: screen.backend
        accent: settings.accent
        keyboardAvailable: keyboardPanel.status === Loader.Ready
        onKeyboardRequested: { screen.keyboardShown = !screen.keyboardShown; password.forceActiveFocus() }
    }

    // the on-screen keyboard (keyboard=true in theme.conf; see VirtualKeyboard.qml).
    // It types into whatever has focus, so the password field keeps it.
    property bool keyboardShown: false
    Loader {
        id: keyboardPanel
        objectName: "keyboardPanel"
        active: settings.keyboard && screen.primary
        source: "VirtualKeyboard.qml"
        anchors.fill: parent
        z: 20
    }
    Binding { target: keyboardPanel.item; property: "shown"; value: screen.keyboardShown; when: keyboardPanel.status === Loader.Ready }

    Component.onCompleted: if (primary) password.forceActiveFocus()
}

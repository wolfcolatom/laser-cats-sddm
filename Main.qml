// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: an SDDM login screen. An animated space sky (Sky.qml), a
// clock, the password field, a session picker and power buttons.
pragma ComponentBehavior: Bound
// SDDM hands the theme `sddm`, `userModel`, `sessionModel`, `config` and
// `keyboard` as context objects, which the QML linter can't see:
// qmllint disable unqualified
import QtQuick
import QtQuick.Controls.Basic

Rectangle {
    id: root
    width: 1920; height: 1080
    color: "#000000"

    readonly property color accent: config.accent || "#43af9c"
    readonly property color text: "#f2f4f3"
    readonly property color subtext: "#8a958e"
    // the text uses the system's own font (no family set), except the clock
    // Space Grotesk (SIL Open Font License, assets/OFL-SpaceGrotesk.txt) for the clock and date
    FontLoader { id: clockFont; source: "assets/SpaceGrotesk.ttf" }
    readonly property bool lasers: true
    // calm = true in theme.conf: no explosion or warp (logs straight in), no
    // flashing on key presses, no shooting stars or comet
    readonly property bool calm: String(config.calm) === "true"
    property int session: sessionModel.lastIndex
    // the last user, or else the first one on the system (role 257 = "name")
    property string user: userModel.lastUser !== "" ? userModel.lastUser
                          : userModel.data(userModel.index(0, 0), 257) || ""

    // SDDM closes the login screen the moment a password is accepted, so the
    // planets blow up (and the warp plays) first, and only then does the
    // password go to SDDM. A wrong one rewinds it all (onLoginFailed).
    property bool launching: false
    property string pending: ""
    function launch(text) {
        if (launching || text === "") return
        launching = true
        if (calm) { sddm.login(user, text, session); loginWatchdog.start(); return }
        pending = text
        sky.warpOut()
        loginTimer.start()
    }
    Timer {
        id: loginTimer
        interval: 2200                          // the blast (1.3 s) and the warp (0.9 s)
        onTriggered: { sddm.login(root.user, root.pending, root.session); root.pending = ""; loginWatchdog.start() }
    }
    // never leave the field disabled: if SDDM hasn't answered, start over
    Timer {
        id: loginWatchdog
        interval: 15000
        onTriggered: if (root.launching) { root.launching = false; sky.rewind(); password.text = ""; password.forceActiveFocus() }
    }

    Connections {
        target: sddm
        function onLoginSucceeded() { }        // the planets already blew up (see launch())
        function onLoginFailed() {
            loginWatchdog.stop()
            root.launching = false
            sky.rewind()                        // everything flies back, washed amber
            password.forceActiveFocus()
            password.text = ""
            password.placeholderText = qsTr("Wrong password")
            shake.start()
        }
    }

    // the laser cats sky (Sky.qml)
    Sky {
        id: sky
        anchors.fill: parent
        visible: root.lasers
        jadeNebula: true
        calm: root.calm
        // the classic GIF cats, once get-cats.sh has made them (it sets classic=true)
        classic: String(config.classic) === "true"
    }

    // the clock, date and password clear away as the planets blow up,
    // leaving the middle to the spiral-eyed cat (Sky.qml)
    readonly property real clear: 1 - Math.min(1, Math.max(sky.blast * 1.6, sky.warp * 4))

    // soft dark patches under the clock / password and the session picker,
    // so the stars don't get in the way of reading them
    Image {
        visible: root.lasers
        opacity: root.clear
        source: "assets/text-shade.png"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: date.bottom
        anchors.verticalCenterOffset: 20
    }
    Image {
        visible: root.lasers
        source: "assets/corner-shade.png"
        anchors { left: parent.left; bottom: parent.bottom; leftMargin: -40; bottomMargin: -16 }
    }


    Text {
        id: clock
        opacity: root.clear
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.verticalCenter
        anchors.bottomMargin: 30   // clock, date and password centred on screen
        color: "transparent"   // the visible clock is the Row below
        font { family: clockFont.name; pixelSize: 120; weight: Font.Medium; variableAxes: ({ "wght": 500 }) }
        text: Qt.formatTime(new Date(), "h:mm AP")
        Timer { interval: 1000; running: true; repeat: true
                onTriggered: { clock.text = Qt.formatTime(new Date(), "h:mm AP");
                               date.text = Qt.formatDate(new Date(), "dddd, MMMM d") } }
    }
    // the clock drawn in three pieces so the colon sits centred on the digits
    // (Space Grotesk's colon sits at lowercase height); the Text above keeps the layout
    Row {
        anchors.centerIn: clock
        opacity: clock.opacity
        readonly property var parts: clock.text.split(":")
        TextMetrics { id: mDigit; font: clock.font; text: "9" }
        TextMetrics { id: mColon; font: clock.font; text: ":" }
        Text { text: parent.parts[0]; color: root.text; font: clock.font }
        Text { text: ":"; color: root.text; font: clock.font
               transform: Translate { y: (mDigit.tightBoundingRect.y + mDigit.tightBoundingRect.height / 2)
                                         - (mColon.tightBoundingRect.y + mColon.tightBoundingRect.height / 2) } }
        Text { text: parent.parts.length > 1 ? parent.parts[1] : ""; color: root.text; font: clock.font }
    }
    Text {
        id: date
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: clock.bottom
        anchors.topMargin: 4
        color: "#8dd2c6"   // soft mint date
        opacity: root.clear
        font { family: clockFont.name; pixelSize: 24; variableAxes: ({ "wght": 400 }) }
        text: Qt.formatDate(new Date(), "dddd, MMMM d")
    }

    Column {
        id: form
        opacity: root.clear
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: date.bottom
        anchors.topMargin: 80
        spacing: 14

        // who's logging in: with one account just the name, as before; with
        // several, the name has a small arrow and clicking it lists the others
        // (in the session picker's style)
        Text {
            visible: userPicker.count <= 1
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.subtext
            font { pixelSize: 18; weight: Font.DemiBold }
            text: root.user
        }
        ComboBox {
            id: userPicker
            objectName: "userPicker"
            visible: count > 1
            anchors.horizontalCenter: parent.horizontalCenter
            model: userModel
            textRole: "name"
            currentIndex: Math.max(0, userModel.lastIndex)
            width: Math.max(160, nameLabel.implicitWidth + 64); height: 34
            font { pixelSize: 18; weight: Font.DemiBold }
            Component.onCompleted: if (count > 1 && currentText !== "") root.user = currentText
            onActivated: { root.user = currentText; password.text = ""; password.forceActiveFocus() }
            contentItem: Text {
                id: nameLabel
                text: userPicker.displayText
                color: root.subtext
                font: userPicker.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            indicator: Text { x: userPicker.width - width - 16; anchors.verticalCenter: parent.verticalCenter
                              text: "▾"; color: root.subtext; font.pixelSize: 14 }
            background: Rectangle { radius: height / 2; color: userPicker.hovered ? "#161917" : "transparent"
                                    border.width: 1; border.color: userPicker.hovered ? "#1f2421" : "transparent" }
            // the list: a rounded panel, like the pills
            popup: Popup {
                y: userPicker.height + 6
                width: userPicker.width
                padding: 6
                implicitHeight: contentItem.implicitHeight + 12
                contentItem: ListView {
                    clip: true
                    spacing: 2
                    implicitHeight: contentHeight
                    model: userPicker.popup.visible ? userPicker.delegateModel : null
                    currentIndex: userPicker.highlightedIndex
                }
                background: Rectangle { radius: 16; color: "#0a0b0a"; border.width: 1; border.color: "#1f2421" }
            }
            delegate: ItemDelegate {
                required property var model
                required property int index
                width: userPicker.width - 12
                contentItem: Text { text: userPicker.model.name; color: root.text; font: userPicker.font
                                    horizontalAlignment: Text.AlignHCenter }
                background: Rectangle { color: highlighted ? "#1f2421" : "#0a0b0a"; radius: 10 }
                highlighted: userPicker.highlightedIndex === index
            }
        }

        TextField {
            id: password
            width: 340; height: 54
            focus: true
            echoMode: TextInput.Password
            passwordCharacter: "●"
            horizontalAlignment: TextInput.AlignHCenter
            color: root.text
            placeholderText: qsTr("Password")
            placeholderTextColor: root.subtext
            font { pixelSize: 18 }
            // dark surface inside a jade -> amber edge,
            // a little brighter while the field has focus
            background: Rectangle {
                radius: height / 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(0.263, 0.686, 0.612, password.activeFocus ? 0.6 : 0.36) }
                    GradientStop { position: 1.0; color: Qt.rgba(0.659, 0.420, 0.0, password.activeFocus ? 0.6 : 0.36) }
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: height / 2
                    color: "#121513"
                }
            }
            enabled: !root.launching
            onAccepted: root.launch(text)
            Keys.onEscapePressed: text = ""
            Keys.onPressed: event => { sky.keyPressed(); event.accepted = false }
            SequentialAnimation {
                id: shake
                NumberAnimation { target: password; property: "x"; to: password.x - 10; duration: 50 }
                NumberAnimation { target: password; property: "x"; to: password.x + 10; duration: 50 }
                NumberAnimation { target: password; property: "x"; to: password.x; duration: 50 }
            }
        }

        // Caps Lock warning: amber (it needs attention), only while it's on
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: keyboard.capsLock
            text: qsTr("Caps Lock is on")
            color: "#dfa33a"
            font { pixelSize: 15 }
        }
    }

    // bottom-left: which desktop to start
    ComboBox {
        id: sessionPicker
        anchors { left: parent.left; bottom: parent.bottom; margins: 28 }
        width: 220; height: 40
        model: sessionModel
        textRole: "name"
        currentIndex: root.session
        onActivated: root.session = currentIndex
        font { pixelSize: 15 }
        contentItem: Text {
            leftPadding: 18
            text: sessionPicker.displayText
            color: root.subtext
            font: sessionPicker.font
            verticalAlignment: Text.AlignVCenter
        }
        indicator: Text { x: sessionPicker.width - width - 16; anchors.verticalCenter: parent.verticalCenter
                          text: "▾"; color: root.subtext; font.pixelSize: 14 }
        // solid dark fill, like the power buttons
        background: Rectangle { radius: height / 2; color: sessionPicker.hovered ? "#1f2421" : "#121513"
                                border.width: 1; border.color: sessionPicker.hovered ? "#2a302d" : "#1f2421" }
        // the list: a rounded panel, like the pills
        popup: Popup {
            y: -implicitHeight - 6
            width: sessionPicker.width
            padding: 6
            implicitHeight: contentItem.implicitHeight + 12
            contentItem: ListView {
                clip: true
                spacing: 2
                implicitHeight: contentHeight
                model: sessionPicker.popup.visible ? sessionPicker.delegateModel : null
                currentIndex: sessionPicker.highlightedIndex
            }
            background: Rectangle { radius: 16; color: "#0a0b0a"; border.width: 1; border.color: "#1f2421" }
        }
        delegate: ItemDelegate {
            required property var model
            required property int index
            width: sessionPicker.width - 12
            contentItem: Text { text: sessionPicker.model.name; color: root.text; font: sessionPicker.font; leftPadding: 10 }
            background: Rectangle { color: highlighted ? "#1f2421" : "#0a0b0a"; radius: 10 }
            highlighted: sessionPicker.highlightedIndex === index
        }
    }

    // bottom-right: power
    Row {
        anchors { right: parent.right; bottom: parent.bottom; margins: 28 }
        spacing: 10
        Repeater {
            model: [
                { icon: "assets/system-reboot.svg", label: qsTr("Restart"), ok: sddm.canReboot, act: function() { sddm.reboot() } },
                { icon: "assets/system-shutdown.svg", label: qsTr("Shut down"), ok: sddm.canPowerOff, act: function() { sddm.powerOff() } }
            ]
            // small square icon buttons on a solid dark fill; the name shows
            // as a rounded tooltip on hover
            delegate: Button {
                required property var modelData
                required property int index
                id: powerButton
                objectName: "power-" + index
                visible: modelData.ok
                width: 40; height: 40
                onClicked: modelData.act()
                contentItem: Image { source: powerButton.modelData.icon; sourceSize: Qt.size(20, 20); fillMode: Image.Pad }
                background: Rectangle { radius: 9; color: powerButton.hovered ? "#1f2421" : "#121513"
                                        border.width: 1; border.color: powerButton.hovered ? "#2a302d" : "#1f2421" }
                ToolTip {
                    visible: powerButton.hovered
                    delay: 400
                    y: -implicitHeight - 8
                    x: (powerButton.width - implicitWidth) / 2
                    contentItem: Text { text: powerButton.modelData.label; color: root.text; font { pixelSize: 14 } }
                    background: Rectangle { radius: 10; color: "#121513"; border.width: 1; border.color: "#2a302d" }
                    padding: 8; leftPadding: 12; rightPadding: 12
                }
            }
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}

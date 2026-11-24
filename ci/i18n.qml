// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// CI: loads the theme and prints the password field's placeholder, the
// Restart button's name and whether the layout is mirrored, to check translations and right-to-left
// languages:   qml --translation translations/de.qm ci/i18n.qml
import QtQuick
import QtQuick.Window
// (reads the field's placeholder through the Loader:)
// qmllint disable missing-property

Window {
    id: win
    width: 800; height: 600
    visible: true
    QtObject { id: config; property string calm: "true" }
    QtObject { id: keyboard; property bool capsLock: false }
    ListModel { id: userModel; property string lastUser: "user"; property int lastIndex: 0; ListElement { name: "user" } }
    ListModel { id: sessionModel; property int lastIndex: 0; ListElement { name: "Plasma" } }
    QtObject {
        id: sddm
        property bool canReboot: true
        property bool canPowerOff: true
        signal loginSucceeded()
        signal loginFailed()
        signal informationMessage(string message)
        function login(user, password, session) {}
        function reboot() {}
        function powerOff() {}
    }
    Loader {
        id: theme
        anchors.fill: parent
        source: "../Main.qml"
        onLoaded: {
            Qt.callLater(() => {
                console.log("i18n: placeholder=" + win.find(theme.item, "password").placeholderText
                            + " restart=" + win.find(theme.item, "restartButton").label
                            + " mirrored=" + (theme.item as Item).LayoutMirroring.enabled)
                Qt.exit(0)
            })
        }
    }
    function find(item: Item, name: string): Item {
        if (item.objectName === name) return item
        for (const child of item.children) { const found = find(child, name); if (found) return found }
        return null
    }
}

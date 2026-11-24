// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: an SDDM login screen. This is where SDDM starts: the login
// screen (login/LoginScreen.qml) given SDDM as its backend.
import QtQuick
import "login"

LoginScreen {
    width: 1920; height: 1080
    backend: SddmBackend {}
}

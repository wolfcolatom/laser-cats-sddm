// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// The theme's settings (login/Settings.qml), read from SDDM's strings.
import QtQuick
import QtTest
import "../login"
import "../style"

TestCase {
    name: "Settings"

    Settings { id: settings; source: ({}) }

    function test_defaults() {
        settings.source = {}
        compare(settings.calm, Settings.Calm.Auto)
        verify(!settings.classicCats)
        verify(!settings.keyboard)
        compare(settings.timeFormat, "")
        compare(settings.dateFormat, "")
        verify(Qt.colorEqual(settings.accent, Theme.jade))
    }
    function test_missingSourceIsDefaults() {
        settings.source = null
        compare(settings.calm, Settings.Calm.Auto)
        verify(!settings.classicCats)
    }
    function test_calm_data() {
        return [ { tag: "true", value: "true", calm: Settings.Calm.Always },
                 { tag: "false", value: "false", calm: Settings.Calm.Never },
                 { tag: "auto", value: "auto", calm: Settings.Calm.Auto },
                 { tag: "empty", value: "", calm: Settings.Calm.Auto },
                 { tag: "nonsense", value: "maybe", calm: Settings.Calm.Auto } ]
    }
    function test_calm(d) {
        settings.source = { calm: d.value }
        compare(settings.calm, d.calm)
    }
    function test_flags_data() {
        return [ { tag: "true", value: "true", on: true }, { tag: "True", value: "True", on: true },
                 { tag: "padded", value: " true ", on: true }, { tag: "bool", value: true, on: true },
                 { tag: "false", value: "false", on: false }, { tag: "1", value: "1", on: false },
                 { tag: "empty", value: "", on: false } ]
    }
    function test_flags(d) {
        settings.source = { classic: d.value, keyboard: d.value }
        compare(settings.classicCats, d.on)
        compare(settings.keyboard, d.on)
    }
    function test_askUsername() {
        verify(!settings.askUsername)
        settings.source = { askUsername: "true" }
        verify(settings.askUsername)
    }
    function test_formatsAndAccent() {
        settings.source = { timeFormat: " HH:mm ", dateFormat: "d MMMM", accent: "#ff0000" }
        compare(settings.timeFormat, "HH:mm")
        compare(settings.dateFormat, "d MMMM")
        verify(Qt.colorEqual(settings.accent, "#ff0000"))
    }
    function test_accent_data() {
        return [
            { tag: "hex", value: "#ff0000", expect: "#ff0000" },
            { tag: "a name", value: "teal", expect: "#008080" },
            { tag: "not set", value: "", expect: Theme.jade },
            { tag: "a typo", value: "#43af9", expect: Theme.jade },
            { tag: "nonsense", value: "jadeish", expect: Theme.jade }
        ]
    }
    function test_accent(d) {
        settings.source = { accent: d.value }
        verify(Qt.colorEqual(settings.accent, d.expect), d.tag + " gave " + settings.accent)
    }
}

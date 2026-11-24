// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: the theme's settings (theme.conf and theme.conf.user), read
// once into typed values. SDDM gives them as strings.
import QtQuick
import "../style"

QtObject {
    id: settings
    required property var source        // SDDM's config object

    // calm: no explosion or warp (logs straight in), no flashing on key
    // presses, no shooting stars or comet
    //   Auto    only without GPU acceleration (the sky is then held still too)
    //   Always, Never
    enum Calm { Auto, Always, Never }
    readonly property int calm: text("calm") === "true" ? Settings.Calm.Always
                              : text("calm") === "false" ? Settings.Calm.Never : Settings.Calm.Auto
    readonly property bool classicCats: flag("classic")     // the GIF cats from get-cats.sh
    readonly property bool keyboard: flag("keyboard")       // offer the on-screen keyboard
    readonly property string timeFormat: text("timeFormat") // "" = the system's
    readonly property string dateFormat: text("dateFormat")
    readonly property color accent: text("accent") !== "" ? text("accent") : Theme.jade

    function text(key: string): string {
        const value = source ? source[key] : undefined
        return value === undefined || value === null ? "" : String(value).trim()
    }
    function flag(key: string): bool { return text(key).toLowerCase() === "true" }
}

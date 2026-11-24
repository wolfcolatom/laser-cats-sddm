// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: one of a planet cat's lasers.
import QtQml

QtObject {
    required property int paw           // 0 = its left paw, 1 = its right
    required property real angle        // where it lands: degrees round the planet's rim (0 = right, 90 = down)
    required property real sweep        // how far it swings either way (degrees)
    required property real speed        // swings per 6 seconds
}

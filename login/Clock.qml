// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: the time and date, in the system's own format (12 or 24
// hours, its language) unless timeFormat / dateFormat say otherwise.
// `timeBottom` is where the big time ends, for placing it on the screen.
import QtQuick
import "../style"

Item {
    id: clock
    property string timeFormat: ""      // Qt's date format; "" = the system's
    property string dateFormat: ""
    property date now: new Date()
    property bool ticking: true         // (off in tests, which set `now`)

    readonly property string timeText: Qt.locale().toString(now, timeFormat !== "" ? timeFormat
                                                                 : Qt.locale().timeFormat(Locale.ShortFormat))
    // the locale's long date without the year, unless a format is given
    readonly property string dateText: Qt.locale().toString(now, dateFormat !== "" ? dateFormat
        : withoutYear(Qt.locale().dateFormat(Locale.LongFormat)))

    // A Qt date format with the year taken out, along with the words that
    // belong to it, leaving one separator where it was:
    //   "dddd, d 'de' MMMM 'de' yyyy"  -> "dddd, d 'de' MMMM"
    //   "d MMMM yyyy 'г'."             -> "d MMMM"
    //   "yyyy年M月d日dddd"              -> "M月d日dddd"
    //   "dddd, yyyy. 'gada' d. MMMM"   -> "dddd, d. MMMM"
    function withoutYear(format: string): string {
        // fields (a run of one letter) and the text between them (quoted or not)
        const parts = format.match(/([a-zA-Z])\1*|'[^']*'|[^a-zA-Z']+/g) ?? []
        const isField = part => /^[a-zA-Z]/.test(part)
        const isQuoted = part => part.charAt(0) === "'"
        const year = parts.findIndex(part => /^y+$/.test(part))
        if (year < 0) return format
        // the text either side of the year, up to the neighbouring fields
        let from = year, to = year
        while (from > 0 && !isField(parts[from - 1])) from--
        while (to < parts.length - 1 && !isField(parts[to + 1])) to++
        // the year's own words: quoted ones between it and those fields
        let start = year, end = year
        for (let i = from; i < year; i++) if (isQuoted(parts[i])) { start = i; break }
        for (let i = to; i > year; i--) if (isQuoted(parts[i])) { end = i; break }
        // what is left either side; in the middle of a date one of them
        // stays to join the neighbours: the one with punctuation in it
        const before = parts.slice(from, start).join(""), after = parts.slice(end + 1, to + 1).join("")
        const inTheMiddle = from > 0 && to < parts.length - 1
        const joint = !inTheMiddle ? "" : /\S/.test(after) || !/\S/.test(before) ? after : before
        return parts.slice(0, from).concat([joint], parts.slice(to + 1)).join("").trim()
    }
    readonly property real timeBottom: time.height

    implicitWidth: Math.max(time.implicitWidth, date.implicitWidth)
    implicitHeight: time.height + date.anchors.topMargin + date.height
    Accessible.role: Accessible.StaticText
    Accessible.name: timeText + ", " + dateText

    Timer { interval: 1000; running: clock.ticking; repeat: true; onTriggered: clock.now = new Date() }
    // Space Grotesk (SIL Open Font License) for the time and date
    FontLoader { id: face; source: "../assets/SpaceGrotesk.ttf" }

    Text {                              // keeps the layout; the visible time is the Row below
        id: time
        objectName: "clock"
        anchors.horizontalCenter: parent.horizontalCenter
        color: "transparent"
        font { family: face.name; pixelSize: 120; weight: Font.Medium; variableAxes: ({ "wght": 500 }) }
        text: clock.timeText
        Accessible.ignored: true
    }
    // the time drawn in pieces so a colon sits centred on the digits (Space
    // Grotesk's colon sits at lowercase height). Times written without a
    // colon are drawn as they are.
    Row {
        id: pieces
        anchors.centerIn: time
        readonly property int split: time.text.indexOf(":")
        TextMetrics { id: digit; font: time.font; text: "9" }
        TextMetrics { id: colon; font: time.font; text: ":" }
        Text { text: pieces.split < 0 ? time.text : time.text.slice(0, pieces.split); color: Theme.text; font: time.font
               Accessible.ignored: true }
        Text { objectName: "clockColon"; visible: pieces.split >= 0; text: ":"; color: Theme.text; font: time.font
               Accessible.ignored: true
               transform: Translate { y: (digit.tightBoundingRect.y + digit.tightBoundingRect.height / 2)
                                         - (colon.tightBoundingRect.y + colon.tightBoundingRect.height / 2) } }
        Text { visible: pieces.split >= 0; text: time.text.slice(pieces.split + 1); color: Theme.text; font: time.font
               Accessible.ignored: true }
    }
    Text {
        id: date
        objectName: "date"
        anchors { horizontalCenter: parent.horizontalCenter; top: time.bottom; topMargin: 4 }
        color: Theme.mint
        font { family: face.name; pixelSize: 24; variableAxes: ({ "wght": 400 }) }
        text: clock.dateText
        Accessible.ignored: true        // read out with the time
    }
}

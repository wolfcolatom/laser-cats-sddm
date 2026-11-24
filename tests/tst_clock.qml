// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// The date under the clock (login/Clock.qml): each language's own long
// date with the year taken out, leaving no stray words or punctuation.
import QtQuick
import QtTest
import "../login"

TestCase {
    name: "Clock"

    Clock { id: clock; ticking: false; now: new Date(2026, 10, 24, 9, 41, 0) }

    // long date formats as the Unicode locale data has them
    function test_withoutYear_data() {
        return [
            { tag: "en_US", format: "dddd, MMMM d, yyyy", expect: "dddd, MMMM d" },
            { tag: "en_GB", format: "dddd, d MMMM yyyy", expect: "dddd, d MMMM" },
            { tag: "de", format: "dddd, d. MMMM yyyy", expect: "dddd, d. MMMM" },
            { tag: "es", format: "dddd, d 'de' MMMM 'de' yyyy", expect: "dddd, d 'de' MMMM" },
            { tag: "pt_BR", format: "dddd, d 'de' MMMM 'de' yyyy", expect: "dddd, d 'de' MMMM" },
            { tag: "ru", format: "dddd, d MMMM yyyy 'г'.", expect: "dddd, d MMMM" },
            { tag: "ja", format: "yyyy年M月d日dddd", expect: "M月d日dddd" },
            { tag: "zh_CN", format: "yyyy年M月d日dddd", expect: "M月d日dddd" },
            { tag: "ko", format: "yyyy년 M월 d일 dddd", expect: "M월 d일 dddd" },
            { tag: "hu", format: "yyyy. MMMM d., dddd", expect: "MMMM d., dddd" },
            { tag: "year in the middle", format: "d MMMM yyyy, dddd", expect: "d MMMM, dddd" },
            { tag: "two-digit year", format: "dddd d/M/yy", expect: "dddd d/M" },
            { tag: "no year", format: "dddd d MMMM", expect: "dddd d MMMM" },
            { tag: "a y inside quotes is not a year", format: "d 'day' MMMM yyyy", expect: "d 'day' MMMM" }
        ]
    }
    function test_withoutYear(d) { compare(clock.withoutYear(d.format), d.expect) }

    // and against the locale data this Qt has: no year, nothing left dangling
    function test_everyShippedLanguage_data() {
        return ["en_US", "en_GB", "de_DE", "es_ES", "fr_FR", "it_IT", "ja_JP", "nl_NL", "pl_PL", "pt_BR",
                "ru_RU", "zh_CN", "ko_KR", "hu_HU", "he_IL", "ar_EG", "tr_TR", "sv_SE"].map(name => ({ tag: name }))
    }
    function test_everyShippedLanguage(d) {
        const locale = Qt.locale(d.tag)
        const full = locale.dateFormat(Locale.LongFormat)
        const format = clock.withoutYear(full)
        const text = locale.toString(clock.now, format)
        verify(!/y/.test(format.replace(/'[^']*'/g, "")), "a year field is left in " + format)
        verify(text.indexOf("2026") < 0, "the year is in: " + text)
        // it ends with a day or month, or text that belongs to one (日, 일),
        // never a joining word or punctuation left over from the year
        const tail = format.slice(format.search(/[dM][^dM]*$/) + 1)
        verify(tail.length <= 2 && !/[',\s]/.test(tail), "'" + full + "' left '" + format + "'")
    }
}

// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Performance: runs the login screen full screen (on a real GPU, so not in
// CI) and measures frames per second and frame times, idle and through the
// explosion and warp. Prints a summary and quits after about 20 seconds.
//   qml ci/perf.qml
import QtQuick
import QtQuick.Window
import QtTest
import "../login"
import "../tests"

Window {
    id: win
    visible: true
    visibility: Window.FullScreen
    color: "black"

    FakeBackend { id: fake; answers: false }      // (never answers: the screen stays up to be measured)
    LoginScreen { id: screen; anchors.fill: parent; backend: fake }
    TestCase { id: keys; when: false; name: "perf" }

    // frame times (ms) per phase
    property string phase: "warmup"
    property var times: ({ idle: [], typing: [], login: [] })
    FrameAnimation {
        running: true
        onTriggered: if (win.phase !== "warmup" && win.phase !== "done") win.times[win.phase].push(frameTime * 1000)
    }
    function summary(name) {
        const t = times[name].slice().sort((a, b) => a - b)
        if (t.length === 0) return name + ": no frames"
        const avg = t.reduce((a, b) => a + b, 0) / t.length
        const pct = p => t[Math.min(t.length - 1, Math.floor(t.length * p))]
        return name + ": " + (1000 / avg).toFixed(1) + " fps average, frame time median " + pct(0.5).toFixed(1)
               + " ms, 95th " + pct(0.95).toFixed(1) + " ms, worst " + t[t.length - 1].toFixed(1) + " ms (" + t.length + " frames)"
    }
    // warm up 3 s, idle 10 s, type 2 s, then Enter and 2.5 s of explosion and warp
    SequentialAnimation {
        running: true
        PauseAnimation { duration: 3000 }
        ScriptAction { script: win.phase = "idle" }
        PauseAnimation { duration: 10000 }
        ScriptAction { script: win.phase = "typing" }
        ScriptAction { script: { for (const c of "meow") keys.keyClick(c) } }
        PauseAnimation { duration: 2000 }
        ScriptAction { script: { win.phase = "login"; keys.keyClick(Qt.Key_Return) } }
        PauseAnimation { duration: 2500 }
        ScriptAction {
            script: {
                win.phase = "done"
                console.log("perf: " + Screen.width + "x" + Screen.height + " (x" + Screen.devicePixelRatio + "), software rendering: " + screen.softwareRendering)
                for (const n of ["idle", "typing", "login"]) console.log("perf: " + win.summary(n))
                Qt.exit(0)
            }
        }
    }
}

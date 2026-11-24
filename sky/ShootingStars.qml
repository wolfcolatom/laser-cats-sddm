// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: shooting stars.
pragma ComponentBehavior: Bound
import QtQuick
import "../style"

Item {
    id: shootingStars
    anchors.fill: parent
    required property bool running      // shown
    required property bool active       // shooting now and then (off while held still)
    required property int seed          // for its random numbers
    Rng { id: rng; seed: shootingStars.seed }

    // shooting stars: three, each on its own timer (every 2-7 s), with
    // their own length, angle and speed; a mint trail to a white head
    Repeater {
        model: shootingStars.running ? 3 : 0
        Rectangle {
            required property int index
            id: shooting
            height: 2; radius: 1
            opacity: 0
            antialiasing: true
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.6; color: Theme.mint }      // a mint trail
                GradientStop { position: 1.0; color: Theme.white }
            }
            property real x0: 0
            property real y0: 0
            property real dist: 500
            property int time: 900
            ParallelAnimation {
                id: shoot
                NumberAnimation { target: shooting; property: "x"; from: shooting.x0
                                  to: shooting.x0 + shooting.dist * Math.cos(shooting.rotation * Math.PI / 180)
                                  duration: shooting.time; easing.type: Easing.OutQuad }
                NumberAnimation { target: shooting; property: "y"; from: shooting.y0
                                  to: shooting.y0 + shooting.dist * Math.sin(shooting.rotation * Math.PI / 180)
                                  duration: shooting.time; easing.type: Easing.OutQuad }
                SequentialAnimation {
                    NumberAnimation { target: shooting; property: "opacity"; to: 0.9; duration: shooting.time * 0.15 }
                    NumberAnimation { target: shooting; property: "opacity"; to: 0; duration: shooting.time * 0.85 }
                }
            }
            Timer {
                interval: 1500 + shooting.index * 1700; repeat: true; running: shootingStars.active
                onTriggered: {
                    interval = 2000 + rng.next() * 5000
                    shooting.width = 110 + rng.next() * 170
                    shooting.rotation = 8 + rng.next() * 28
                    shooting.dist = 350 + rng.next() * 450
                    shooting.time = 600 + rng.next() * 700
                    shooting.x0 = rng.next() * shootingStars.width * 0.85
                    shooting.y0 = rng.next() * shootingStars.height * 0.7
                    shoot.start()
                }
            }
        }
    }
}

// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: a comet crossing now and then.
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import "../style"

// a comet, every 25-50 s: a slow crossing with a long jade tail
Item {
    id: comet
    required property bool running      // shown
    required property bool active       // crossing now and then (off while held still)
    required property int seed          // for its random numbers
    Rng { id: rng; seed: comet.seed }
    required property real areaWidth    // the sky it crosses
    required property real areaHeight
    visible: running
    width: 460; height: 14
    opacity: 0
    rotation: 12
    property real x0: 0
    property real y0: 0
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width; height: 3; radius: 1.5
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.55; color: Theme.faded(Theme.jadeDeep, 0.45) }
            GradientStop { position: 0.9; color: Theme.mint }
            GradientStop { position: 1.0; color: Theme.white }
        }
    }
    Rectangle {           // the head, with a soft glow
        x: parent.width - 9; anchors.verticalCenter: parent.verticalCenter
        width: 12; height: 12; radius: 6; color: Theme.white
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 0.4; shadowEnabled: true; shadowColor: Theme.mint; shadowBlur: 1.0; shadowHorizontalOffset: 0; shadowVerticalOffset: 0 }
    }
    ParallelAnimation {
        id: cometRun
        NumberAnimation { target: comet; property: "x"; from: comet.x0; to: comet.x0 + comet.areaWidth * 0.9; duration: 6500; easing.type: Easing.InOutSine }
        NumberAnimation { target: comet; property: "y"; from: comet.y0; to: comet.y0 + comet.areaWidth * 0.9 * Math.tan(comet.rotation * Math.PI / 180); duration: 6500; easing.type: Easing.InOutSine }
        SequentialAnimation {
            NumberAnimation { target: comet; property: "opacity"; to: 0.9; duration: 1200 }
            PauseAnimation { duration: 4000 }
            NumberAnimation { target: comet; property: "opacity"; to: 0; duration: 1300 }
        }
    }
    Timer {
        id: cometTimer
        interval: 12000; repeat: true; running: comet.active
        onTriggered: {
            interval = 25000 + rng.next() * 25000
            comet.rotation = 6 + rng.next() * 16
            comet.x0 = -comet.width + rng.next() * comet.areaWidth * 0.2
            comet.y0 = rng.next() * comet.areaHeight * 0.45
            cometRun.start()
        }
    }
}

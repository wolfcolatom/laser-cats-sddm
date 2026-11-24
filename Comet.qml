// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: a comet crossing now and then.
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import "Palette.js" as Palette

// a comet, every 25-50 s: a slow crossing with a long jade tail
Item {
    id: comet
    property var sky                    // the Sky it belongs to (sizes, state)
    function show() { cometTimer.triggered() }     // (for testing)
    visible: sky.running
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
            GradientStop { position: 0.55; color: Qt.rgba(0.196, 0.561, 0.494, 0.45) }
            GradientStop { position: 0.9; color: Palette.mint }
            GradientStop { position: 1.0; color: Palette.white }
        }
    }
    Rectangle {           // the head, with a soft glow
        x: parent.width - 9; anchors.verticalCenter: parent.verticalCenter
        width: 12; height: 12; radius: 6; color: Palette.white
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 0.4; shadowEnabled: true; shadowColor: Palette.mint; shadowBlur: 1.0; shadowHorizontalOffset: 0; shadowVerticalOffset: 0 }
    }
    ParallelAnimation {
        id: cometRun
        NumberAnimation { target: comet; property: "x"; from: comet.x0; to: comet.x0 + comet.sky.width * 0.9; duration: 6500; easing.type: Easing.InOutSine }
        NumberAnimation { target: comet; property: "y"; from: comet.y0; to: comet.y0 + comet.sky.width * 0.9 * Math.tan(comet.rotation * Math.PI / 180); duration: 6500; easing.type: Easing.InOutSine }
        SequentialAnimation {
            NumberAnimation { target: comet; property: "opacity"; to: 0.9; duration: 1200 }
            PauseAnimation { duration: 4000 }
            NumberAnimation { target: comet; property: "opacity"; to: 0; duration: 1300 }
        }
    }
    Timer {
        id: cometTimer
        interval: 12000; repeat: true; running: comet.sky.running
        onTriggered: {
            interval = 25000 + Math.random() * 25000
            comet.rotation = 6 + Math.random() * 16
            comet.x0 = -comet.width + Math.random() * comet.sky.width * 0.2
            comet.y0 = Math.random() * comet.sky.height * 0.45
            cometRun.start()
        }
    }
}

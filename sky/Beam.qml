// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: one laser beam from a cat's paw to a spot on its planet's
// rim, swinging back and forth across the surface. A widening see-through
// beam with a bright core, shimmering a little.
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import "../style"
import "Rng.js" as Rng

Item {
    id: beam
    required property point from        // where it starts (the paw)
    required property point centre      // the planet's centre
    required property real radius       // and radius
    required property real angle        // where it lands: degrees round the rim (0 = right, 90 = down)
    required property real sweep        // how far it swings either way (degrees)
    required property real speed        // swings per 6 seconds
    required property real phase        // offset, so the beams don't swing in step
    required property real clock        // seconds since the sky started
    required property color colour
    required property real spreadBase   // half-width at the planet: base + length x growth
    required property real spreadGrowth
    required property bool active       // shimmering (off while held still)
    property real fade: 0               // 0-1: gone as the planet blows up

    readonly property real ang: (angle + sweep * Math.sin(clock * 2 * Math.PI * speed / 6 + phase)) * Math.PI / 180
    // where it lands right now
    readonly property point to: Qt.point(centre.x + radius * Math.cos(ang), centre.y + radius * Math.sin(ang))
    readonly property real len: Math.sqrt(Math.pow(to.x - from.x, 2) + Math.pow(to.y - from.y, 2))
    readonly property real spread: spreadBase + len * spreadGrowth

    property real shimmer: 1
    Timer { interval: 70; repeat: true; running: beam.active; onTriggered: beam.shimmer = 0.8 + Rng.next() * 0.2 }

    // laid along x from the paw; the item is as tall as the widest end, so
    // the soft-edge blur has room
    width: len; height: spread * 2 + 12
    x: from.x; y: from.y - height / 2
    transformOrigin: Item.Left
    rotation: Math.atan2(to.y - from.y, to.x - from.x) * 180 / Math.PI
    opacity: shimmer * (1 - Math.min(1, fade * 4))
    layer.enabled: true
    layer.effect: MultiEffect { blurEnabled: true; blur: 0.35; blurMax: 10 }
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0; y1: 0; x2: beam.len; y2: 0
                GradientStop { position: 0.0; color: Qt.rgba(0.95, 0.96, 0.95, 0.95) }
                GradientStop { position: 0.18; color: Qt.rgba(beam.colour.r, beam.colour.g, beam.colour.b, 0.8) }
                GradientStop { position: 0.75; color: Qt.rgba(beam.colour.r, beam.colour.g, beam.colour.b, 0.5) }
                GradientStop { position: 1.0; color: Qt.rgba(beam.colour.r, beam.colour.g, beam.colour.b, 0.0) }   // fades into the surface
            }
            startX: 0; startY: beam.height / 2 - 2
            PathLine { x: beam.len; y: beam.height / 2 - beam.spread }
            PathLine { x: beam.len; y: beam.height / 2 + beam.spread }
            PathLine { x: 0; y: beam.height / 2 + 2 }
            PathLine { x: 0; y: beam.height / 2 - 2 }
        }
    }
    Rectangle {                         // bright core
        x: 0; y: beam.height / 2 - 1; width: beam.len; height: 2; radius: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.white }
            GradientStop { position: 0.6; color: Qt.rgba(1, 1, 1, 0.35) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }
}

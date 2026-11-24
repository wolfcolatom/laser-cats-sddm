// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats: warp speed after login: star streaks rushing out, and a cat
// in the middle that fires its eye lasers.
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import "Palette.js" as Palette

Item {
    id: warpScene
    anchors.fill: parent
    z: 10                                   // over everything, the planet cats too
    property var sky                    // the Sky it belongs to (sizes, state)
    property var cat                    // the warp cat (Cats.js)

    // warp speed: streaks rushing out from the centre while warp goes 0 -> 1
    Item {
        anchors.fill: parent
        visible: warpScene.sky.warp > 0
        Rectangle { anchors.fill: parent; color: "#000000"; opacity: warpScene.sky.warp * 0.55 }
        Repeater {
            model: warpScene.sky.warp > 0 ? 280 : 0
            Rectangle {
                readonly property real angle: Math.random() * 2 * Math.PI
                readonly property real r0: 30 + Math.random() * 520
                readonly property real reach: Math.max(warpScene.sky.width, warpScene.sky.height)
                readonly property real k: 0.6 + Math.random() * 0.6        // fixed per streak
                readonly property real len: 120 + Math.random() * 260
                readonly property real r: r0 + warpScene.sky.warp * warpScene.sky.warp * reach * k
                width: 4 + warpScene.sky.warp * warpScene.sky.warp * len; height: 2.5; radius: 1.25
                x: warpScene.sky.width / 2 + Math.cos(angle) * r - width / 2
                y: warpScene.sky.height / 2 + Math.sin(angle) * r - 1
                rotation: angle * 180 / Math.PI
                opacity: Math.min(1, warpScene.sky.warp * 3) * (1 - Math.max(0, warpScene.sky.warp - 0.85) / 0.15)
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.7; color: Palette.mint }
                    GradientStop { position: 1.0; color: Palette.white }
                }
            }
        }
    }
    // a cat with spiralling, hypnotic eyes appears in the middle as the planets
    // blow up, then grows and turns with the starburst and fades out.
    // assets/warp-cat.webp: a dark cat face whose teal swirls build into a
    // vortex as it rears up and roars; dark parts see-through so it blends
    // into the stars. It plays once from the start each time, then holds on
    // the roar.
    AnimatedImage {
        id: warpCat
        z: 11
        readonly property real fadeIn: Math.max(Math.min(1, Math.max(0, warpScene.sky.blast - 0.45) * 2.5), Math.min(1, warpScene.sky.warp * 4))
        visible: opacity > 0.01
        source: "assets/" + warpScene.cat.file
        playing: visible
        onVisibleChanged: if (visible) currentFrame = 0
        smooth: true
        // the image is padded so the point between the eyes is its centre (and the screen's)
        height: warpScene.sky.height * warpScene.cat.size * (0.46 + 0.45 * warpScene.sky.warp * warpScene.sky.warp); width: height
        x: (warpScene.sky.width - width) / 2; y: (warpScene.sky.height - height) / 2
        rotation: -6 + warpScene.sky.warp * 18
        scale: 0.85 + 0.15 * fadeIn
        // a soft mint glow around its lines, so it melts into the starlight
        layer.enabled: visible
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Palette.mint
            shadowOpacity: 0.9
            shadowBlur: 1.0
            blurMax: 48
            shadowScale: 1.04
            shadowHorizontalOffset: 0; shadowVerticalOffset: 0
            brightness: 0.08
        }
        opacity: 0.8 * fadeIn * (1 - Math.max(0, warpScene.sky.warp - 0.85) / 0.15)    // see-through, and its dark parts are clear
    }

    // the spiral cat fires: as its spiral eyes peak, each eye flashes and
    // shoots a laser beam out toward the edge (jade left, amber right, like
    // the planet cats), sweeping a little, then fades out with the cat
    Item {
        id: warpLasers
        z: 12
        anchors.fill: parent
        readonly property real p: Math.max(0, Math.min(1, (warpScene.sky.warp - 0.55) / 0.3))     // 0 -> 1 as it fires
        readonly property real fade: 1 - Math.max(0, warpScene.sky.warp - 0.85) / 0.15
        visible: p > 0 && fade > 0 && warpCat.status === AnimatedImage.Ready   // no cat, no eye lasers
        // an eye's place on screen: (fx, fy) is its offset from the image's
        // centre (between the eyes) as a fraction of the image, turned and
        // scaled with the cat
        function eye(fx, fy) {
            let s = warpCat.height * warpCat.scale, a = warpCat.rotation * Math.PI / 180
            let dx = fx * s, dy = fy * s
            return Qt.point(warpScene.sky.width / 2 + dx * Math.cos(a) - dy * Math.sin(a),
                            warpScene.sky.height / 2 + dx * Math.sin(a) + dy * Math.cos(a))
        }
        Repeater {
            // one beam per eye (where the eyes are: Cats.js): jade to the
            // left, amber to the right, each sweeping a little
            model: [ { fx: warpScene.cat.eyes[0].x, fy: warpScene.cat.eyes[0].y, angle: 196, sweep: -14, col: Palette.jade, clear: Palette.jadeClear },
                     { fx: warpScene.cat.eyes[1].x, fy: warpScene.cat.eyes[1].y, angle: -16, sweep: 14, col: Palette.amber, clear: Palette.amberClear } ]
            Item {
                required property var modelData
                id: shot
                readonly property point at: warpLasers.eye(modelData.fx, modelData.fy)
                readonly property real thick: (6 + 12 * warpLasers.p) * warpScene.sky.catScale
                readonly property real len: Math.sqrt(warpLasers.p) * warpScene.sky.width * 0.75
                readonly property real turn: modelData.angle + modelData.sweep * warpLasers.p
                readonly property real show: warpLasers.fade * Math.min(1, warpLasers.p * 3)
                Rectangle {                     // a soft halo around the beam
                    x: shot.at.x; y: shot.at.y - height / 2
                    width: shot.len; height: shot.thick * 3.5; radius: height / 2
                    transformOrigin: Item.Left; rotation: shot.turn
                    opacity: shot.show * 0.3
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: shot.modelData.col }
                        GradientStop { position: 1.0; color: shot.modelData.clear }
                    }
                }
                Rectangle {                     // the beam: white-hot at the eye, then its colour, fading out
                    x: shot.at.x; y: shot.at.y - height / 2
                    width: shot.len; height: shot.thick; radius: height / 2
                    transformOrigin: Item.Left; rotation: shot.turn
                    opacity: shot.show
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#f2f6f9" }
                        GradientStop { position: 0.12; color: shot.modelData.col }
                        GradientStop { position: 1.0; color: shot.modelData.clear }
                    }
                }
                Image {                         // the flash in the eye
                    source: "assets/glow.png"
                    width: 150 * warpScene.sky.catScale * (0.5 + warpLasers.p); height: width
                    x: shot.at.x - width / 2; y: shot.at.y - height / 2
                    opacity: warpLasers.fade * Math.min(1, warpLasers.p * 4)
                }
            }
        }
    }
}

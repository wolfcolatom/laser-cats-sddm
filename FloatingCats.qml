// Laser Cats: the laser cats floating across the sky.
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import "Palette.js" as Palette

// the floating cats, in one layer so they can flash brighter on a key
// press and wash amber on a wrong password, all together
Item {
    id: catLayer
    property var sky                    // the Sky it belongs to (sizes, state)
    property var cats                   // the floating cats to show (Cats.js)
    anchors.fill: parent
    layer.enabled: sky.flash > 0.01 || sky.alarm > 0.01
    layer.effect: MultiEffect {
        brightness: catLayer.sky.flash * 0.25
        colorization: catLayer.sky.alarm * 0.75
        colorizationColor: Palette.amber
    }

    // single laser cats, floating right with the stars, one per lane,
    // starting spread around the loop so they pass rather than pile up; some
    // face the other way. Each bobs and turns a little; their lasers are
    // part of their animation.
    Repeater {
        model: catLayer.sky.running ? catLayer.cats : []         // (lanes, sizes, speeds: Cats.js)
        AnimatedImage {
            required property var modelData
            required property int index
            asynchronous: true          // load in the background: the lock shows at once
            id: floater
            source: "assets/" + modelData.file
            width: sourceSize.width * modelData.s * catLayer.sky.catScale; height: sourceSize.height * modelData.s * catLayer.sky.catScale
            smooth: true
            mirror: modelData.mirror
            opacity: 0.95
            property real t: 0          // seconds it has been floating
            FrameAnimation { running: true; onTriggered: floater.t += frameTime }
            readonly property real baseX: (modelData.start * (catLayer.sky.width + width) + floater.t * modelData.speed) % (catLayer.sky.width + width) - width
            readonly property real baseY: modelData.y * catLayer.sky.height + 9 * Math.sin(floater.t * 0.8 + modelData.frame)
            // the planets blowing up fling it off the screen: outward from
            // the middle, spinning (sky.blast 0 -> 1 over the explosion)
            readonly property real gust: Math.max(0, catLayer.sky.blast)          // steady, so you see them go
            readonly property real away: Math.atan2(baseY + height / 2 - catLayer.sky.height / 2, baseX + width / 2 - catLayer.sky.width / 2)
            readonly property real fling: gust * Math.max(catLayer.sky.width, catLayer.sky.height) * 1.4
            x: baseX + Math.cos(away) * fling
            y: baseY + Math.sin(away) * fling
            rotation: 8 * Math.sin(floater.t * 0.25 + modelData.frame) + gust * (index % 2 ? 540 : -540)
            onStatusChanged: if (status === AnimatedImage.Ready) currentFrame = modelData.frame % frameCount
        }
    }
}

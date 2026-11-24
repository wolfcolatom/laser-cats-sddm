.pragma library
// Everything about the cat pictures, in one place: which file, how big it is
// drawn, and where its paws and eyes are, so the lasers line up with them.
// Positions are in the picture's own pixels unless noted. There are two sets:
// the theme's own cats, and the classic GIF cats that get-cats.sh can make.
// Sky.qml picks one (`classic`) and hands the parts to the components.

var own = {
    // floating across the sky, one per lane. s: size (x the picture, on a
    // 1080 px tall screen); y: lane (fraction of the screen height); speed:
    // px a second; start: where in its loop it begins (0-1); frame: first
    // frame shown, so they don't move in step. Their lasers are in the art.
    floaters: [
        { file: "cat-front.webp",  s: 0.50, y: 0.06, speed: 31, start: 0.48, mirror: false, frame: 2 },
        { file: "cat-ginger.webp", s: 0.52, y: 0.55, speed: 21, start: 0.33, mirror: false, frame: 4 },
        { file: "cat-leap.webp",   s: 0.50, y: 0.82, speed: 30, start: 0.95, mirror: true,  frame: 6 }
    ],

    // rising from behind each planet (PlanetCat.qml's 460 x 520 box; the
    // planet is centred at 220, 330 with a 105 px radius). x, y: where the
    // picture's top-left goes in that box; scale: how big it is drawn.
    planetCat: {
        file: "planet-cat-roar.webp", animated: true,
        x: 71, y: 45, scale: 0.76,
        // its two paws (left, right) in each frame of its animation
        paws: [ [[61, 204], [337, 215]], [[58, 193], [339, 206]], [[57, 181], [337, 209]],
                [[54, 155], [348, 172]], [[46, 118], [349, 115]], [[42, 89], [346, 88]],
                [[48, 110], [344, 132]], [[57, 169], [340, 199]], [[60, 195], [333, 232]] ],
        // its lasers: which paw, where they land on the planet (degrees round
        // its rim, 0 = right, 90 = down), how far they sweep, how fast. Each
        // paw fires down its own side, so the beams miss its face.
        beams: [ { paw: 0, a: 200, sweep: 9, speed: 0.9 }, { paw: 0, a: 228, sweep: 8, speed: 1.3 },
                 { paw: 1, a: 340, sweep: 9, speed: 1.1 }, { paw: 1, a: 312, sweep: 8, speed: 0.8 } ],
        // a beam's half-width at the planet: base + length x growth
        beamSpread: { base: 5, growth: 0.05 }
    },

    // the face in the warp. size: its height at full warp (x the screen
    // height). The picture is padded so the screen's centre is between its
    // eyes; eyes: offset from there, as a fraction of the picture's size.
    warpCat: {
        file: "warp-cat.webp", size: 1.7,
        eyes: [ { x: -0.105, y: 0.049 }, { x: 0.136, y: 0.046 } ]
    }
}

var classic = {
    floaters: [
        { file: "cat-b-mint.webp", s: 0.55, y: 0.09, speed: 31, start: 0.48, mirror: true,  frame: 13 },
        { file: "cat-a-jade.webp", s: 0.58, y: 0.57, speed: 21, start: 0.33, mirror: false, frame: 4 },
        { file: "cat-a-jade.webp", s: 0.54, y: 0.84, speed: 30, start: 0.95, mirror: true,  frame: 24 }
    ],
    planetCat: {
        file: "planet-cat.png", animated: false,
        x: 60, y: 74, scale: 1,
        paws: [ [[16, 91], [299, 34]] ],
        beams: [ { paw: 0, a: 205, sweep: 16, speed: 0.9 }, { paw: 0, a: 312, sweep: 14, speed: 1.3 },
                 { paw: 1, a: 330, sweep: 16, speed: 1.1 }, { paw: 1, a: 228, sweep: 14, speed: 0.8 } ],
        beamSpread: { base: 7, growth: 0.06 }
    },
    warpCat: {
        file: "spiral-cat.webp", size: 1.6,
        eyes: [ { x: -0.1367, y: -0.0065 }, { x: 0.1628, y: 0.0 } ]
    }
}

#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 tom
# SPDX-License-Identifier: GPL-3.0-or-later
"""Star layers for the Laser Cats login screen: small horizontal pixel
streaks like the GIF's stars, at its density and speeds, in the theme's colours
(mint-white and grey-teal, some jade, amber where the GIF had red, soft gold,
a few amber stars with a halo). A still backdrop and three drifting layers,
1920x1080, tiling side to side, written as transparent PNGs.
Usage: make-stars.py OUTDIR"""
import random, subprocess, sys
import numpy as np

W, H = 1920, 1080
out = sys.argv[1]
rng = random.Random(7)

def hexc(s):
    s = s.lstrip("#"); return [int(s[i:i + 2], 16) for i in (0, 2, 4)]

def put(img, x, y, w, h, col, a=255):
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            px = img[yy % H, xx % W]
            if a >= px[3]:
                px[:3] = col; px[3] = a

def layer(name, n, widths, heights, palette, glows=0, dust=0, red=0, gold=0):
    img = np.zeros((H, W, 4), dtype=np.uint8)
    for _ in range(dust):                      # the faint green / brown speckle
        x, y = rng.randrange(W), rng.randrange(H)
        put(img, x, y, 1, 1, hexc(rng.choice(["#14241f", "#1a2c27", "#241c0c", "#2a200e"])), 200)
    for _ in range(n):
        col = hexc(rng.choice(palette))
        put(img, rng.randrange(W), rng.randrange(H), rng.choice(widths), rng.choice(heights), col)
    for count, pal in ((red, ["#a86b00", "#c27c10", "#dfa33a", "#b8740a"]),       # amber (was the GIF's red)
                       (gold, ["#c9b37e", "#d8c48e", "#bfa86e", "#e6d6a6"])):     # the theme soft gold
        for _ in range(count):                 # red and gold stars, like the GIF's
            put(img, rng.randrange(W), rng.randrange(H), rng.choice(widths), rng.choice(heights),
                hexc(rng.choice(pal)))
    for _ in range(glows):                     # the red-orange ones with a halo
        x, y = rng.randrange(W), rng.randrange(H)
        put(img, x - 3, y - 2, 8, 6, hexc("#5a3a06"), 110)     # amber halo
        put(img, x - 1, y - 1, 4, 3, hexc("#a86b00"), 220)
        put(img, x, y, 2, 1, hexc("#ffe2a8"))
    subprocess.run(["magick", "-size", f"{W}x{H}", "-depth", "8", "rgba:-",
                    f"PNG32:{out}/stars-{name}.png"], input=img.tobytes(), check=True)

# Measured from the GIF: ~80% of its bright stars stay still (a backdrop);
# the rest drift right in three speeds (sky/Starfield.qml: 16 / 37 / 68 px a second).
# Bright-pixel density overall ~2.3% (>60 of 255), ~1.6% (>120), ~0.5% (>180).
DIM = ["#5a6e6a", "#667a74", "#5e7270", "#6e8480", "#3f7a6e"]          # lum 90-140: grey-teal, a little jade
MIDC = ["#9aaea8", "#a8bcb6", "#b4c4be", "#7fb8ac", "#5fa898"]        # lum 150-205: misty mint, jade
FAINT = ["#4a5856", "#52605c", "#4e5e5a", "#3e6058", "#565c58"]        # lum 75-115: dim grey-teal
BRIGHT = ["#d9e0dc", "#e6eeea", "#f2f4f3", "#c4ece4"]                 # lum 230-255: the theme text white, mint
layer("still", 15000, [1, 2, 3], [1, 1, 2], FAINT * 3 + DIM * 3 + MIDC * 2 + BRIGHT,
      dust=60000, red=680, gold=400, glows=30)
layer("far", 2300, [1, 2], [1], DIM + MIDC, red=60, gold=30)
layer("mid", 900, [2, 3], [1], MIDC + BRIGHT, red=40, gold=25)
layer("near", 260, [3, 4, 5], [1, 2], BRIGHT, red=12, gold=10, glows=14)

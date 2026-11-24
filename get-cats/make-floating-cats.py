#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 tom
# SPDX-License-Identifier: GPL-3.0-or-later
"""Floating cats for Laser Cats, from "Major Lazer Cat" by Guldhart (GIPHY).
Cuts two of the GIF's three cats out one by one (the top cat, the big middle
one), keeping only their big shapes (the cat, its glow and lasers); the GIF's
small stars and dark sky are made see-through and the cut edge fades out.
Their lasers are recoloured: green -> jade, pink -> mint, keeping shading
and white-hot cores.
Usage: make-floating-cats.py SOURCE.gif OUTDIR
  -> OUTDIR/cat-a-jade.webp, OUTDIR/cat-b-mint.webp"""
import os, subprocess, sys, tempfile
import numpy as np

src, outdir = sys.argv[1], sys.argv[2]
W, H = 347, 400
# per cat: how much of the dim glow around it to keep, and where its bright
# parts start (the ghostly cat is only an outline: its dim grey-green haze
# would show as a grey patch, so it keeps none of it)
LOOK = {"a": (0.8, 0.10), "b": (0.8, 0.10), "c": (0.0, 0.17)}
CATS = {   # cut area (polygon in GIF pixels)
    "a": [(125, 0), (347, 0), (347, 240), (300, 240), (240, 165), (125, 165)],
    "b": [(0, 150), (225, 150), (238, 230), (238, 288), (178, 338), (118, 400), (0, 400)],
    "c": [(238, 262), (347, 262), (347, 400), (125, 400), (190, 335), (205, 292)],
}

# outputs: (file name, cat, laser colour or None)
OUTPUTS = [("cat-a-jade", "a", "#43af9c"), ("cat-b-mint", "b", "#8dd2c6")]
# the big cat's pink beams look like its fur by colour: mark them by place
PINK_BEAMS = [[(132, 212), (108, 208), (0, 232), (0, 290), (138, 238)],
              [(108, 226), (140, 232), (82, 400), (0, 400), (0, 382)]]

raw = subprocess.run(["magick", src, "-coalesce", "-depth", "8", "rgb:-"], capture_output=True, check=True).stdout
frames = np.frombuffer(raw, np.uint8).reshape(-1, H, W, 3).astype(np.float32) / 255


def magick_gray(args, img):
    """run an ImageMagick filter over a grayscale float image"""
    data = (np.clip(img, 0, 1) * 255).astype(np.uint8).tobytes()
    out = subprocess.run(["magick", "-size", f"{W}x{H}", "-depth", "8", "gray:-", *args, "-depth", "8", "gray:-"],
                         input=data, capture_output=True, check=True).stdout
    return np.frombuffer(out, np.uint8).reshape(H, W).astype(np.float32) / 255


def polygon_mask(points):
    draw = "polygon " + " ".join(f"{x},{y}" for x, y in points)
    m = magick_gray(["-fill", "black", "-colorize", "100", "-fill", "white", "-draw", draw, "-blur", "0x6"],
                    np.zeros((H, W), np.float32))
    return m


def hue_sat(f):
    mx, mn = f.max(axis=2), f.min(axis=2)
    d = np.maximum(mx - mn, 1e-6)
    r, g, b = f[..., 0], f[..., 1], f[..., 2]
    h = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60
    return h, (mx - mn) / np.maximum(mx, 1e-3), mx


# per colour: least saturation and brightness gain (the GIF's green and
# yellow beams are dark, so jade and amber need a lift to read as themselves)
TUNE = {"#43af9c": (0.8, 1.45), "#8dd2c6": (0.85, 1.05), "#dfa33a": (0.85, 1.5)}


def recolour(f, weight, colour):
    """beams to `colour`, keeping their shading; white cores stay white"""
    s_floor, gain = TUNE.get(colour, (0.55, 1.2))
    t = np.array([int(colour[i:i + 2], 16) for i in (1, 3, 5)], np.float32) / 255
    t = t / t.max()
    _, sat, v = hue_sat(f)
    s_eff = np.maximum(sat, s_floor)[..., None]
    v = np.minimum(1, v * gain)[..., None]
    new = v * (t * s_eff + (1 - s_eff))
    w = weight[..., None]
    return f * (1 - w) + new * w


def laser_weight(f, cat, beams):
    h, sat, v = hue_sat(f)
    bright = np.clip((v - 0.22) / 0.2, 0, 1)
    if cat == "b":      # pink beams, inside their outlines (cores are near white)
        pinkish = ((h < 35) | (h > 340) | (sat < 0.3)).astype(np.float32)
        return beams * pinkish * np.clip((v - 0.5) / 0.2, 0, 1)
    # green (top cat) / yellow-olive (ghost cat) beams: the only colours like that
    return ((h > 38) & (h < 150)).astype(np.float32) * np.clip((sat - 0.22) / 0.2, 0, 1) * bright


beam_area = np.maximum(*[polygon_mask(b) for b in PINK_BEAMS])

for out_name, name, colour in OUTPUTS:
    poly = CATS[name]
    glow_keep, floor = LOOK[name]
    area = polygon_mask(poly)
    xs = [x for x, _ in poly]; ys = [y for _, y in poly]
    x0, x1, y0, y1 = max(0, min(xs) - 4), min(W, max(xs) + 4), max(0, min(ys) - 4), min(H, max(ys) + 4)
    with tempfile.TemporaryDirectory() as tmp:
        names = []
        for i, f in enumerate(frames):
            if colour:
                f = recolour(f, laser_weight(f, name, beam_area), colour)
            lum = f.max(axis=2)
            key = np.clip((lum - floor) / 0.22, 0, 1)
            # big shapes only: drop components smaller than 150 px (the stars)
            solid = magick_gray(["-threshold", "50%", "-define", "connected-components:area-threshold=150",
                                 "-define", "connected-components:mean-color=true",
                                 "-connected-components", "8"], (key * area > 0.35).astype(np.float32))
            # also keep the dark glow next to the cat: grow the shapes a bit, soften
            keep = magick_gray(["-morphology", "Dilate", "Disk:2", "-blur", "0x1.5"], solid)
            glow = np.clip((lum - 0.06) / 0.20, 0, 1)
            alpha = np.maximum(key, glow * glow_keep) * keep * area
            # the GIF's red stars (deep red, unlike the pinkish cats and lasers)
            r, g = f[..., 0], f[..., 1]
            deep_red = np.clip((0.42 - g / np.maximum(r, 0.05)) / 0.12, 0, 1) * (r > 0.25)
            alpha = alpha * (1 - deep_red)
            rgba = np.dstack([f, alpha])[y0:y1, x0:x1]
            n = os.path.join(tmp, f"f{i:03d}.rgba")
            (rgba * 255).round().astype(np.uint8).tofile(n)
            names.append(n)
        cmd = ["magick", "-size", f"{x1 - x0}x{y1 - y0}", "-depth", "8", "-delay", "10", "-loop", "0"]
        cmd += [f"rgba:{n}" for n in names]
        cmd += ["-quality", "88", "-define", "webp:alpha-quality=100", os.path.join(outdir, f"{out_name}.webp")]
        subprocess.run(cmd, check=True)
    print(out_name, f"{x1 - x0}x{y1 - y0}")

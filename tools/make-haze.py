#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 tom
# SPDX-License-Identifier: GPL-3.0-or-later
"""Faint nebula haze for the Laser Cats sky, after the GIF's: soft clouds of
dark green, brown and a little deep red, mostly empty black between. Two
1920x1080 layers that tile side to side (they drift behind the stars).
And a jade nebula in the theme's own jade.
Usage: make-haze.py OUTDIR  -> OUTDIR/haze-{near,jade}.png"""
import subprocess, sys
import numpy as np

W, H = 1920, 1080
out = sys.argv[1]


def smooth_noise(rng, scale):
    """random field blurred to blobs about `scale` px across; periodic, so
    the layer tiles seamlessly"""
    f = np.fft.fft2(rng.standard_normal((H, W)))
    ky = np.fft.fftfreq(H)[:, None]; kx = np.fft.fftfreq(W)[None, :]
    f *= np.exp(-((kx ** 2 + ky ** 2) * (scale ** 2) * 9))
    n = np.fft.ifft2(f).real
    return (n - n.mean()) / n.std()


def layer(name, seed, colours, coverage, strength):
    rng = np.random.default_rng(seed)
    # wispy: ridged noise (thin bright ridges) over a few sizes, held in
    # by a slow field so clouds come and go across the sky
    ridges = sum(w * (1 - np.abs(smooth_noise(rng, sc)))
                 for sc, w in ((240, 1.0), (110, 0.6), (45, 0.35), (18, 0.2)))
    shape = ridges * np.clip(smooth_noise(rng, 500) * 0.7 + 0.6, 0, None)
    cut = np.quantile(shape, 1 - coverage)                  # only the top `coverage` becomes cloud
    a = np.clip((shape - cut) / (shape.max() - cut) * 1.6, 0, 1) ** 1.3 * strength
    # colour: blend between the palette by another slow field
    mix = (smooth_noise(rng, 600) + 2) / 4 * (len(colours) - 1)
    mix = np.clip(mix, 0, len(colours) - 1.001)
    lo = np.floor(mix).astype(int); t = (mix - lo)[..., None]
    pal = np.array(colours, dtype=np.float32)
    rgb = pal[lo] * (1 - t) + pal[lo + 1] * t
    # a little grain, like the GIF's dithered nebula
    a *= 0.45 + 1.1 * rng.random((H, W)) ** 2
    img = np.dstack([rgb, np.clip(a, 0, 1) * 255]).astype(np.uint8)
    subprocess.run(["magick", "-size", f"{W}x{H}", "-depth", "8", "rgba:-", f"PNG32:{out}/haze-{name}.png"],
                   input=img.tobytes(), check=True)


GREEN, MOSS, BROWN, RUST, DEEPRED = (40, 72, 34), (52, 66, 30), (70, 44, 24), (92, 40, 22), (110, 22, 18)
# the warm wisps in the theme amber (they were the GIF's rust red)
AMBER_D, AMBER_M, AMBER, AMBER_B = (70, 44, 6), (110, 70, 4), (168, 107, 0), (190, 128, 30)
layer("near", 23, [AMBER_D, AMBER_M, AMBER, AMBER_M], coverage=0.12, strength=0.24)
# the lock screen's nebula in the theme's own colours: mid jade and jade,
# mint where it's brightest, a touch of amber at its edges
def jade_nebula(name, seed):
    rng = np.random.default_rng(seed)
    ridges = sum(w * (1 - np.abs(smooth_noise(rng, sc)))
                 for sc, w in ((300, 1.0), (130, 0.6), (50, 0.35), (20, 0.2)))
    shape = ridges * np.clip(smooth_noise(rng, 560) * 0.7 + 0.65, 0, None)
    cut = np.quantile(shape, 1 - 0.18)
    d = np.clip((shape - cut) / (shape.max() - cut), 0, 1)       # 0 at the edge .. 1 in the core
    jade_mid, jade, mint, amber = (np.array(c, np.float32) for c in ((50, 143, 126), (67, 175, 156), (141, 210, 198), (168, 107, 0)))
    t = np.clip(d * 1.8, 0, 1)[..., None]
    rgb = jade_mid * (1 - t) + jade * t
    rgb = rgb * (1 - np.clip((d - 0.55) / 0.45, 0, 1)[..., None]) + mint * np.clip((d - 0.55) / 0.45, 0, 1)[..., None]
    edge = (np.clip(1 - d * 2.5, 0, 1) * np.clip(smooth_noise(rng, 400) * 0.8 + 0.2, 0, 1))[..., None]
    rgb = rgb * (1 - edge * 0.85) + amber * edge * 0.85
    a = np.clip(d * 1.7, 0, 1) ** 1.3 * 0.20
    a *= 0.55 + 0.9 * rng.random((H, W)) ** 2
    img = np.dstack([rgb, np.clip(a, 0, 1) * 255]).astype(np.uint8)
    subprocess.run(["magick", "-size", f"{W}x{H}", "-depth", "8", "rgba:-", f"PNG32:{out}/haze-{name}.png"],
                   input=img.tobytes(), check=True)


jade_nebula("jade", 41)

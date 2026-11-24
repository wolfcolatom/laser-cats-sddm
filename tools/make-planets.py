#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 tom
# SPDX-License-Identifier: GPL-3.0-or-later
"""Planets for the Laser Cats sky, in the theme's colours: a jade gas giant with
soft bands and a mint rim, an amber planet with a thin ring, a small mint
moon. Lit from the upper left, with a faint glow around each. Transparent
PNGs (drawn at 2x and scaled down, for smooth edges).
Usage: make-planets.py OUTDIR [--crater]  -> OUTDIR/planet-{jade,amber,moon}.png"""
import subprocess, sys
import numpy as np

out = sys.argv[1]
# the old look had a crater baked into the jade and Earth planets; the theme
# now chips them live, so by default they are drawn whole (--crater for the old look)
crater = "--crater" in sys.argv[2:]
rng = np.random.default_rng(9)


def C(s):
    return np.array([int(s[i:i + 2], 16) for i in (1, 3, 5)], np.float32) / 255


def noise1d(n, scale):
    f = np.fft.fft(rng.standard_normal(n))
    f *= np.exp(-(np.fft.fftfreq(n) * scale) ** 2 * 9)
    x = np.fft.ifft(f).real
    return (x - x.mean()) / x.std()


def noise2d(h, w, scale):
    f = np.fft.fft2(rng.standard_normal((h, w)))
    ky = np.fft.fftfreq(h)[:, None]; kx = np.fft.fftfreq(w)[None, :]
    f *= np.exp(-((kx ** 2 + ky ** 2) * scale ** 2 * 9))
    x = np.fft.ifft2(f).real
    return (x - x.mean()) / x.std()


def planet(name, size, dark, mid, light, rim, bands=0.0, ring=None, tilt=0.0, glow=0.35, burning=False):
    S = size * 2                                   # draw at 2x
    pad = int(S * (0.9 if ring else 0.35))
    N = S + 2 * pad
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    x = (xx - N / 2) / (S / 2); y = (yy - N / 2) / (S / 2)
    r2 = x * x + y * y
    inside = r2 <= 1
    z = np.sqrt(np.clip(1 - r2, 0, 1))
    # light from the upper left, a little toward the viewer
    L = np.array([-0.55, -0.6, 0.58]); L /= np.linalg.norm(L)
    lam = np.clip(x * L[0] + y * L[1] + z * L[2], 0, 1)
    shade = lam ** 0.9
    # bands across the planet (rotated by tilt), wobbling
    yr = y * np.cos(tilt) - x * np.sin(tilt)
    band = noise1d(N, N / 9)[np.clip(((yr + 1.5) / 3 * N).astype(int), 0, N - 1)]
    band = band + 0.4 * noise2d(N, N, N / 14)
    t = np.clip(0.5 + bands * 0.35 * band, 0, 1)[..., None]
    base = dark * (1 - t) + mid * t
    col = base * (0.25 + 0.75 * shade[..., None]) + light * (shade ** 6)[..., None] * 0.35
    # rim light on the lit edge, and a soft dark side
    rimv = np.clip((r2 - 0.72) / 0.28, 0, 1) ** 2 * np.clip(lam * 1.6, 0, 1)
    col = col + rim * rimv[..., None] * 0.55
    a = inside.astype(np.float32)
    # glow (atmosphere) just outside
    d = np.sqrt(r2)
    halo = np.clip(1 - (d - 1) / 0.28, 0, 1) ** 2.2 * (d > 1) * glow
    halo_col = rim
    if burning:
        # being blasted by laser cats: a jagged crater bitten out of the upper
        # right edge with molten sides, glowing lava cracks (brightest near the
        # top and the crater), scorched dark patches; the atmosphere glows hot
        amber, gold, hot = C("#a86b00"), C("#dfa33a"), C("#ffe2a8")
        ca = np.deg2rad(-50)
        ccx, ccy = 0.93 * np.cos(ca), 0.93 * np.sin(ca)
        dc = np.sqrt((x - ccx) ** 2 + (y - ccy) ** 2)
        ang = np.arctan2(y - ccy, x - ccx)
        jag = 1 + 0.10 * np.sin(ang * 3 + 1.3) + 0.07 * np.sin(ang * 5 + 0.4) + 0.05 * np.sin(ang * 11) + 0.16 * noise2d(N, N, N / 22)
        rb = 0.34 * jag
        bite = (dc < rb) if crater else np.zeros_like(dc, bool)
        near = np.clip(1 - (dc - rb) / 0.75, 0, 1)                    # 1 at the crater, fading away
        n1 = noise2d(N, N, N / 18); n2 = noise2d(N, N, N / 42)
        crack = np.clip(1 - np.abs(n1) / 0.13, 0, 1) ** 1.6 + 0.7 * np.clip(1 - np.abs(n2) / 0.09, 0, 1) ** 1.6
        where = np.clip(0.35 + 0.9 * np.clip(-y + 0.35, 0, 1) + 1.0 * near, 0, 1.6)
        heat = np.clip(crack * where, 0, 1.4)
        scorch = np.clip(0.7 * near + 0.55 * np.clip(noise2d(N, N, N / 8) * 0.5 + 0.35, 0, 1) * np.clip(-y + 0.5, 0, 1), 0, 0.85)
        col = col * (1 - scorch[..., None])
        col = col + (amber * 1.0 + gold * 0.6 * heat[..., None]) * heat[..., None] * 1.0 \
                  + hot * (np.clip(heat - 0.9, 0, 1) * 1.5)[..., None]
        molten = np.clip(1 - (dc - rb) / 0.07, 0, 1) * (~bite) * crater  # the crater's glowing lip
        col = col * (1 - molten[..., None] * 0.7) + (gold * 0.6 + hot * 0.4) * molten[..., None]
        inside = inside & ~bite
        # the atmosphere: hot amber on the crater side, jade elsewhere
        hotside = np.clip(1 - np.sqrt((x - ccx) ** 2 + (y - ccy) ** 2) / 1.1, 0, 1)[..., None]
        halo_col = rim * (1 - hotside) + gold * hotside
        halo = np.maximum(halo, np.clip(1 - dc / 0.6, 0, 1) ** 2 * 0.55 * bite)   # glow inside the crater
        halo = halo * 1.3
    rgb = np.where(inside[..., None], col, halo_col)
    alpha = np.where(inside, 1.0, halo)
    if ring:
        rc, rw, ra = ring
        # an ellipse ring, tilted; drawn behind the planet's upper half, in front of the lower
        rx = x * np.cos(tilt) + y * np.sin(tilt)
        ry = (-x * np.sin(tilt) + y * np.cos(tilt)) / 0.28
        rd = np.sqrt(rx * rx + ry * ry)
        ringa = np.clip(1 - np.abs(rd - rc) / rw, 0, 1) ** 1.5 * ra
        ringa *= 0.75 + 0.25 * np.sin(rd * 60)                     # fine ringlets
        front = (ry > 0) | ~inside
        ringcol = light * 0.9
        ra2 = ringa * front
        rgb = rgb * (1 - ra2[..., None]) + ringcol * ra2[..., None]
        alpha = np.maximum(alpha, ra2)
    img = (np.dstack([np.clip(rgb, 0, 1), np.clip(alpha, 0, 1)]) * 255).astype(np.uint8)
    subprocess.run(["magick", "-size", f"{N}x{N}", "-depth", "8", "rgba:-", "-filter", "Lanczos",
                    "-resize", "50%", f"PNG32:{out}/planet-{name}.png"], input=img.tobytes(), check=True)


planet("jade", 210, C("#14403a"), C("#328f7e"), C("#8dd2c6"), C("#8dd2c6"), bands=1.0, tilt=0.35, glow=0.30,
       burning=True)    # the laser cat's planet: on fire
planet("amber", 96, C("#3a2404"), C("#a86b00"), C("#dfa33a"), C("#dfa33a"), bands=0.7, tilt=-0.4,
       ring=(1.65, 0.22, 0.75), glow=0.22)
planet("moon", 46, C("#2a3a38"), C("#7fa8a0"), C("#d9e0dc"), C("#8dd2c6"), bands=0.25, glow=0.18)


# fragments blown off the burning planet: jagged jade rock with hot amber
# edges, and soft textures for its fire (a glow) and smoke
def fragment(name, size, seed):
    r_ = np.random.default_rng(seed)
    S = size * 4
    N = S + 8
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    x = (xx - N / 2) / (S / 2); y = (yy - N / 2) / (S / 2)
    ang = np.arctan2(y, x); d = np.sqrt(x * x + y * y)
    k = r_.integers(5, 8)
    edge = 0.75 + sum(r_.uniform(0.04, 0.14) * np.cos(ang * j + r_.uniform(0, 6.3)) for j in range(1, k))
    inside = d < edge
    lit = np.clip(0.55 - 0.45 * (x + y) / 1.4, 0.2, 1)[..., None]
    rock = C("#1c4a42") * (1 - 0.3 * (d / edge)[..., None]) * lit + C("#328f7e") * 0.25 * lit
    hot = np.clip(1 - (edge - d) / 0.22, 0, 1)[..., None] * (x[..., None] - y[..., None] > -0.2)
    rgb = rock * (1 - hot) + (C("#dfa33a") * 0.8 + C("#ffe2a8") * 0.2) * hot
    a = inside.astype(np.float32)
    img = (np.dstack([np.clip(rgb, 0, 1), a]) * 255).astype(np.uint8)
    subprocess.run(["magick", "-size", f"{N}x{N}", "-depth", "8", "rgba:-", "-filter", "Lanczos",
                    "-resize", "25%", f"PNG32:{out}/rock-{name}.png"], input=img.tobytes(), check=True)


def soft(name, size, falloff, grain=0.0):
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    d = np.sqrt((xx - size / 2 + 0.5) ** 2 + (yy - size / 2 + 0.5) ** 2) / (size / 2)
    a = np.clip(1 - d, 0, 1) ** falloff
    if grain:
        a *= 1 - grain + grain * np.clip(noise2d(size, size, size / 6) * 0.5 + 0.5, 0, 1)
    img = np.dstack([np.ones((size, size, 3)), a]) * 255
    subprocess.run(["magick", "-size", f"{size}x{size}", "-depth", "8", "rgba:-", f"PNG32:{out}/{name}.png"],
                   input=img.astype(np.uint8).tobytes(), check=True)


for i, (sz, sd) in enumerate(((24, 3), (17, 8), (12, 13), (9, 21)), 1):
    fragment(str(i), sz, sd)
soft("glow", 32, 1.8)
soft("smoke", 64, 1.4, grain=0.5)


# an Earth-style planet for the second laser cat: blue oceans, green and tan
# continents, ice caps, swirling clouds, a blue atmosphere; burning and
# cratered on the side its lasers hit, like the jade one
def earth(name, size):
    S = size * 2
    pad = int(S * 0.35)
    N = S + 2 * pad
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    x = (xx - N / 2) / (S / 2); y = (yy - N / 2) / (S / 2)
    r2 = x * x + y * y
    inside = r2 <= 1
    z = np.sqrt(np.clip(1 - r2, 0, 1))
    L = np.array([-0.55, -0.6, 0.58]); L /= np.linalg.norm(L)
    lam = np.clip(x * L[0] + y * L[1] + z * L[2], 0, 1)
    shade = (0.18 + 0.82 * lam ** 0.9)[..., None]
    # map the sphere a little so continents curve with it
    px, py = x / np.maximum(z, 0.25) * 0.6, y / np.maximum(z, 0.25) * 0.6
    land_n = noise2d(N, N, N / 6) + 0.5 * noise2d(N, N, N / 14) + 0.25 * noise2d(N, N, N / 30)
    land = np.clip((land_n - 0.75) / 0.12, 0, 1)        # mostly ocean
    ocean = C("#1b4f86") * (1 - 0.35 * np.clip(-land_n, 0, 1))[..., None] + C("#2a74b8") * 0.15
    green, tan = C("#3f7f3c"), C("#a8925a")
    dry = np.clip(noise2d(N, N, N / 10) * 0.6 + 0.2, 0, 1)[..., None]
    ground = green * (1 - dry) + tan * dry
    col = ocean * (1 - land[..., None]) + ground * land[..., None]
    ice = np.clip((np.abs(y) - 0.78) / 0.08, 0, 1)[..., None]
    col = col * (1 - ice) + C("#e8f0f4") * ice
    clouds = np.clip((noise2d(N, N, N / 9) + 0.6 * noise2d(N, N, N / 22) - 0.55) / 0.5, 0, 1)[..., None] * 0.8
    col = col * (1 - clouds) + C("#f2f4f3") * clouds
    col = col * shade + C("#ffffff") * (lam ** 8)[..., None] * 0.25
    # burning like the jade planet: crater upper right, lava cracks, scorch
    amber, gold, hot = C("#a86b00"), C("#dfa33a"), C("#ffe2a8")
    ca = np.deg2rad(-50)
    ccx, ccy = 0.93 * np.cos(ca), 0.93 * np.sin(ca)
    dc = np.sqrt((x - ccx) ** 2 + (y - ccy) ** 2)
    ang = np.arctan2(y - ccy, x - ccx)
    rb = 0.34 * (1 + 0.10 * np.sin(ang * 3 + 2.1) + 0.07 * np.sin(ang * 5 + 0.9) + 0.05 * np.sin(ang * 11) + 0.16 * noise2d(N, N, N / 22))
    bite = (dc < rb) if crater else np.zeros_like(dc, bool)
    near = np.clip(1 - (dc - rb) / 0.75, 0, 1)
    n1 = noise2d(N, N, N / 18); n2 = noise2d(N, N, N / 42)
    crack = np.clip(1 - np.abs(n1) / 0.13, 0, 1) ** 1.6 + 0.7 * np.clip(1 - np.abs(n2) / 0.09, 0, 1) ** 1.6
    heat = np.clip(crack * np.clip(0.05 + 0.25 * np.clip(-y + 0.2, 0, 1) + 1.3 * near ** 1.5, 0, 1.6), 0, 1.4)   # burning mostly round the crater
    scorch = np.clip(0.75 * near ** 1.3, 0, 0.85)
    col = col * (1 - scorch[..., None])
    col = col + (amber + gold * 0.6 * heat[..., None]) * heat[..., None] + hot * (np.clip(heat - 0.9, 0, 1) * 1.5)[..., None]
    molten = np.clip(1 - (dc - rb) / 0.07, 0, 1) * (~bite) * crater
    col = col * (1 - molten[..., None] * 0.7) + (gold * 0.6 + hot * 0.4) * molten[..., None]
    inside = inside & ~bite
    # atmosphere: blue, hot amber on the crater side
    d = np.sqrt(r2)
    rim = np.clip((r2 - 0.75) / 0.25, 0, 1) ** 2 * np.clip(lam * 1.6, 0, 1)
    col = col + C("#7fb8ff") * rim[..., None] * 0.45
    halo = np.clip(1 - (d - 1) / 0.28, 0, 1) ** 2.2 * (d > 1) * 0.42
    hotside = np.clip(1 - dc / 1.1, 0, 1)[..., None]
    halo_col = C("#6aa8ff") * (1 - hotside) + gold * hotside
    halo = np.maximum(halo, np.clip(1 - dc / 0.6, 0, 1) ** 2 * 0.55 * bite)
    rgb = np.where(inside[..., None], col, halo_col)
    alpha = np.where(inside, 1.0, halo)
    img = (np.dstack([np.clip(rgb, 0, 1), np.clip(alpha, 0, 1)]) * 255).astype(np.uint8)
    subprocess.run(["magick", "-size", f"{N}x{N}", "-depth", "8", "rgba:-", "-filter", "Lanczos",
                    "-resize", "50%", f"PNG32:{out}/planet-{name}.png"], input=img.tobytes(), check=True)


earth("earth", 210)

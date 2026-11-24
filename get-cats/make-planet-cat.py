#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 tom
# SPDX-License-Identifier: GPL-3.0-or-later
"""The laser-hands cat for Laser Cats ("Cat shoots beams over a city", GIPHY,
creator unknown), cut out on its own: it rises from behind the planets.
The cat doesn't move in the GIF (only its sky and beams change), so it is
taken from the middle value of each pixel across the frames, which drops
the beams that cross it, then cut out along its black sticker outline. The
city is left out; the bottom of the cat fades, behind the planet anyway.
Holes inside the cat (its ears) are then filled so no stars show through.
Its laser beams are drawn by sky/Beam.qml.
Usage: make-planet-cat.py SOURCE.gif OUT.png"""
import subprocess, sys
from collections import deque
import numpy as np

src, out = sys.argv[1], sys.argv[2]
W, H = 480, 400
raw = subprocess.run(["magick", src, "-coalesce", "-depth", "8", "rgb:-"], capture_output=True, check=True).stdout
F = np.frombuffer(raw, np.uint8).reshape(-1, H, W, 3).astype(np.float32) / 255
cat = np.median(F, axis=0)
lum = cat.max(axis=2)

CUT = 262                          # below this the city hid the cat (and the planet hides it now)
# the cat's outline, traced once by hand (the cat never moves in the GIF)
TRACE = [(345,100),(440,160),(540,150),(600,75),(640,200),(660,300),(690,380),(760,410),(840,330),
         (895,215),(960,120),(1015,130),(1020,250),(950,340),(880,440),(820,520),(790,560),(760,620),
         (440,700),(400,690),(300,560),(240,450),(200,430),(120,440),(85,390),(90,320),(140,295),
         (180,300),(230,370),(250,390),(370,500),(380,420),(360,300),(350,200)]
poly = [(x / 3, y / 3 + 40) for x, y in TRACE]
draw = "polygon " + " ".join(f"{x:.1f},{y:.1f}" for x, y in poly)
def mask(args):
    o = subprocess.run(["magick", "-size", f"{W}x{H}", "xc:black", "-fill", "white", "-draw", draw, *args,
                        "-depth", "8", "gray:-"], capture_output=True, check=True).stdout
    return np.frombuffer(o, np.uint8).reshape(H, W) > 127
grown = mask(["-morphology", "Dilate", "Disk:7"])
core = mask(["-morphology", "Erode", "Disk:7"])
# in the band around the traced edge, drop the sky (light, greyish lavender
# or the nebula) and keep the cat's fur and its black outline
mx, mn = cat.max(axis=2), cat.min(axis=2)
sat = (mx - mn) / np.maximum(mx, 1e-3)
skyish = ((lum > 0.42) & (sat < 0.22)) | ((lum > 0.25) & (cat[..., 2] > cat[..., 0] + 0.02))
inside = grown & (core | ~skyish)
# the city's red glow along the bottom
r, g = cat[..., 0], cat[..., 1]
inside &= ~((np.arange(H)[:, None] > 215) & (r > 0.45) & (g < r * 0.6))
# drop stray specks: keep only the big piece
seen = np.zeros((H, W), bool); best = []
for sy, sx in zip(*np.where(inside)):
    if seen[sy, sx]:
        continue
    comp = []; q = deque([(sy, sx)]); seen[sy, sx] = True
    while q:
        y, x = q.popleft(); comp.append((y, x))
        for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
            if 0 <= ny < H and 0 <= nx < W and inside[ny, nx] and not seen[ny, nx]:
                seen[ny, nx] = True; q.append((ny, nx))
    if len(comp) > len(best):
        best = comp
inside = np.zeros((H, W), bool)
yy_, xx_ = zip(*best); inside[list(yy_), list(xx_)] = True
inside[CUT:, :] = False
# keep the black outline too (it's the sticker look), soften the edge
m = (np.clip(inside.astype(np.float32), 0, 1) * 255).astype(np.uint8)
soft = subprocess.run(["magick", "-size", f"{W}x{H}", "-depth", "8", "gray:-", "-morphology", "Erode", "Disk:0.5",
                       "-blur", "0x0.8", "-depth", "8", "gray:-"], input=m.tobytes(), capture_output=True, check=True).stdout
alpha = np.frombuffer(soft, np.uint8).reshape(H, W).astype(np.float32) / 255
fade = np.clip((CUT - np.arange(H)) / 40, 0, 1)[:, None]        # the bottom fades out
alpha = alpha * fade
# traces of the GIF's beams left on the paws and arm: tint them jade, so
# they read as the start of the new beams
h = np.where(mx == cat[..., 0], ((cat[..., 1] - cat[..., 2]) / np.maximum(mx - mn, 1e-6)) % 6,
             np.where(mx == cat[..., 1], (cat[..., 2] - cat[..., 0]) / np.maximum(mx - mn, 1e-6) + 2,
                      (cat[..., 0] - cat[..., 1]) / np.maximum(mx - mn, 1e-6) + 4)) * 60
beamish = ((h > 70) & (h < 320) & (sat > 0.25) & (lum > 0.3)).astype(np.float32)[..., None]
jade = np.array([0.263, 0.686, 0.612], np.float32) / 0.686
cat = cat * (1 - beamish) + (lum[..., None] * jade).clip(0, 1) * beamish
ys, xs = np.where(alpha > 0.05)
y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
rgba = np.dstack([cat, alpha])[y0:y1, x0:x1]
# seal the ears: fill any holes inside the cat's shape (closed a little
# first), keeping the faded bottom edge
h2, w2 = rgba.shape[:2]
A = rgba[..., 3]
def mgray(args, img):
    o = subprocess.run(["magick", "-size", f"{w2}x{h2}", "-depth", "8", "gray:-", *args, "-depth", "8", "gray:-"],
                       input=(np.clip(img, 0, 1) * 255).astype(np.uint8).tobytes(), capture_output=True, check=True).stdout
    return np.frombuffer(o, np.uint8).reshape(h2, w2).astype(np.float32) / 255
closed = mgray(["-morphology", "Close", "Disk:3"], (A > 0.5).astype(np.float32))
outside = mgray(["-bordercolor", "black", "-border", "1", "-fill", "gray(50%)",
                 "-draw", "color 0,0 floodfill", "-shave", "1x1"], closed)
solid = ((outside < 0.4) | (outside > 0.6)).astype(np.float32)
rgba = rgba.copy()
rgba[..., 3] = np.maximum(A, solid * A.max(axis=1, keepdims=True))
subprocess.run(["magick", "-size", f"{x1 - x0}x{y1 - y0}", "-depth", "8", "rgba:-", f"PNG32:{out}"],
               input=(rgba * 255).round().astype(np.uint8).tobytes(), check=True)

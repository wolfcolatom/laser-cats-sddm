# Laser Cats art tools

The scripts that drew the theme's own art. Each writes PNGs into the folder
you give it. They need python3 with numpy and ImageMagick 7 (`magick`).

| Script | Makes |
|---|---|
| `make-stars.py OUTDIR` | `stars-still.png`, `stars-far.png`, `stars-mid.png`, `stars-near.png` |
| `make-haze.py OUTDIR` | `haze-jade.png`, `haze-near.png` |
| `make-planets.py OUTDIR [--crater]` | `planet-jade.png`, `planet-earth.png`, `planet-amber.png`, `planet-moon.png`, `rock-1..4.png`, `glow.png`, `smoke.png` |

The stars, nebula, amber planet, moon, rocks, glow and smoke come out
pixel-for-pixel the same as the files in `assets/`.

The jade and Earth planets in `assets/` were finished by hand after the
script drew them (the burnt patch on their upper right was reworked when
the lasers started chipping the planets live), so the script draws them
close to, but not exactly like, the shipped files. `--crater` draws the
original look with a crater baked in. For those two, and for the files with
no script (`flame.png`, `text-shade.png`, `corner-shade.png`, and the two
SVG icons), the files in `assets/` are the source.

The cats are pictures made for the theme; `get-cats/` holds the scripts
for the optional classic cats (see the main README).

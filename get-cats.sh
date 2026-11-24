#!/usr/bin/env bash
# Laser Cats: swap in the classic GIF cats (optional).
#
# The theme comes with its own cats. Before version 1.4 it used cats cut out
# of GIFs on GIPHY instead; their artists haven't licensed them for sharing,
# so they aren't in this package. This script downloads those GIFs from
# GIPHY on your own computer and makes the classic cats from them (cut out,
# recoloured, see-through), for your own use. The theme notices them and
# switches to the classic look by itself. --remove switches back.
#
#   Floating cats:   "Major Lazer Cat" by Guldhart (@atinum on GIPHY)
#   Laser-hands cat: "Cat shoots beams over a city" (GIPHY, creator unknown)
#   Spiral cat:      "Psychedelic cat dreams" by Electric Catnip (@ElectricCatnip)
#
# Needs: curl, ImageMagick 7 (magick), python3 with numpy.
#   Arch: sudo pacman -S --needed curl imagemagick python-numpy
#   Debian/Ubuntu: sudo apt install curl imagemagick python3-numpy  (needs IM 7)
#   Fedora: sudo dnf install curl ImageMagick python3-numpy
#
# Usage: bash get-cats.sh [THEME_DIR]
#   THEME_DIR defaults to the folder this script is in (for example
#   /usr/share/sddm/themes/laser-cats). If that folder belongs to root, the
#   cats are made as you and only the final copy asks for sudo.
#   bash get-cats.sh --remove [THEME_DIR]   takes the cats out again.
set -euo pipefail

remove=0
if [ "${1:-}" = "--remove" ]; then remove=1; shift; fi
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
theme=$(cd "${1:-$here}" && pwd)
[ -f "$theme/Sky.qml" ] && [ -d "$theme/assets" ] || { echo "Not a Laser Cats theme folder: $theme" >&2; exit 1; }
tools="$here/get-cats"
CATS=(cat-a-jade.webp cat-b-mint.webp planet-cat.png spiral-cat.webp)

as_owner() {        # run a command with sudo only if the theme folder isn't ours
    if [ -w "$theme/assets" ]; then "$@"; else echo "(needs sudo to write to $theme)"; sudo "$@"; fi
}

if [ $remove = 1 ]; then
    for f in "${CATS[@]}"; do as_owner rm -f "$theme/assets/$f"; done
    echo "Classic cats removed from $theme: back to the theme's own cats."
    exit 0
fi

for c in curl magick python3; do
    command -v $c >/dev/null || { echo "Missing: $c (see the top of this script for what to install)" >&2; exit 1; }
done
python3 -c "import numpy" 2>/dev/null || { echo "Missing: numpy for python3 (python-numpy / python3-numpy)" >&2; exit 1; }

work=$(mktemp -d "${TMPDIR:-/tmp}/laser-cats.XXXXXX")
trap 'rm -rf -- "$work"' EXIT
mkdir "$work/out"

# GIPHY id, file name, and the checksum of the GIF the theme was made from
# (if GIPHY ever changes a file, the cut-outs could land in the wrong place)
GIFS=(
    "ArAgo5dU2z2xO major-lazer-cat.gif b3a53761cbdb"
    "y9hjvnO2bwJbO city-cat.gif 077e4d0de9ae"
    "l4FGoTd3NjBCmnZyE psychedelic-cat-dreams.gif 8da45a9a5d62"
)
for g in "${GIFS[@]}"; do
    read -r id name sum <<<"$g"
    echo "Downloading $name from GIPHY..."
    curl -sfL --retry 2 --max-time 120 "https://media.giphy.com/media/$id/giphy.gif" -o "$work/$name" \
        || { echo "Couldn't download https://giphy.com/gifs/$id" >&2; exit 1; }
    got=$(sha256sum < "$work/$name" | cut -c1-12)
    if [ "$got" != "$sum" ]; then
        echo "Warning: $name isn't the same file the theme was made from (GIPHY may have changed it)." >&2
        echo "         The cut-outs may not line up. Carrying on." >&2
    fi
done

echo "Making the floating cats (about 20 s)..."
python3 -I "$tools/make-floating-cats.py" "$work/major-lazer-cat.gif" "$work/out" >/dev/null

echo "Making the laser-hands cat..."
python3 -I "$tools/make-planet-cat.py" "$work/city-cat.gif" "$work/out/planet-cat.png"

echo "Making the spiral cat..."
# a stretch of 25 frames (every 2nd from frame 113), placed so the eyes sit in
# the middle of a 768 px square; dark parts see-through, edges faded by a mask
s="$work/spiral"; mkdir -p "$s/gf" "$s/nf"
magick "$work/psychedelic-cat-dreams.gif" -coalesce "$s/gf/%03d.png"
magick -size 768x768 xc:black -fill white -draw "ellipse 392,500 215,215 0,360" -blur 0x30 "$s/oval.png"
magick -size 768x768 xc:black -fill white -draw "rectangle 214,302 642,730" -blur 0x16 "$s/inset.png"
magick -size 768x768 xc:white -fill black -draw "rectangle 578,0 767,767" -blur 0x14 "$s/right.png"
magick -size 768x768 xc:white -fill black -draw "ellipse 552,640 58,52 0,360" -blur 0x18 "$s/jaw.png"
magick "$s/oval.png" "$s/inset.png" -compose multiply -composite "$s/right.png" -compose multiply -composite \
    "$s/jaw.png" -compose multiply -composite "$s/mask.png"
args=()
for k in $(seq 0 24); do
    src=$(printf "%s/gf/%03d.png" "$s" $((113 + 2 * k))); out=$(printf "%s/nf/%02d.png" "$s" $k)
    [ -f "$src" ] || { echo "The spiral GIF has fewer frames than expected." >&2; exit 1; }
    magick -size 768x768 xc:none \( "$src" -alpha off \) -geometry +188+276 -composite -alpha off "$s/fr.png"
    magick "$s/fr.png" -colorspace gray -level 13%,48% "$s/mask.png" -compose multiply -composite "$s/al.png"
    magick "$s/fr.png" "$s/al.png" -alpha off -compose CopyOpacity -composite "$out"
    if [ $k -lt 24 ]; then args+=(-delay 6 "$out"); else args+=(-delay 600 "$out"); fi
done
magick "${args[@]}" -background none -loop 0 -define webp:lossless=false -quality 82 \
    -define webp:alpha-quality=90 "$work/out/spiral-cat.webp"
# a clear (not white) animation background, so Qt shows it see-through
python3 -I - "$work/out/spiral-cat.webp" <<'EOF'
import struct, sys
p = sys.argv[1]; d = bytearray(open(p, 'rb').read()); i = 12
while i + 8 <= len(d):
    t = bytes(d[i:i + 4]); n = struct.unpack('<I', d[i + 4:i + 8])[0]
    if t == b'ANIM': d[i + 8:i + 12] = b'\0\0\0\0'
    i += 8 + n + (n & 1)
open(p, 'wb').write(d)
EOF

for f in "${CATS[@]}"; do [ -s "$work/out/$f" ] || { echo "Something went wrong: $f wasn't made." >&2; exit 1; }; done
chmod 644 "$work/out/"*
as_owner cp "${CATS[@]/#/$work/out/}" "$theme/assets/"
echo
echo "Done: the classic cats are in $theme/assets and the theme will use them."
echo "They're made from the artists' GIFs for your own use; please don't share them."

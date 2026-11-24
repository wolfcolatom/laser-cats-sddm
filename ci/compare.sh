#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 tom
# SPDX-License-Identifier: GPL-3.0-or-later
# Visual regression: renders the frozen sky (ci/visual.qml) and compares
# each picture with the approved one in ci/golden/. The pictures are exactly
# repeatable, so THRESHOLD (root-mean-square, 0-1) only allows for rounding:
# one changed word on the screen is several times over it. Differences are
# written to OUTDIR as *-diff.png. To approve new pictures after an
# intended change:  ci/compare.sh --update
# Needs: qml (Qt 6), ImageMagick 7.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
out=${OUTDIR:-$(mktemp -d)}
threshold=${THRESHOLD:-0.002}
qtbin=${QTBIN:-/usr/lib/qt6/bin}
mkdir -p "$out"

# the same font, language and time zone everywhere: only the bundled Space
# Grotesk (ci/fonts.conf), the C locale, UTC
FONTCONFIG_FILE="$here/fonts.conf" LC_ALL=C.UTF-8 TZ=UTC \
QT_QPA_PLATFORM=offscreen QT_FORCE_STDERR_LOGGING=1 \
    timeout 180 "$qtbin/qml" "$here/visual.qml" -- "$out"

if [ "${1:-}" = "--update" ]; then
    for f in "$out"/*.png; do magick "$f" -strip "PNG24:$here/golden/$(basename "$f")"; done
    echo "Approved new pictures in ci/golden/"
    exit 0
fi

fail=0
for golden in "$here"/golden/*.png; do
    name=$(basename "$golden" .png)
    got="$out/$name.png"
    [ -f "$got" ] || { echo "FAIL $name: not rendered"; fail=1; continue; }
    rmse=$(magick compare -metric RMSE "$golden" "$got" "$out/$name-diff.png" 2>&1 >/dev/null | sed -E 's/.*\((.*)\).*/\1/' || true)
    if awk -v r="$rmse" -v t="$threshold" 'BEGIN { exit !(r <= t) }'; then
        echo "ok   $name (difference $rmse)"
    else
        echo "FAIL $name: difference $rmse > $threshold (see $out/$name-diff.png)"; fail=1
    fi
done
exit $fail

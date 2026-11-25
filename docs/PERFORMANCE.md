# Performance

Measured with `ci/perf.qml`: the login screen full screen on real
hardware, frame times recorded idle (10 s), while typing, and through the
explosion and warp.

| Machine | Idle | Typing | Explosion and warp |
|---|---|---|---|
| Intel i5-8350U, UHD Graphics 620, 1920x1080 at 125% | 60 fps, 95% of frames under 18 ms, worst 26 ms | 60 fps, worst 24-50 ms | 60 fps, 95% under 21 ms, worst 33 ms |

That's a 2018 laptop's built-in graphics, so most machines should hold
60 fps. The first key press used to stutter (about 100 ms) while Qt set up
the flash effect; the theme now prepares it at start.

Without GPU acceleration (Qt's software renderer) the animation can't run
smoothly, so with `calm=auto` (the default) the sky is held still and the
login skips the explosion.

## As a Plasma wallpaper

The wallpaper version runs all day, so it was measured for power rather
than frame times: the whole laptop's draw from its battery (`power_now`),
30 seconds per run, with the sky full screen, against the same window
showing a still black screen.

| Machine | Still black screen | Full sky | Difference |
|---|---|---|---|
| Intel i5-8350U, UHD Graphics 620, 1920x1080 at 125% | 11.3 W (runs 11.9, 12.2, 9.8) | 11.7 W (runs 12.8, 12.1, 10.3) | about 0.4 W, less than the run-to-run spread |

So the animation costs a few percent of a laptop's draw. Updating the sky
30 times a second instead of every frame saved nothing measurable, so the
wallpaper isn't cut down. On the desktop it holds completely still behind
maximized and fullscreen windows (then it draws no frames at all), unless
"Keep animating behind maximized and fullscreen windows" is set.

CPU percentages are a poor guide here: on a power-saving profile the
processor runs slower and the same work shows as a much larger share of
a core.

To measure your own machine:

    QT_FORCE_STDERR_LOGGING=1 qml ci/perf.qml

Please add your numbers to an issue.

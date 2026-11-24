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

To measure your own machine:

    QT_FORCE_STDERR_LOGGING=1 qml ci/perf.qml

Please add your numbers to an issue.

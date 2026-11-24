# How Laser Cats fits together

    Main.qml                 the login screen: clock, password, pickers, power,
     │                       SDDM messages, on-screen keyboard; talks to SDDM
     └─ Sky.qml              shared state (clock, flash, alarm, blast, warp),
         │                   the seeded random numbers, and the parts:
         ├─ Starfield        star and nebula layers, drifting
         ├─ DriftingPlanets  the far-off amber planet and moon
         ├─ PlanetCat ×2     a cat behind a burning planet
         │   ├─ ChippedPlanet   the planet, with laser bites cut out of it
         │   ├─ Beam ×4         the lasers, sweeping across it
         │   ├─ Impact ×8       flashes where they hit
         │   ├─ PlanetFire      fire, smoke, debris (Qt Quick Particles)
         │   └─ Explosion       flash, streaks and rocks on login
         ├─ Constellation    a cat-head constellation
         ├─ FloatingCats     the laser cats drifting across
         ├─ ShootingStars, Comet
         └─ Warp             star streaks and the vortex cat after login

    Cats.js      every cat's picture, size, lane, paw and eye positions
                 (the theme's own set, and the classic set from get-cats.sh)
    Palette.js   the colours
    Rng.js       seeded random numbers

## Time and state

One clock (`Sky.clock`, seconds since start, advanced every frame) drives
all drifting and floating; one seeded generator (`Rng.js`) drives
everything random. Setting `Sky.frozen` stops both, so a test can set the
clock, `blast` and `warp` by hand and get the same picture every time.

Each part declares exactly what it needs as typed `required` properties
(running, clock, scale, blast...) instead of reaching into the sky, so it
can be read, tested and changed on its own.

## Logging in

SDDM closes the login screen the moment a password is accepted, so
`Main.launch()` plays the explosion and warp first (2.2 s) and only then
hands the password to SDDM; a wrong password rewinds the sky. The field is
emptied when Enter is pressed and the password is dropped as soon as it is
sent. A watchdog gives the field back if SDDM never answers. In calm mode
(or without a GPU, with `calm=auto`) it logs straight in.

## Screens

SDDM shows the theme once per screen and tells each copy whether it is on
the primary screen (`primaryScreen`); only that one shows the login
controls.

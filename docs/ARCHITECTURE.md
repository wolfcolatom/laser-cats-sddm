# How Laser Cats fits together

Three folders, and dependencies only point one way: `login` uses `sky` and
`style`; `sky` uses `style`; nothing in `sky` or `style` knows there is a
login screen, and only one file knows there is an SDDM.

    Main.qml                    where SDDM starts: a LoginScreen given SDDM
     │                          as its backend, and nothing else
     │
    login/
     ├─ Backend.qml             what the screen needs from a display manager:
     │   └─ SddmBackend.qml     users, sessions, login, power, messages. The
     │                          SDDM one is the only file that touches SDDM.
     ├─ Settings.qml            theme.conf, read and checked in one place
     ├─ LoginController.qml     the login as a small state machine, no pictures
     ├─ LoginScreen.qml         the screen: lays out the parts below over a Sky
     ├─ Clock, PasswordField, PillComboBox, IconButton, PowerButtons
     └─ KeyboardPanel.qml       the on-screen keyboard's slot; VirtualKeyboard
         └─ VirtualKeyboard     fills it, loaded only if asked for and installed

    sky/
     ├─ Sky.qml                 shared state (clock, flash, alarm, blast, warp)
     │   │                      and the parts:
     │   ├─ Starfield           star and nebula layers, drifting
     │   ├─ DriftingPlanets     the far-off amber planet and moon
     │   ├─ PlanetCat ×2        a cat behind a burning planet
     │   │   ├─ ChippedPlanet     the planet, with laser bites cut out of it
     │   │   ├─ Beam ×4           the lasers, sweeping across it
     │   │   ├─ Impact ×8         flashes where they hit
     │   │   ├─ PlanetFire        fire, smoke, debris (Qt Quick Particles)
     │   │   └─ Explosion         flash, streaks and rocks on login
     │   ├─ Constellation       a cat-head constellation
     │   ├─ FloatingCats        the laser cats drifting across
     │   ├─ ShootingStars, Comet
     │   └─ Warp                star streaks and the vortex cat after login
     │       └─ EyeLaser ×2
     ├─ CatSets.qml             every cat, as typed data: CatSet holds
     │                          FloatingCatSpec, PlanetCatSpec (with BeamSpec)
     │                          and WarpCatSpec. Two sets: the theme's own and
     │                          the classic one from get-cats.sh
     ├─ Rng.qml                 seeded random numbers
     └─ FlashEffect.qml         the white-out when a laser fires

    style/Theme.qml             the colours, one singleton

## Time, chance and state

One clock (`Sky.clock`, seconds since start, advanced every frame) drives
all drifting and floating. Everything random comes from an `Rng`; each part
that needs chance owns one, seeded from `Sky.seed`, so adding a random
number to one part can't change what another draws. Setting `Sky.frozen`
stops the clock, so a test can set the clock, `blast` and `warp` by hand
and get the same picture every time.

Each part declares exactly what it needs as typed `required` properties
(running, clock, scale, blast...) instead of reaching into the sky, so it
can be read, tested and changed on its own.

## Logging in

SDDM closes the login screen the moment a password is accepted, so the
explosion and warp have to play first. `LoginController` holds that order:

    Idle ──submit──▶ Exploding ──explosionFinished──▶ Waiting ──▶ (SDDM closes the screen)
      ▲                                                  │
      └──────────── wrong password, or no answer ────────┘

`submit()` asks the screen for the explosion; the sky says when the warp
has ended (`Sky.warpFinished`), and only then does the password go to the
backend. A wrong password, or no answer within 15 seconds, puts it back to
Idle and the screen rewinds the sky. In calm mode (or without a GPU, with
`calm=auto`) there is no Exploding: the password goes straight through.

The password field is emptied when Enter is pressed; the controller holds
the password only while the explosion plays and drops it as it is sent.

## The backend seam

`LoginScreen` and `LoginController` are given a `Backend` and never look
anywhere else. Under SDDM that is `SddmBackend`; in the tests it is
`tests/FakeBackend.qml`, which accepts or refuses on command. That is why
the whole login, from a key press to a rejected password, runs in the test
suite with no display manager, and why a change in SDDM's theme API would
touch one file.

## Screens

SDDM shows the theme once per screen and tells each copy whether it is on
the primary screen; only that one shows the login controls.

## Checks

| | |
|---|---|
| `tests/` | Qt Quick Test: the controller, the settings, the whole screen driven by keys against the fake backend, the cat data, colour contrast, the random numbers |
| `ci/visual.qml` | six reference pictures (sky idle, explosion, warp; three login screens), compared pixel by pixel |
| `ci/smoke.qml` | the real `Main.qml`, headless: normal, calm, software-rendered, HiDPI, right-to-left, on-screen keyboard |
| `make greeter` | the theme loaded by the real `sddm-greeter-qt6` |

CI runs all of it on a pinned Qt, the tests again on the oldest supported
Qt, and once a week on the newest (see `.github/workflows/`).

# Laser Cats: an SDDM login theme

An animated space login screen. Laser-eyed kittens float through a drifting
starfield and nebula; two tabbies rise out of burning planets, firing lasers
from their paws that chip pieces off them. Typing makes the cats flash (and
chips the planets); a wrong password washes everything amber. Press Enter
with the right password and the planets explode, the cats are flung off
screen, a roaring neon vortex cat appears, and everything warps away into your
session.

**Classic cats (optional).** Before 1.4 the theme used cats cut out of GIFs
on GIPHY. Their artists haven't licensed them for sharing, so they aren't in
this package, but `get-cats.sh` can download the GIFs from GIPHY and make the
classic cats on your own computer, for your own use. The theme switches to
them by itself. See "Classic cats" below.

## Requirements

- **SDDM 0.21 or newer with the Qt 6 greeter** (`sddm-greeter-qt6`)
- **Qt 6 Quick modules**: Effects, Shapes, Particles (on Arch: `qt6-declarative`)
- **A GPU-accelerated X server for SDDM.** The animation is too heavy for
  software rendering; if the login screen stays black, SDDM's X server isn't
  accelerated (on some Intel machines the old `xf86-video-intel` driver
  causes this; the `modesetting` driver fixes it).
- Fonts: Space Grotesk for the clock and date is bundled; everything else
  uses Adwaita Sans (falls back to your default sans font if missing)
- Works at any screen size: the starfield and nebula scale up to fill
  larger screens (1440p, 4K, ultrawide) and the cats and planets scale with
  the screen height.

## Changes

- 1.5: tidier code, nothing changes on screen unless you ask. Sky.qml is
  split into one file per part (Starfield, DriftingPlanets, PlanetCat,
  Constellation, FloatingCats, ShootingStars, Comet, Warp); every cat's
  picture, size and paw/eye positions live in Cats.js, the colours in
  Palette.js; clean under Qt 6's qmllint. New `calm` option (see Settings).
  The text is ready for translation. The scripts that drew the stars,
  nebula and planets are included (`tools/`). The cats and planets no
  longer jump once after a day and more on screen.
- 1.4: all-new cats made for this theme (laser-eyed kittens, paw-laser
  tabbies on the planets, a roaring vortex cat in the warp), replacing the
  GIFs from other artists; the planet cats' lasers follow their paws.
  `get-cats.sh` brings back the classic GIF cats on your own computer.
- 1.3: the clock and date in Space Grotesk (bundled), with the colon centred
  on the digits; an amber "Caps Lock is on" warning under the password field;
  rounded account and session lists; the session picker and power buttons on
  a solid dark fill, the power buttons as square icons with rounded tooltips.
- 1.2: computers with several accounts get a user picker (click the name
  above the password field); single-account computers look the same as
  before. Restart and Shut down are now labelled buttons in the bottom-right
  corner.
- 1.1: the starfield and nebula fill screens of any size (before, on
  screens larger than 1920x1080 they left part of the screen black); the
  drifting planets scale with the screen like the cats.
- 1.0: first release.

## Install

```
sudo cp -r laser-cats /usr/share/sddm/themes/
printf '[Theme]\nCurrent=laser-cats\n' | sudo tee /etc/sddm.conf.d/laser-cats.conf
```

Preview it first, in a window (it closes by itself after 30 seconds):

```
timeout 30 sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/laser-cats
```

**The preview can't log anyone in.** It looks exactly like the real login
screen but isn't connected to SDDM, so typing your password and pressing
Enter plays the explosion and then does nothing. That's expected.

To go back to SDDM's default theme:
`sudo rm /etc/sddm.conf.d/laser-cats.conf`

## Classic cats

To use the original GIF cats instead of the theme's own (needs `curl`,
ImageMagick 7 and python3 with numpy; it asks for sudo only to copy the cats
into the theme folder):

```
bash /usr/share/sddm/themes/laser-cats/get-cats.sh
```

It downloads three GIFs from GIPHY, cuts the cats out and puts them in the
theme's `assets` folder; the theme then uses them, with their own layout and
lasers. To go back to the theme's own cats:

```
bash /usr/share/sddm/themes/laser-cats/get-cats.sh --remove
```

Updating the theme removes the classic cats, so run it again after an
update. They're made from the artists' work for your own use: please don't
share them.

## How the login works

SDDM closes the login screen the moment a password is accepted, so the
explosion and warp (about 2.2 s) play **as soon as you press Enter**, and
only then is the password handed to SDDM. A wrong password rewinds it all:
the planets and cats fly back together, washed amber. If SDDM doesn't
answer within 15 seconds, the password field comes back by itself.

## Settings (`theme.conf`)

- `accent`: the colour the password field's edge starts with.
- `calm`: `true` for a gentler screen, for anyone sensitive to motion or on
  battery: no explosion or warp when you log in (it logs straight in, with
  no 2-second wait), no flashing as you type, no shooting stars or comet.

## Files

- `Main.qml`: the login screen (clock, password, pickers, power buttons).
- `Sky.qml`: the animated sky; it holds the shared state (flash, wrong
  password, explosion, warp) and puts the parts together:
  `Starfield.qml`, `DriftingPlanets.qml`, `PlanetCat.qml`,
  `Constellation.qml`, `FloatingCats.qml`, `ShootingStars.qml`,
  `Comet.qml`, `Warp.qml`.
- `Cats.js`: every cat's picture, size, lane, and paw/eye positions (so
  the lasers line up). Swapping a cat is an edit here.
- `Palette.js`: the colours.
- `tools/`: the scripts that drew the stars, nebula and planets.
- `get-cats.sh`, `get-cats/`: the optional classic cats.

## Translations

All the text (Password, Wrong password, Caps Lock is on, Restart, Shut
down) is marked with `qsTr()`, ready for translations.

## Credits and licence

Code and theme-made artwork: GPL-3.0-or-later (`LICENSE`). The clock font,
Space Grotesk, is under the SIL Open Font License. See `CREDITS.md`.

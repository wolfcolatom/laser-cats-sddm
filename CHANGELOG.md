# Changelog

All notable changes to Laser Cats. Versions follow
[semantic versioning](https://semver.org); the format follows
[Keep a Changelog](https://keepachangelog.com).

## [1.6] - 2026-11-24

### Added
- Accessibility: screen-reader names and roles on every control, a visible
  focus ring for keyboard use (Tab between controls, Enter or Space to
  press), and text contrast checked against WCAG AA.
- Messages from SDDM (an account locked, a password about to expire)
  shown under the password field.
- Without GPU acceleration the sky is held still and the login is calm,
  instead of an animation the computer can't draw (`calm=auto`).
- On several screens the login controls appear on the primary screen
  only; every screen shows the sky and the clock.
- Translations: German, Spanish, French, Italian, Japanese, Dutch, Polish,
  Brazilian Portuguese, Russian and Simplified Chinese.
- The time and date follow the system's language and 12/24-hour setting;
  `timeFormat` and `dateFormat` in theme.conf override them.
- Right-to-left languages mirror the layout.
- An optional on-screen keyboard button for touch screens (`keyboard=true`).
- Tests: the login flow, the cat data, colour contrast and the random
  numbers (Qt Quick Test), screenshot comparisons of the sky, a headless
  run in normal, calm, software-rendered, HiDPI and right-to-left setups,
  and translation checks; all run on every change.
- `make install`, an Arch PKGBUILD, and releases built by CI with checksums
  and build provenance.
- Licence information for every file (REUSE), contributor, architecture,
  art, performance and security notes.

### Changed
- The planet cat is split into ChippedPlanet, Beam, Impact, PlanetFire and
  Explosion; every part takes typed inputs and runs on one shared clock.
- Everything random uses a seeded generator, so the sky can be replayed
  exactly.
- `calm` now takes `auto` (the default), `true` or `false`.
- The flash effect is prepared at start, so the first key press no longer
  stutters.

### Fixed
- The user and session lists showed empty entries.
- Times written without a colon (such as 14.05) were drawn with a stray
  colon.
- The password is cleared from the field as soon as Enter is pressed.

## [1.5] - 2026-11-24

### Changed
- Sky.qml split into one file per part; every cat's picture, size and
  paw/eye positions in Cats.js, the colours in Palette.js; clean under
  Qt 6's qmllint.
- The text uses the system's font.
- The classic cats are switched on with `classic=true` in theme.conf.user,
  so nothing is logged at every login.

### Added
- `calm` setting; text marked for translation; the scripts that drew the
  stars, nebula and planets (`tools/`); a System Settings preview; SPDX
  headers; CI.

### Fixed
- The cats and planets no longer jump once after a day on screen.

## [1.4] - 2026-11-24

### Changed
- All-new cats made for the theme (laser-eyed kittens, roaring paw-laser
  tabbies on the planets, a vortex cat in the warp), replacing the GIFs
  from other artists; the planet cats' lasers follow their paws.

### Added
- `get-cats.sh` makes the classic GIF cats on your own computer.

## [1.3] - 2026-11-23

### Added
- The clock and date in Space Grotesk, with the colon centred on the
  digits; a Caps Lock warning; rounded account and session lists; square
  power buttons with tooltips.

## [1.2] - 2026-11-23

### Added
- A user picker on computers with several accounts; labelled Restart and
  Shut down buttons.

## [1.1] - 2026-11-23

### Fixed
- The starfield and nebula fill screens of any size; the drifting planets
  scale with the screen.

## [1.0] - 2026-11-23

First release.

[1.6]: https://github.com/wolfcolatom/laser-cats-sddm/releases/tag/v1.6
[1.5]: https://github.com/wolfcolatom/laser-cats-sddm/releases/tag/v1.5

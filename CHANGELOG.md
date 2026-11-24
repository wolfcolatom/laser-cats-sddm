# Changelog

All notable changes to Laser Cats. Versions follow
[semantic versioning](https://semver.org); the format follows
[Keep a Changelog](https://keepachangelog.com).

## [1.8] - 2026-11-24

### Added
- The sky as a Plasma wallpaper plugin (`org.wolfcolatom.lasercats`), for
  Plasma Login Manager, which takes Plasma wallpapers instead of SDDM
  themes, and for the Plasma desktop and lock screen. It is the same sky
  as the login theme, without the explosion and warp (a wallpaper doesn't
  know when a password goes in), with a Calm setting.
  `make install-wallpaper`, or the `laser-cats-wallpaper` archive from the
  release with `kpackagetool6`. The Arch package installs it too.

## [1.7.2] - 2026-11-24

### Fixed
- The two planet cats roared in unison: both started the same animation
  at the same moment. The right one now starts half a roar later.

## [1.7.1] - 2026-11-24

### Fixed
- "Wrong password" was never shown. It was the password field's
  placeholder, and Qt hides a centred field's placeholder while the field
  has focus, which on a login screen is always; a wrong password gave only
  the shake and the amber wash. It is now a line under the field, shown
  until the next password is being typed.

## [1.7] - 2026-11-24

Nothing looks different; this release is about how the theme is built.

### Changed
- The code is in three folders with one-way dependencies: `login/` (the
  screen), `sky/` (the animation) and `style/` (the colours). `Main.qml`
  only joins them.
- Only `login/SddmBackend.qml` talks to SDDM. The login screen is written
  against a small `Backend` interface, so the whole login runs in the tests
  against a fake one.
- The login itself is a small state machine (`LoginController`), separate
  from anything drawn, and theme.conf is read and checked in one place
  (`Settings`).
- The warp tells the login when it has ended, instead of the login
  guessing with a timer.
- Every cat is typed data (`sky/CatSets.qml`) instead of an untyped
  JavaScript object, and each part of the sky owns its own seeded random
  numbers.
- The colours are one singleton, `style/Theme.qml`.
- `get-cats.sh` checks its downloads against full SHA-256 sums, refuses
  unknown options, and stops rather than build from a changed download
  (`--force` overrides).

### Fixed
- If SDDM lists no users (network accounts, hidden users) there was no way
  to say who you are. A username field now appears in that case.
- Changing the user or session list while the explosion played could send
  the password under another name. Who and where are fixed when Enter is
  pressed, and the lists lock until SDDM answers.
- An answer from SDDM arriving after the theme had stopped waiting wiped
  what had been typed since.
- The date kept a stray word where the year had been in some languages
  (Spanish and Portuguese "…de noviembre de", Russian "…ноября г.").
- Enter with an empty password did nothing, so accounts without a
  password and fingerprint readers couldn't log in. It is now sent like
  any other.
- A message wider than the password field pushed the field off-centre.
- A mistyped `accent` colour turned the focus rings black; it now falls
  back to jade.
- The drop-down arrow was a character some fonts don't have; it is drawn.
- `make install` no longer copies Python cache folders or the art
  scripts, and never needs Qt's tools.
- The on-screen keyboard filled the whole screen, slid in at start-up, and
  once up covered its own button and could cover the password field. It
  now slides up only when asked, and the controls move clear of it.
- The oldest supported Qt is 6.8, not 6.5 as the notes said.

### Added
- `askUsername=true` in theme.conf: a field for the username instead of
  SDDM's list, for network accounts it doesn't list.
- Tests for the controller, the settings and the on-screen keyboard, and
  reference pictures of the login screen itself (plain, with warnings,
  with several users).
- `make greeter`: the theme loaded by the real SDDM greeter, and
  `make smoke-gl`: a run drawn with OpenGL; both also in CI.
- CI runs on a pinned Qt, again on Qt 6.8, and weekly on the newest; the
  release is built from the same pinned packages, and only after the
  checks pass on its tag.
- `make update-translations`.

### Removed
- An unused nebula layer and its picture.

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

[1.8]: https://github.com/wolfcolatom/laser-cats-sddm/releases/tag/v1.8
[1.7.2]: https://github.com/wolfcolatom/laser-cats-sddm/releases/tag/v1.7.2
[1.7.1]: https://github.com/wolfcolatom/laser-cats-sddm/releases/tag/v1.7.1
[1.7]: https://github.com/wolfcolatom/laser-cats-sddm/releases/tag/v1.7
[1.6]: https://github.com/wolfcolatom/laser-cats-sddm/releases/tag/v1.6
[1.5]: https://github.com/wolfcolatom/laser-cats-sddm/releases/tag/v1.5

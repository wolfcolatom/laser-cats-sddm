# Contributing

Bug reports, translations and fixes are welcome. Open an issue first for
anything bigger than a small fix, so we can agree on it.

## What you need

Qt 6.8 or newer with Qt Quick (`qt6-declarative`), `qt6-imageformats`,
`qt6-svg`, Qt's translation tools (`qt6-tools`), ImageMagick 7 and, for the
on-screen keyboard, `qt6-virtualkeyboard`. On Arch:

    sudo pacman -S --needed qt6-declarative qt6-imageformats qt6-svg qt6-tools qt6-virtualkeyboard imagemagick

## Checks

`make check` runs everything CI runs:

| | |
|---|---|
| `make lint` | Qt 6 `qmllint`, no warnings allowed |
| `make test` | the Qt Quick Test suites in `tests/` |
| `make smoke` | loads the theme headless: normal, calm, software-rendered, HiDPI, right-to-left |
| `make visual` | renders the sky and the login screen at fixed moments and compares with `ci/golden/` |
| `make translations` | compiles `translations/*.ts` and checks none are unfinished |
| `make i18n` | every translation shows up on the login screen |

Two more that CI runs but `check` doesn't, because they need more
installed: `make greeter` (SDDM) loads the theme under the real
`sddm-greeter-qt6`, and `make smoke-gl` (`xorg-server-xvfb`) runs it drawn
with OpenGL; both fail on any warning. To look
at it as a real login screen in a window (it can't log anyone in):

    sddm-greeter-qt6 --test-mode --theme .

CI runs all of this on a pinned Qt, the tests again on Qt 6.8 (the oldest
supported), and weekly on the newest. To move the pin, change the image and
snapshot in `.github/workflows/check.yml` and `release.yml` together.

`ci/perf.qml` measures frame rates on your own GPU (see
[docs/PERFORMANCE.md](docs/PERFORMANCE.md)).

## Changing how it looks

The sky is random but seeded, so the screenshot tests replay it exactly.
Colours live in `style/Theme.qml`; nothing else should spell one out.
If you change the look on purpose, approve the new pictures and commit
them with your change:

    ci/compare.sh --update

## Swapping a cat

Everything about a cat (picture, size, lane, paw and eye positions) is in
`sky/CatSets.qml`, as typed data. `tests/tst_cats.qml` checks every paw
and eye lies inside its picture.

## Where things go

`login/` may use `sky/` and `style/`; `sky/` may use `style/`; never the
other way. Only `login/SddmBackend.qml` touches SDDM: anything new the
screen needs from it goes through `login/Backend.qml`, and into
`tests/FakeBackend.qml`, so it can be tested. See
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Translations

Add a language with `lupdate`, translate the `.ts` file (Qt Linguist is
easiest), then `make translations`. After changing text in the theme, run
`make update-translations`. See [translations/README.md](translations/README.md).

## Style

- QML: four-space indents; every part declares what it needs as typed
  `required` properties; no `var` where a type will do; comments say why.
- Every source file starts with SPDX licence lines (REUSE).
- Commit messages: a short summary line, then what and why.

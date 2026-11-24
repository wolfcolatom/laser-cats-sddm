# SPDX-FileCopyrightText: 2026 tom
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Laser Cats
#   make install      install the theme (PREFIX=/usr, DESTDIR for packaging)
#   make uninstall
#   make check        lint, test, smoke, visual, translations (CI adds `make greeter`)
#   make dist         the release archive, laser-cats-sddm-VERSION.tar.gz
#   make wallpaper    the sky as a Plasma wallpaper package, in build/wallpaper/
#                     (install-wallpaper, dist-wallpaper, test-wallpaper)
#
# The checks need Qt 6 (qt6-declarative, qt6-imageformats, qt6-svg,
# qt6-tools) and ImageMagick 7. Install needs only coreutils: the compiled
# translations are in git, and it copies them as they are.

NAME      := laser-cats
VERSION   := $(shell sed -n 's/^Version=//p' metadata.desktop)
PREFIX    ?= /usr
THEMEDIR  := $(DESTDIR)$(PREFIX)/share/sddm/themes/$(NAME)
QTBIN     ?= /usr/lib/qt6/bin
QML_ENV   := QT_QPA_PLATFORM=offscreen QT_FORCE_STDERR_LOGGING=1

# what goes into an installed theme (and the release archive)
FILES     := Main.qml metadata.desktop theme.conf preview.jpg \
             get-cats.sh LICENSE README.md CREDITS.md CHANGELOG.md
DIRS      := sky login style assets get-cats LICENSES
# the release archive also carries the scripts that drew the art
DISTDIRS  := $(DIRS) tools
QM        := $(patsubst %.ts,%.qm,$(wildcard translations/*.ts))
LANGS     := $(basename $(notdir $(wildcard translations/*.ts)))

# the Plasma wallpaper (for Plasma Login Manager, the desktop and the lock
# screen): wallpaper/ plus the very same sky/, style/ and assets/
WALLID    := org.wolfcolatom.lasercats
WALLBUILD := build/wallpaper/$(WALLID)
WALLDIR   := $(DESTDIR)$(PREFIX)/share/plasma/wallpapers/$(WALLID)

.PHONY: wallpaper install-wallpaper uninstall-wallpaper dist-wallpaper test-wallpaper test-wallpaper-gl
.PHONY: all install uninstall translations update-translations check versions lint test smoke smoke-gl greeter visual i18n dist clean

all: translations

translations: $(QM)
	@! grep -l 'type="unfinished"' translations/*.ts || { echo "unfinished translations above"; exit 1; }

# after changing the text in login/: bring every .ts file up to date
update-translations:
	$(QTBIN)/lupdate -no-obsolete -locations none Main.qml login -ts $(wildcard translations/*.ts)

translations/%.qm: translations/%.ts
	$(QTBIN)/lrelease -silent $< -qm $@

# (no dependency on `translations`: after a clone the .ts and .qm files have
# arbitrary dates, and installing must not need Qt's tools)
install:
	@for f in $(QM); do [ -f $$f ] || { echo "$$f is missing: run 'make translations' first"; exit 1; }; done
	install -d $(THEMEDIR)/translations
	install -m 644 $(FILES) $(THEMEDIR)/
	chmod 755 $(THEMEDIR)/get-cats.sh
	cp -r $(DIRS) $(THEMEDIR)/
	find $(THEMEDIR) -name __pycache__ -prune -exec rm -rf {} +
	install -m 644 $(QM) translations/README.md $(THEMEDIR)/translations/

uninstall:
	rm -rf $(THEMEDIR)

check: versions lint test smoke visual translations i18n test-wallpaper

# the version is set in metadata.desktop; the PKGBUILD and changelog must agree,
# and nothing else may spell one out
versions:
	@grep -q '^pkgver=$(VERSION)$$' packaging/arch/PKGBUILD || { echo "packaging/arch/PKGBUILD: pkgver is not $(VERSION)"; exit 1; }
	@grep -q '^## \[$(VERSION)\]' CHANGELOG.md || { echo "CHANGELOG.md has no entry for $(VERSION)"; exit 1; }
	@! grep -nE 'laser-cats-sddm-[0-9]+\.[0-9]+' README.md CONTRIBUTING.md docs/*.md || { echo "a version number is written out above"; exit 1; }
	@[ "$$(grep -hoE 'archlinux:base-[0-9.]+' .github/workflows/*.yml | sort -u | wc -l)" = 1 ] \
	  && [ "$$(grep -hoE '(snapshot|SNAPSHOT): [0-9/]+' .github/workflows/*.yml | cut -d' ' -f2 | sort -u | wc -l)" = 1 ] \
	  || { echo "check.yml and release.yml pin different Arch images or snapshots"; exit 1; }
	@echo "version $(VERSION) agrees everywhere"

# VirtualKeyboard.qml needs qt6-virtualkeyboard; it's skipped if that isn't installed
QMLDIR    := $(or $(shell $(QTBIN)/qtpaths --query QT_INSTALL_QML 2>/dev/null),/usr/lib/qt6/qml)
HAVE_VK   := $(wildcard $(QMLDIR)/QtQuick/VirtualKeyboard)
QMLFILES  := Main.qml $(wildcard sky/*.qml login/*.qml style/*.qml ci/*.qml tests/*.qml)
LINT      := $(if $(HAVE_VK),$(QMLFILES),$(filter-out login/VirtualKeyboard.qml,$(QMLFILES)))

lint:
	$(if $(HAVE_VK),,@echo "(qt6-virtualkeyboard not installed: not linting login/VirtualKeyboard.qml)")
	@# absolute paths: qmllint needs them to match qmldir singletons
	@$(QTBIN)/qmllint --max-warnings 0 $(abspath $(LINT)) > /dev/null 2>&1 \
	  && echo "lint: $(words $(LINT)) files, no warnings" \
	  || { $(QTBIN)/qmllint --json - $(abspath $(LINT)) 2>/dev/null | python3 ci/lint-report.py; exit 1; }

test:
	$(QML_ENV) $(QTBIN)/qmltestrunner -input tests
	$(if $(HAVE_VK),QT_IM_MODULE=qtvirtualkeyboard $(QML_ENV) $(QTBIN)/qmltestrunner -input ci/tst_keyboard.qml,@echo "(qt6-virtualkeyboard not installed: on-screen keyboard test not run)")

# headless runs (so drawn by Qt's software renderer; `smoke-gl` is the
# OpenGL one); any QML warning fails them
smoke:
	@for mode in normal calm; do \
	  echo "== $$mode"; \
	  $(QML_ENV) timeout 60 $(QTBIN)/qml ci/smoke.qml -- $$mode > smoke.log 2>&1; s=$$?; cat smoke.log; \
	  [ $$s = 0 ] && ! grep -E '\.qml:[0-9]+' smoke.log || exit 1; done
	@echo "== HiDPI (2x)"; QT_SCALE_FACTOR=2 $(QML_ENV) timeout 60 $(QTBIN)/qml ci/smoke.qml -- normal > smoke.log 2>&1; s=$$?; cat smoke.log; \
	  [ $$s = 0 ] && ! grep -E '\.qml:[0-9]+' smoke.log
	@echo "== right-to-left"; LANG=he_IL.UTF-8 LC_ALL=he_IL.UTF-8 $(QML_ENV) timeout 60 $(QTBIN)/qml ci/i18n.qml > smoke.log 2>&1; cat smoke.log; \
	  grep -q 'mirrored=true' smoke.log
	$(if $(HAVE_VK),@echo "== on-screen keyboard"; QT_IM_MODULE=qtvirtualkeyboard $(QML_ENV) timeout 60 $(QTBIN)/qml ci/smoke.qml -- keyboard > smoke.log 2>&1; s=$$?; cat smoke.log; \
	  [ $$s = 0 ] && ! grep -E '\.qml:[0-9]+' smoke.log,@echo "(qt6-virtualkeyboard not installed: on-screen keyboard not run)")
	@rm -f smoke.log

# The same run drawn with OpenGL, as on a real login screen (the headless
# runs above use Qt's software renderer, which can't draw the glows): Mesa's
# software GL on a virtual display. Not part of `check`: it needs xvfb-run.
smoke-gl:
	@LIBGL_ALWAYS_SOFTWARE=1 QT_QPA_PLATFORM=xcb QT_FORCE_STDERR_LOGGING=1 xvfb-run -a -s "-screen 0 1280x720x24" \
	  timeout 120 $(QTBIN)/qml ci/smoke.qml -- gl > smoke.log 2>&1; s=$$?; cat smoke.log; \
	  [ $$s = 0 ] && ! grep -E '\.qml:[0-9]+' smoke.log
	@rm -f smoke.log
	@echo "smoke-gl: drawn with OpenGL, no warnings"

# The wallpaper drawn with OpenGL (Mesa's software GL on a virtual display),
# so the animated path runs: it must move, draw nothing while the desktop is
# covered, and move again after. Not part of `check`: it needs xvfb-run.
test-wallpaper-gl: wallpaper
	@LIBGL_ALWAYS_SOFTWARE=1 QT_QPA_PLATFORM=xcb QT_FORCE_STDERR_LOGGING=1 xvfb-run -a -s "-screen 0 1280x720x24" \
	  timeout 120 $(QTBIN)/qml -I ci/stubs ci/wallpaper.qml -- $(abspath $(WALLBUILD)) > wallpaper.log 2>&1; s=$$?; cat wallpaper.log; \
	  [ $$s = 0 ] && grep -q 'paused when covered' wallpaper.log && ! grep -E '\.qml:[0-9]+' wallpaper.log
	@rm -f wallpaper.log

# the real SDDM greeter, headless, for a few seconds: it must load Main.qml
# and stay up (so it ends by the timeout, exit 124) with no QML warnings.
# Not part of `check`: it needs SDDM installed.
greeter:
	@$(QML_ENV) timeout 8 sddm-greeter-qt6 --test-mode --theme "$(CURDIR)" > greeter.log 2>&1; s=$$?; \
	  grep -q 'Loading file.*Main.qml' greeter.log || { cat greeter.log; echo "greeter: the theme was not loaded"; exit 1; }; \
	  ! grep -E '\.qml:[0-9]+' greeter.log || { echo "greeter: QML warnings above"; exit 1; }; \
	  [ $$s = 124 ] || { tail -5 greeter.log; echo "greeter: exited early ($$s)"; exit 1; }
	@rm -f greeter.log; echo "greeter: loaded under the real SDDM greeter, no warnings"

visual:
	QTBIN=$(QTBIN) ci/compare.sh

# every translation shows up on the login screen: its Restart button must
# not still say "Restart"
i18n: translations
	@for l in $(LANGS); do \
	  out=$$($(QML_ENV) timeout 30 $(QTBIN)/qml --translation translations/$$l.qm ci/i18n.qml 2>&1 | grep 'i18n:'); \
	  echo "$$l: $$out"; \
	  [ -n "$$out" ] && ! echo "$$out" | grep -q 'restart=Restart ' || { echo "$$l not applied"; exit 1; }; done

dist: translations
	rm -rf build/$(NAME) && mkdir -p build/$(NAME)/translations
	cp -r $(FILES) $(DISTDIRS) build/$(NAME)/
	cp $(QM) translations/README.md build/$(NAME)/translations/
	find build/$(NAME) -name __pycache__ -prune -exec rm -rf {} +
	tar --sort=name --owner=0 --group=0 --numeric-owner --mtime='$(shell git log -1 --format=%cI 2>/dev/null || date -u +%FT%TZ)' \
	    --mode='u+rwX,go+rX,go-w' -C build -cf - $(NAME) | gzip -n -9 > $(NAME)-sddm-$(VERSION).tar.gz
	rm -rf build
	@echo "built $(NAME)-sddm-$(VERSION).tar.gz"

wallpaper:
	rm -rf $(WALLBUILD) && mkdir -p $(WALLBUILD)
	cp -r wallpaper/. $(WALLBUILD)/
	cp -r sky style assets $(WALLBUILD)/contents/ui/
	cp LICENSE $(WALLBUILD)/
	sed -i 's/"Version": "[^"]*"/"Version": "$(VERSION)"/' $(WALLBUILD)/metadata.json
	find $(WALLBUILD) -name __pycache__ -prune -exec rm -rf {} +
	@echo "built $(WALLBUILD)"

# system-wide: Plasma Login Manager's greeter runs as its own user and only
# sees wallpapers installed for everyone
install-wallpaper: wallpaper
	install -d $(WALLDIR)
	cp -r $(WALLBUILD)/. $(WALLDIR)/

uninstall-wallpaper:
	rm -rf $(WALLDIR)

# for the KDE Store and `kpackagetool6 --type Plasma/Wallpaper --install`
dist-wallpaper: wallpaper
	tar --sort=name --owner=0 --group=0 --numeric-owner --mtime='$(shell git log -1 --format=%cI 2>/dev/null || date -u +%FT%TZ)' \
	    --mode='u+rwX,go+rX,go-w' -C build/wallpaper -cf - $(WALLID) | gzip -n -9 > $(NAME)-wallpaper-$(VERSION).tar.gz
	@echo "built $(NAME)-wallpaper-$(VERSION).tar.gz"

# loads the package the way Plasma Login Manager does, with a stand-in for
# Plasma's WallpaperItem (ci/stubs); with the real Plasma too, and installs
# it with KDE's own package tool, where libplasma is installed (as in CI).
# Any QML warning fails it.
HAVE_PLASMA := $(wildcard $(QMLDIR)/org/kde/plasma/plasmoid)
HAVE_KIRIGAMI := $(wildcard $(QMLDIR)/org/kde/kirigami)
HAVE_IMAGEWP := $(wildcard $(QMLDIR)/org/kde/plasma/wallpapers/image)
KPKGTEST  := build/kpackage-test
test-wallpaper: wallpaper
	@for mode in normal calm; do \
	  $(QML_ENV) timeout 60 $(QTBIN)/qml -I ci/stubs ci/wallpaper.qml -- $(abspath $(WALLBUILD)) $$mode > wallpaper.log 2>&1; s=$$?; cat wallpaper.log; \
	  [ $$s = 0 ] && ! grep -E '\.qml:[0-9]+' wallpaper.log || exit 1; done
	@files="$(abspath $(WALLBUILD)/contents/ui/main.qml)$(if $(HAVE_KIRIGAMI), $(abspath $(WALLBUILD)/contents/ui/config.qml))$(if $(HAVE_IMAGEWP), $(abspath $(WALLBUILD)/contents/ui/CoverMonitor.qml))"; \
	  $(QTBIN)/qmllint --max-warnings 0 -I $(abspath ci/stubs) $$files > /dev/null 2>&1 \
	  && echo "wallpaper lint: $$(echo $$files | wc -w) files, no warnings" || { $(QTBIN)/qmllint -I $(abspath ci/stubs) $$files; exit 1; }
	$(if $(HAVE_PLASMA),@$(QML_ENV) timeout 60 $(QTBIN)/qml ci/wallpaper.qml -- $(abspath $(WALLBUILD)) plasma > wallpaper.log 2>&1; s=$$?; cat wallpaper.log; \
	  [ $$s = 0 ] && ! grep -E '\.qml:[0-9]+' wallpaper.log,@echo "(libplasma not installed: not tried with the real Plasma)")
	$(if $(HAVE_PLASMA),@rm -rf $(KPKGTEST) && mkdir -p $(KPKGTEST) \
	  && XDG_DATA_HOME=$(abspath $(KPKGTEST)) kpackagetool6 --type Plasma/Wallpaper --install $(WALLBUILD) >/dev/null \
	  && XDG_DATA_HOME=$(abspath $(KPKGTEST)) kpackagetool6 --type Plasma/Wallpaper --list | grep -q '$(WALLID)' \
	  && echo "kpackagetool6: installs and lists as $(WALLID)",)
	@rm -f wallpaper.log

clean:
	rm -rf build smoke.log greeter.log wallpaper.log $(NAME)-sddm-*.tar.gz $(NAME)-wallpaper-*.tar.gz

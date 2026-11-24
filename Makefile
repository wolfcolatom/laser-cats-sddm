# SPDX-FileCopyrightText: 2026 tom
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Laser Cats
#   make install      install the theme (PREFIX=/usr, DESTDIR for packaging)
#   make uninstall
#   make check        everything CI checks: lint, test, smoke, visual, translations
#   make dist         the release archive, laser-cats-sddm-VERSION.tar.gz
#
# Needs Qt 6 (qt6-declarative, qt6-imageformats, qt6-svg, qt6-tools) and
# ImageMagick 7 for the checks; only install needs nothing but coreutils.

NAME      := laser-cats
VERSION   := $(shell sed -n 's/^Version=//p' metadata.desktop)
PREFIX    ?= /usr
THEMEDIR  := $(DESTDIR)$(PREFIX)/share/sddm/themes/$(NAME)
QTBIN     ?= /usr/lib/qt6/bin
QML_ENV   := QT_QPA_PLATFORM=offscreen QT_FORCE_STDERR_LOGGING=1

# what goes into an installed theme (and the release archive)
FILES     := $(wildcard *.qml) $(wildcard *.js) metadata.desktop theme.conf preview.jpg \
             get-cats.sh LICENSE README.md CREDITS.md CHANGELOG.md
DIRS      := assets get-cats tools LICENSES
QM        := $(patsubst %.ts,%.qm,$(wildcard translations/*.ts))
LANGS     := $(basename $(notdir $(wildcard translations/*.ts)))

.PHONY: all install uninstall translations check lint test smoke visual i18n dist clean

all: translations

translations: $(QM)
	@! grep -l 'type="unfinished"' translations/*.ts || { echo "unfinished translations above"; exit 1; }

translations/%.qm: translations/%.ts
	$(QTBIN)/lrelease -silent $< -qm $@

install: translations
	install -d $(THEMEDIR)/translations
	install -m 644 $(FILES) $(THEMEDIR)/
	chmod 755 $(THEMEDIR)/get-cats.sh
	cp -r $(DIRS) $(THEMEDIR)/
	install -m 644 $(QM) translations/README.md $(THEMEDIR)/translations/

uninstall:
	rm -rf $(THEMEDIR)

check: lint test smoke visual translations i18n

# VirtualKeyboard.qml needs qt6-virtualkeyboard; it's skipped if that isn't installed
HAVE_VK   := $(wildcard /usr/lib/qt6/qml/QtQuick/VirtualKeyboard)
LINT      := $(if $(HAVE_VK),$(wildcard *.qml),$(filter-out VirtualKeyboard.qml,$(wildcard *.qml))) ci/*.qml tests/*.qml

lint:
	$(if $(HAVE_VK),,@echo "(qt6-virtualkeyboard not installed: not linting VirtualKeyboard.qml)")
	$(QTBIN)/qmllint --max-warnings 0 $(LINT)

test:
	$(QML_ENV) $(QTBIN)/qmltestrunner -input tests

# headless runs; any QML warning fails them
smoke:
	@for mode in normal calm; do \
	  echo "== $$mode"; \
	  $(QML_ENV) timeout 60 $(QTBIN)/qml ci/smoke.qml -- $$mode > smoke.log 2>&1; s=$$?; cat smoke.log; \
	  [ $$s = 0 ] && ! grep -E '\.qml:[0-9]+' smoke.log || exit 1; done
	@echo "== software renderer"; QT_QUICK_BACKEND=software $(QML_ENV) timeout 60 $(QTBIN)/qml ci/smoke.qml -- calm > smoke.log 2>&1; s=$$?; cat smoke.log; \
	  [ $$s = 0 ] && ! grep -E '\.qml:[0-9]+' smoke.log
	@echo "== HiDPI (2x)"; QT_SCALE_FACTOR=2 $(QML_ENV) timeout 60 $(QTBIN)/qml ci/smoke.qml -- normal > smoke.log 2>&1; s=$$?; cat smoke.log; \
	  [ $$s = 0 ] && ! grep -E '\.qml:[0-9]+' smoke.log
	@echo "== right-to-left"; LANG=he_IL.UTF-8 LC_ALL=he_IL.UTF-8 $(QML_ENV) timeout 60 $(QTBIN)/qml ci/i18n.qml > smoke.log 2>&1; cat smoke.log; \
	  grep -q 'mirrored=true' smoke.log
	@rm -f smoke.log

visual:
	ci/compare.sh

# every translation shows up on the login screen
i18n: translations
	@for l in $(LANGS); do \
	  out=$$($(QML_ENV) timeout 30 $(QTBIN)/qml --translation translations/$$l.qm ci/i18n.qml 2>&1 | grep 'i18n:'); \
	  echo "$$l: $$out"; \
	  [ "$$l" = it ] || ! echo "$$out" | grep -q 'placeholder=Password ' || { echo "$$l not applied"; exit 1; }; done

dist: translations
	rm -rf build/$(NAME) && mkdir -p build/$(NAME)/translations
	cp -r $(FILES) $(DIRS) build/$(NAME)/
	cp $(QM) translations/README.md build/$(NAME)/translations/
	find build/$(NAME) -name __pycache__ -prune -exec rm -rf {} +
	tar --sort=name --owner=0 --group=0 --numeric-owner --mtime='$(shell git log -1 --format=%cI 2>/dev/null || date -u +%FT%TZ)' \
	    --mode='u+rwX,go+rX,go-w' -C build -cf - $(NAME) | gzip -n -9 > $(NAME)-sddm-$(VERSION).tar.gz
	rm -rf build
	@echo "built $(NAME)-sddm-$(VERSION).tar.gz"

clean:
	rm -rf build smoke.log $(NAME)-sddm-*.tar.gz

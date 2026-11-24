# Translations

The theme's text (Password, Wrong password, Caps Lock is on, Restart, Shut
down...) is marked with `qsTr()` in `login/`. To add a language, generate
a `.ts` file named after the locale with Qt's `lupdate`, translate it (for
example with Qt Linguist), and compile it:

    /usr/lib/qt6/bin/lupdate -no-obsolete -locations none ../login -ts da.ts
    make -C .. translations

After changing the text in the theme, `make update-translations` brings
every `.ts` file up to date; `make translations` fails while any entry is
still unfinished.

SDDM loads `<locale>.qm` from this folder (set in metadata.desktop).

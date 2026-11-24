# Translations

The theme's text (Password, Wrong password, Caps Lock is on, Restart, Shut
down) is marked with `qsTr()`. To add a language, generate a `.ts` file
with Qt's `lupdate`, translate it (for example with Qt Linguist), and
compile it to `.qm` with `lrelease`, named after the locale:

    /usr/lib/qt6/bin/lupdate ../Main.qml -ts laser-cats_de.ts
    /usr/lib/qt6/bin/lrelease laser-cats_de.ts -qm de.qm

SDDM loads `<locale>.qm` from this folder (set in metadata.desktop).

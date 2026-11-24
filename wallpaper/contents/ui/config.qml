// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats wallpaper settings, shown by Plasma's wallpaper dialog. Laid
// out like KDE's own wallpapers' settings (org.kde.color): the labels line
// up with the dialog's own (twinFormLayouts, formLayout), and each setting
// is a cfg_ alias, so the dialog's Defaults and Reset show on the controls.
//
// i18nd and parentLayout come from the dialog, which the linter can't see:
// qmllint disable unqualified
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: root
    twinFormLayouts: parentLayout

    property alias cfg_Calm: calmBox.checked
    property alias cfg_AlwaysAnimate: alwaysAnimateBox.checked
    property alias formLayout: root

    QQC2.CheckBox {
        id: calmBox
        Kirigami.FormData.label: i18nd("plasma_wallpaper_org.wolfcolatom.lasercats", "Motion:")
        text: i18nd("plasma_wallpaper_org.wolfcolatom.lasercats", "Calm: no shooting stars or comet")
    }
    QQC2.CheckBox {
        id: alwaysAnimateBox
        text: i18nd("plasma_wallpaper_org.wolfcolatom.lasercats", "Keep animating behind maximized and fullscreen windows")
    }
}

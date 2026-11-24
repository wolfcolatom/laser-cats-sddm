// SPDX-FileCopyrightText: 2026 tom
// SPDX-License-Identifier: GPL-3.0-or-later
// Laser Cats wallpaper settings, shown by Plasma's wallpaper dialog.
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: root
    property bool cfg_Calm
    property bool cfg_CalmDefault

    QQC2.CheckBox {
        Kirigami.FormData.label: i18nd("plasma_wallpaper_org.wolfcolatom.lasercats", "Motion:")
        text: i18nd("plasma_wallpaper_org.wolfcolatom.lasercats", "Calm: no shooting stars or comet")
        checked: root.cfg_Calm
        onToggled: root.cfg_Calm = checked
    }
}

/*
    SPDX-FileCopyrightText: 2022 David Edmundson <davidedmundson@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick

import org.kde.plasma.components as PlasmaComponents3

LockSessionManagementScreen {
    focus: true
    PlasmaComponents3.Button {
        id: loginButton
        focus: true
        font.family: FontConfig.family
        text: i18ndc("plasma_shell_org.kde.plasma.desktop", "@action:button no-password unlock", "Unlock")
        icon.name: "object-unlocked"
        onClicked: Qt.quit();
        Keys.onEnterPressed: clicked()
        Keys.onReturnPressed: clicked()
    }

    Component.onCompleted: {
        forceActiveFocus();
    }
}

/*
    SPDX-FileCopyrightText: 2014 David Edmundson <davidedmundson@kde.org>
    SPDX-FileCopyrightText: 2014 Aleix Pol Gonzalez <aleixpol@blue-systems.com>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

Item {
    id: wrapper

    // If we're using software rendering, draw outlines instead of shadows
    // See https://bugs.kde.org/show_bug.cgi?id=398317
    readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software

    property bool isCurrent: true

    property string name
    property string userName
    property string avatarPath
    property string iconSource
    property bool needsPassword
    property var vtNumber
    property bool constrainText: true
    property alias nameFontSize: usernameDelegate.font.pointSize
    property real fontSize: Kirigami.Theme.defaultFont.pointSize + 2
    signal clicked()

    property real faceSize: Kirigami.Units.gridUnit * 7

    opacity: isCurrent ? 1.0 : 0.75

    Behavior on opacity {
        OpacityAnimator {
            duration: Kirigami.Units.longDuration
        }
    }

    // Draw a translucent background circle under the user picture
    Rectangle {
        anchors.centerIn: imageSource
        width: imageSource.width - 2 // Subtract to prevent fringing
        height: width
        radius: width / 2

        color: Kirigami.Theme.backgroundColor
        opacity: 0.6
    }

    // Anillo de degradado que gira alrededor del avatar mientras escribes
    // y late con cada tecla.
    Item {
        id: avatarRing
        anchors.centerIn: imageSource
        width: imageSource.width + 16
        height: width
        visible: opacity > 0
        opacity: wrapper.isCurrent && Fx.typing ? 1 : 0
        scale: wrapper.isCurrent && Fx.typing ? 1 : 0.8
        Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 600; easing.type: Easing.OutBack } }

        property real kick: 0
        Connections {
            target: Fx
            function onKeystroke() { if (wrapper.isCurrent) ringKick.restart(); }
        }
        SequentialAnimation {
            id: ringKick
            NumberAnimation { target: avatarRing; property: "kick"; to: 1; duration: 80 }
            NumberAnimation { target: avatarRing; property: "kick"; to: 0; duration: 420; easing.type: Easing.OutCubic }
        }

        RectangularGlow {
            anchors.fill: parent
            glowRadius: 18 + avatarRing.kick * 10
            spread: 0.1
            cornerRadius: width / 2 + glowRadius
            color: Fx.accent2
            opacity: 0.35 + avatarRing.kick * 0.4
        }
        ConicalGradient {
            id: ringCone
            anchors.fill: parent
            visible: false
            gradient: Gradient {
                GradientStop { position: 0.00; color: Fx.accent }
                GradientStop { position: 0.35; color: Fx.accent2 }
                GradientStop { position: 0.70; color: Fx.accent3 }
                GradientStop { position: 1.00; color: Fx.accent }
            }
            NumberAnimation on angle {
                running: avatarRing.visible
                loops: Animation.Infinite
                from: 0; to: 360; duration: 3000
            }
        }
        Rectangle {
            id: ringMask
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: 3 + avatarRing.kick * 2
            visible: false
        }
        OpacityMask {
            anchors.fill: parent
            source: ringCone
            maskSource: ringMask
        }
    }

    Item {
        id: imageSource
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        Behavior on width {
            PropertyAnimation {
                from: wrapper.faceSize
                duration: Kirigami.Units.longDuration;
            }
        }
        width: wrapper.isCurrent ? wrapper.faceSize : wrapper.faceSize - Kirigami.Units.gridUnit
        height: width

        //Image takes priority, taking a full path to a file, if that doesn't exist we show an icon
        Image {
            id: face
            source: wrapper.avatarPath
            sourceSize: Qt.size(wrapper.faceSize * Screen.devicePixelRatio, wrapper.faceSize * Screen.devicePixelRatio)
            fillMode: Image.PreserveAspectCrop
            anchors.fill: parent
        }

        Kirigami.Icon {
            id: faceIcon
            source: wrapper.iconSource
            visible: face.status === Image.Error || face.status === Image.Null
            anchors.fill: parent
        }
    }

    ShaderEffect {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        width: imageSource.width
        height: imageSource.height

        supportsAtlasTextures: true

        readonly property Item source: ShaderEffectSource {
            sourceItem: imageSource
            // software rendering is just a fallback so we can accept not having a rounded avatar here
            hideSource: wrapper.GraphicsInfo.api !== GraphicsInfo.Software
            live: true // otherwise the user in focus will show a blurred avatar
        }

        readonly property color colorBorder: Kirigami.Theme.textColor

        fragmentShader: "qrc:/qt/qml/org/kde/breeze/components/shaders/UserDelegate.frag.qsb"
    }

    PlasmaComponents3.Label {
        id: usernameDelegate

        anchors.top: imageSource.bottom
        anchors.topMargin: Kirigami.Units.gridUnit
        anchors.horizontalCenter: parent.horizontalCenter

        // Make it bigger than other fonts to match the scale of the avatar better
        font.family: FontConfig.family
        font.pointSize: wrapper.fontSize + 4

        width: wrapper.constrainText ? parent.width : undefined
        text: wrapper.name
        textFormat: Text.PlainText
        style: wrapper.softwareRendering ? Text.Outline : Text.Normal
        styleColor: wrapper.softwareRendering ? Kirigami.Theme.backgroundColor : "transparent" //no outline, doesn't matter
        wrapMode: Text.WordWrap
        maximumLineCount: wrapper.constrainText ? 3 : 1
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        //make an indication that this has active focus, this only happens when reached with keyboard navigation
        font.underline: wrapper.activeFocus
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onClicked: wrapper.clicked()
    }

    Keys.onSpacePressed: wrapper.clicked()

    Accessible.name: name
    Accessible.role: Accessible.Button
    function accessiblePressAction() { wrapper.clicked() }
}

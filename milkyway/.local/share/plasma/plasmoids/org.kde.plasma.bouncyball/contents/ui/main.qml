/*******************************************************************************
 *   Copyright (C) 2008 by Thomas Gillespie <tomjamesgillespie@googlemail.com> *
 *   Copyright (C) 2010 by Enrico Ros <enrico.ros@gmail.com>                   *
 *   Copyright (C) 2017 by Eike Hein <hein@kde.org>                            *
 *   Copyright (C) 2026 by Filip Fila <filipfila.kde@gmail.com>                *
 *                                                                             *
 *   This program is free software; you can redistribute it and/or modify      *
 *   it under the terms of the GNU General Public License as published by      *
 *   the Free Software Foundation; either version 2 of the License, or         *
 *   (at your option) any later version.                                       *
 *                                                                             *
 *   This program is distributed in the hope that it will be useful,           *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             *
 *   GNU General Public License for more details.                              *
 *                                                                             *
 *   You should have received a copy of the GNU General Public License         *
 *   along with this program; if not, write to the                             *
 *   Free Software Foundation, Inc.,                                           *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .            *
 ******************************************************************************/

/*
 * Plasma 6 Port Notes:
 * - plasmoid.availableScreenRect → plasmoid.containment.availableScreenRect
 * - Audio component → MediaPlayer + AudioOutput
 * - PlasmaExtras.Heading → Kirigami.Heading
 * - units.gridUnit → Kirigami.Units.gridUnit
 * - units.devicePixelRatio → Screen.devicePixelRatio
 * - MouseArea → DragHandler, TapHandler, HoverHandler (prevents edit mode trigger)
 * - Parent hierarchy traversal needed for desktop containment (no longer fixed depth)
 */

import QtQuick
import QtQuick.Layouts
import QtMultimedia
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: main

    // Still works in Plasma 6, we don't want to have a plasmoid background
    Plasmoid.backgroundHints: "NoBackground";

    fullRepresentation: ((plasmoid.location != PlasmaCore.Types.Desktop
    && plasmoid.location != PlasmaCore.Types.Floating) ? errorComponent : null)

    Layout.minimumWidth: Kirigami.Units.gridUnit * 10
    Layout.minimumHeight: Kirigami.Units.gridUnit * 10

    onXChanged: ball.bouncing = false
    onYChanged: ball.bouncing = false
    onWidthChanged: ball.bouncing = false
    onHeightChanged: ball.bouncing = false
    onVisibleChanged: ball.bouncing = false

    property int collisionSounds: 0
    readonly property string collisionSoundUrl: Qt.resolvedUrl("../sounds/bounce.ogg")

    // Plasma 6: devicePixelRatio needs to be retrieved from Screen
    readonly property real devicePixelRatio: Screen.devicePixelRatio

    // Plasma 6: Preload sound to avoid loading lag on each collision
    // MediaPlayer replaces the old Audio component from Plasma 5
    MediaPlayer {
        id: soundTemplate
        audioOutput: AudioOutput {
            id: templateAudioOutput
            volume: plasmoid.configuration.soundVolume || 1.0
        }
        source: main.collisionSoundUrl

        // Preload the sound file at startup to reduce playback latency
        Component.onCompleted: {
            // Just loading it is enough, we'll create new instances for playback
        }
    }

    // Update sound volume when configuration changes
    Connections {
        target: plasmoid.configuration
        function onSoundVolumeChanged() {
            templateAudioOutput.volume = plasmoid.configuration.soundVolume;
        }
    }

    // Plasma 6: plasmoid.availableScreenRect moved to plasmoid.containment.availableScreenRect
    readonly property var availableScreenRect: plasmoid.containment.availableScreenRect

    readonly property real fullScreenWidth: Screen.width
    readonly property real fullScreenHeight: Screen.height

    // Use availableScreenRect just like Plasma 5 did
    readonly property real boundsLeft: availableScreenRect.x
    readonly property real boundsTop: availableScreenRect.y
    readonly property real boundsRight: availableScreenRect.x + availableScreenRect.width
    readonly property real boundsBottom: availableScreenRect.y + availableScreenRect.height

    //--------------------------------------------------
    // Error component for non-desktop locations
    // Plasma 6: Changed from PlasmaExtras.Heading to Kirigami.Heading
    //          Changed units.gridUnit to Kirigami.Units.gridUnit
    //--------------------------------------------------
    Component {
        id: errorComponent
        Kirigami.Heading {
            Layout.minimumWidth: implicitWidth + (2 * Kirigami.Units.gridUnit)
            Layout.minimumHeight: implicitHeight + (2 * Kirigami.Units.gridUnit)
            level: 3
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            elide: Text.ElideMiddle
            text: i18n("Bouncy Ball only works on the desktop, sorry!")
        }
    }

    //--------------------------------------------------
    // Collision sound component
    // Plasma 6: Uses MediaPlayer + AudioOutput instead of Audio component
    //          Audio component was removed in Qt6/QtMultimedia 6
    //--------------------------------------------------
    Component {
        id: collisionSoundComponent
        MediaPlayer {
            audioOutput: AudioOutput {
                // Get volume from config at the moment of creation
                volume: plasmoid.configuration.soundVolume
            }
            source: main.collisionSoundUrl

            property bool hasPlayed: false

            // Plasma 6: onStopped changed to onPlaybackStateChanged
            onPlaybackStateChanged: {
                if (playbackState === MediaPlayer.StoppedState && hasPlayed) {
                    destroy();
                }
            }

            Component.onCompleted: {
                play();
                hasPlayed = true;
                ++main.collisionSounds;
            }

            Component.onDestruction: {
                --main.collisionSounds;
            }
        }
    }

    //--------------------------------------------------
    // Timer for physics simulation
    // Configuration property access works the same in Plasma 6
    //--------------------------------------------------
    Timer {
        id: physicsTick
        property bool even: false
        interval: plasmoid.configuration.tickLength
        repeat: true
        triggeredOnStart: true
        onTriggered: ball.bounce()
    }

    // Plasma 6: Listen for configuration changes to update live
    // This allows timer interval to change without restarting the widget
    Connections {
        target: plasmoid.configuration
        function onTickLengthChanged() {
            physicsTick.interval = plasmoid.configuration.tickLength;
        }
    }

    //--------------------------------------------------
    // Ball background socket
    // Plasma 6: Use devicePixelRatio from main (matches Plasma 5 behavior)
    //--------------------------------------------------
    Rectangle {
        id: ballSocket
        width: Math.min(main.width, main.height)
        height: width
        anchors.centerIn: parent
        border.width: main.devicePixelRatio
        border.color: Kirigami.Theme.textColor
        color: Kirigami.Theme.backgroundColor
        opacity: 0.5
        radius: width / 2
    }

    //--------------------------------------------------
    // Return hint
    //--------------------------------------------------
    Kirigami.Heading {
        id: returnHint
        anchors.fill: ballSocket
        anchors.margins: Kirigami.Units.gridUnit
        visible: plasmoid.configuration.showHelpTexts && ball.bouncing
        level: 3
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
        elide: Text.ElideMiddle
        text: i18n("Click to\n return ball!")
    }

    MouseArea {
        anchors.fill: parent
        enabled: ball.bouncing
        onClicked: ball.bouncing = false
    }

    //--------------------------------------------------
    // Ball SVG
    // Plasma 6: Use devicePixelRatio for size calculation (matches Plasma 5)
    //--------------------------------------------------
    KSvg.SvgItem {
        id: ball
        width: ballSocket.width - (6 * main.devicePixelRatio)
        height: width

        // Ball physics
        property bool bouncing: false
        property bool everBounced: false

        property real gravity: 1.5
        property real friction: 0.03
        property real restitution: 0.8
        property var time
        property var velocity: Qt.vector2d(0, 0)
        property real angularVelocity: 0
        property real angle: 0

        // Update physics properties when configuration changes
        Connections {
            target: plasmoid.configuration
            function onGravityChanged() {
                ball.gravity = plasmoid.configuration.gravity * main.devicePixelRatio;
                // Reset velocity when physics changes to avoid weird behavior
                if (ball.bouncing) {
                    ball.velocity = Qt.vector2d(ball.velocity.x * 0.5, ball.velocity.y * 0.5);
                }
            }
            function onFrictionChanged() {
                ball.friction = plasmoid.configuration.friction;
            }
            function onRestitutionChanged() {
                ball.restitution = plasmoid.configuration.restitution;
            }
        }

        Component.onCompleted: {
            // Initialize physics properties from configuration
            var configGravity = plasmoid.configuration.gravity;
            var configFriction = plasmoid.configuration.friction;
            var configRestitution = plasmoid.configuration.restitution;

            gravity = (configGravity !== undefined ? configGravity : 1.5) * main.devicePixelRatio;
            friction = configFriction !== undefined ? configFriction : 0.03;
            restitution = configRestitution !== undefined ? configRestitution : 0.8;
        }

        rotation: (360 * angle / 6.28)
        svg: KSvg.Svg { imagePath: Qt.resolvedUrl("../images/bball.svgz") }

        onXChanged: !ballDragHandler.active || (ballDragHandler.globalMouseX = ball.parent.mapToGlobal(ball.x + ballDragHandler.centroid.position.x, ball.y + ballDragHandler.centroid.position.y).x)
        onYChanged: !ballDragHandler.active || (ballDragHandler.globalMouseY = ball.parent.mapToGlobal(ball.x + ballDragHandler.centroid.position.x, ball.y + ballDragHandler.centroid.position.y).y)

        onBouncingChanged: {
            if (bouncing) {
                everBounced = true;
            } else {
                physicsTick.stop();
                angle = 0;
            }
        }

        //--------------------------------------------------
        // Bounce physics simulation
        // Plasma 6: Uses Screen properties and panel detection for bounds
        //--------------------------------------------------
        function bounce() {
            // While dragging, just track the mouse position and update time
            if (ballDragHandler.active) {
                // Position tracking happens in DragHandler.onCentroidChanged
                time = new Date().getTime();
                return;
            }

            if (!time) {
                time = new Date().getTime();
            }

            var dT = Math.min((new Date().getTime() - time) / 1000.0, 0.5);
            time = new Date().getTime();

            if (plasmoid.configuration.autoBounce && Math.random() < 1.0/35) {
                var strength = plasmoid.configuration.autoBounceStrength;
                velocity = Qt.vector2d(velocity.x + (((Math.random() * 1000) - 500) * strength * (0.5/main.devicePixelRatio)),
                                       velocity.y + (((Math.random() * 1000) - 500) * strength * (0.5/main.devicePixelRatio)));
            }

            // Apply gravity (uses available screen height for scaling, like Plasma 5)
            var gravityForce = availableScreenRect.height * gravity * dT;
            velocity = Qt.vector2d(velocity.x, velocity.y + gravityForce);

            // Apply friction (air resistance)
            velocity = Qt.vector2d(velocity.x * (1.0 - 2 * friction * dT), velocity.y * (1.0 - 2 * friction * dT));

            // Calculate new position using devicePixelRatio for proper scaling
            var newX = x + ((velocity.x * dT) / main.devicePixelRatio);
            var newY = y + ((velocity.y * dT) / main.devicePixelRatio);

            var collision = false;
            var bottom = false;

            // Bounce off bottom boundary
            if ((newY + height) >= main.boundsBottom && velocity.y > 0) {
                newY = main.boundsBottom - height;
                velocity = Qt.vector2d(velocity.x, velocity.y * -restitution);
                angularVelocity = velocity.x / (width / 2);
                collision = true;
                bottom = true;
            }

            // Bounce off top boundary
            if (newY <= main.boundsTop && velocity.y < 0) {
                newY = main.boundsTop;
                velocity = Qt.vector2d(velocity.x, velocity.y * -restitution);
                angularVelocity = -velocity.x / (width / 2);
                collision = true;
            }

            // Bounce off right boundary
            if ((newX + width) >= main.boundsRight && velocity.x > 0) {
                newX = main.boundsRight - width - 0.1;
                velocity = Qt.vector2d(velocity.x * -restitution, velocity.y);
                angularVelocity = -velocity.y / (width / 2);

                if (bottom) {
                    velocity = Qt.vector2d(0, velocity.y);
                }

                collision = true;
            }

            // Bounce off left boundary
            if (newX <= main.boundsLeft && velocity.x < 0) {
                newX = main.boundsLeft + 0.1;
                velocity = Qt.vector2d(velocity.x * -restitution, velocity.y);
                angularVelocity = velocity.y / (width / 2);

                if (bottom) {
                    velocity = Qt.vector2d(0, velocity.y);
                }

                collision = true;
            }

            angularVelocity = angularVelocity * (0.9999 - 2 * friction * dT);

            // Only stop if auto-bounce is off AND velocity is very low
            if (!plasmoid.configuration.autoBounce
                && velocity.length() < 10
                && Math.abs(angularVelocity) < 0.1
                && Math.abs(newY - (main.boundsBottom - height)) < 1) {  // Only stop if resting on ground
                    physicsTick.stop();
                    return;
                }

                // Play collision sound
                var playSound = plasmoid.configuration.playSound;
            var maxSounds = plasmoid.configuration.maxConcurrentSounds || 2;

            if (playSound && collision && main.collisionSounds < maxSounds && (velocity.x || velocity.y) && Math.abs(angularVelocity) && Math.round(newY) != Math.round(y)) {
                collisionSoundComponent.createObject(main);
            }

            x = newX;
            y = newY;
            angle += angularVelocity * dT;
        }

        states: [
            State {
                name: "resting"
                when: !ball.bouncing

                ParentChange {
                    target: ball
                    parent: main
                }

                AnchorChanges {
                    target: ball
                    anchors.horizontalCenter: main.horizontalCenter
                    anchors.verticalCenter: main.verticalCenter
                }

                PropertyChanges {
                    target: ball
                    z: 0
                }
            },
            State {
                name: "bouncing"
                when: ball.bouncing

                ParentChange {
                    target: ball
                    parent: {
                        // Plasma 6: Walk up parent chain to find desktop containment
                        // The parent hierarchy depth can vary, so we search dynamically
                        var item = main;
                        var maxDepth = 20;  // Safety limit to prevent infinite loops
                        var depth = 0;

                        // Walk up until we find an item that looks like the desktop containment
                        // (roughly screen-sized with 90% or more of screen dimensions)
                        while (item && item.parent && depth < maxDepth) {
                            item = item.parent;
                            depth++;

                            if (item.width >= main.fullScreenWidth * 0.9 &&
                                item.height >= main.fullScreenHeight * 0.9) {
                                return item;
                                }
                        }

                        // Fallback to whatever we found at the top
                        return item || main.parent || main;
                    }
                }

                AnchorChanges {
                    target: ball
                    anchors.horizontalCenter: undefined
                    anchors.verticalCenter: undefined
                }

                PropertyChanges {
                    target: ball
                    z: 999
                }
            }
        ]

        //--------------------------------------------------
        // Drag hint
        //--------------------------------------------------
        Kirigami.Heading {
            id: dragHint
            anchors.fill: parent
            anchors.margins: Kirigami.Units.gridUnit
            visible: plasmoid.configuration.showHelpTexts && !ball.everBounced && !ball.bouncing && ballHoverHandler.hovered
            level: 3
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            elide: Text.ElideMiddle
            text: i18n("Drag me to\n start bouncing!")
        }
    }

    //--------------------------------------------------
    // Ball interaction handlers
    // Plasma 6: Use DragHandler, TapHandler, HoverHandler to prevent edit mode trigger
    // Note: These must be separate items that follow the ball, not children of ball
    //--------------------------------------------------
    Item {
        id: ballInteractionArea

        // Follow the ball wherever it goes (resting or bouncing)
        parent: ball.parent
        x: ball.x
        y: ball.y
        width: ball.width
        height: ball.height
        z: ball.z + 1  // Stay on top of the ball to capture events

        // HoverHandler for cursor changes
        HoverHandler {
            id: ballHoverHandler
            cursorShape: Qt.DragMoveCursor
        }

        // DragHandler for dragging the ball
        DragHandler {
            id: ballDragHandler
            target: ball

            property real globalMouseX: 0
            property real globalMouseY: 0
            property real mouseAtLastTickX: 0
            property real mouseAtLastTickY: 0

            xAxis.minimum: 0
            xAxis.maximum: availableScreenRect.width - ball.width
            yAxis.minimum: 0
            yAxis.maximum: availableScreenRect.height - ball.height

            onActiveChanged: {
                if (active) {
                    // Drag started - set bouncing IMMEDIATELY to break anchors
                    ball.bouncing = true;

                    // Initialize drag state
                    ball.angularVelocity = 0;
                    ball.velocity = Qt.vector2d(0, 0);  // Zero velocity during drag
                    ball.time = new Date().getTime();

                    // Initialize global mouse position tracking
                    var globalPos = ball.parent.mapToGlobal(ball.x + centroid.position.x, ball.y + centroid.position.y);
                    globalMouseX = globalPos.x;
                    globalMouseY = globalPos.y;
                    mouseAtLastTickX = globalMouseX;
                    mouseAtLastTickY = globalMouseY;

                    // Ensure physics timer is running
                    if (!physicsTick.running) {
                        physicsTick.start();
                    }
                } else {
                    // Drag ended - calculate throw velocity
                    var globalPos = ball.parent.mapToGlobal(ball.x + centroid.position.x, ball.y + centroid.position.y);
                    var step = Math.max(physicsTick.interval / 1000, 0.001);

                    var velocityX = (globalPos.x - mouseAtLastTickX) / step;
                    var velocityY = (globalPos.y - mouseAtLastTickY) / step;

                    // If the velocity calculation failed, just use gravity
                    if (isNaN(velocityX)) velocityX = 0;
                    if (isNaN(velocityY)) velocityY = 0;

                    ball.velocity = Qt.vector2d(velocityX, velocityY);

                    // Reset time so physics starts fresh
                    ball.time = new Date().getTime();

                    // Make sure physics keeps running
                    if (!physicsTick.running) {
                        physicsTick.start();
                    }
                }
            }

            onCentroidChanged: {
                if (active) {
                    // Update global mouse position during drag
                    var globalPos = ball.parent.mapToGlobal(ball.x + centroid.position.x, ball.y + centroid.position.y);
                    globalMouseX = globalPos.x;
                    globalMouseY = globalPos.y;
                }
            }
        }

        // Helper to track mouse position during physics ticks while dragging
        Connections {
            target: physicsTick
            enabled: ballDragHandler.active
            function onTriggered() {
                ballDragHandler.mouseAtLastTickX = ballDragHandler.globalMouseX;
                ballDragHandler.mouseAtLastTickY = ballDragHandler.globalMouseY;
            }
        }

        // TapHandler for single clicks - fires ball away from click point
        TapHandler {
            id: ballTapHandler
            gesturePolicy: TapHandler.DragThreshold

            onTapped: (eventPoint, button) => {
                // Don't fire if we just finished dragging - DragHandler sets velocity
                if (ballDragHandler.active) {
                    return;
                }

                if (!ball.bouncing) {
                    ball.bouncing = true;
                }

                // Calculate direction away from click point
                var clickX = eventPoint.position.x;
                var clickY = eventPoint.position.y;
                var centerX = ball.width / 2;
                var centerY = ball.height / 2;

                // Vector from click point to ball center
                var dirX = centerX - clickX;
                var dirY = centerY - clickY;

                // Normalize and scale to create launch velocity
                var magnitude = Math.sqrt(dirX * dirX + dirY * dirY);
                if (magnitude > 0) {
                    dirX /= magnitude;
                    dirY /= magnitude;
                }

                // Launch with a strong velocity (adjust multiplier as needed)
                var launchSpeed = 5000;
                ball.velocity = Qt.vector2d(dirX * launchSpeed, dirY * launchSpeed);
                ball.angularVelocity = (dirX * launchSpeed) / (ball.width / 2);

                // Reset time so physics starts fresh
                ball.time = new Date().getTime();

                // Ensure physics timer is running
                if (!physicsTick.running) {
                    physicsTick.start();
                }
            }
        }
    }
}

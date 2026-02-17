/***************************************************************************
 *   Copyright (C) 2014 by Eike Hein <hein@kde.org>                        *
 *   Copyright (C) 2026 by Filip Fila <filipfila.kde@gmail.com>            *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

/*
 * PLASMA 6 CONFIG UI PORTING NOTES:
 *
 * Major changes from Plasma 5 config pages:
 *
 * 1. BASE COMPONENT:
 *    - Plasma 5: Item or ColumnLayout with property aliases
 *    - Plasma 6: KCM.SimpleKCM (requires org.kde.kcmutils import)
 *
 * 2. LAYOUT:
 *    - Plasma 5: GroupBox with nested layouts
 *    - Plasma 6: Kirigami.FormLayout with section headers
 *    - Use Kirigami.FormData.isSection for section dividers
 *    - Use Kirigami.FormData.label for field labels
 *
 * 3. CONTROLS:
 *    - Must qualify with QQC2. prefix (QtQuick.Controls as QQC2)
 *    - GroupBox checkable sections → separate CheckBox controls
 *
 * 4. SPINBOX DECIMALS:
 *    - Qt6 SpinBox doesn't have a "decimals" property
 *    - Must implement custom textFromValue/valueFromText functions
 *    - Store internal value * 100 to work with integer SpinBox
 *    - Use onValueModified to write real value back to config
 *
 * 5. SLIDER:
 *    - minimumValue/maximumValue → from/to
 *    - tickmarksEnabled property removed in Qt6
 *
 * 6. DEFAULT PROPERTIES:
 *    - Plasma config system may look for cfg_*Default properties
 *    - Define them even if main.xml has defaults (harmless duplicates)
 *
 * 7. PROPERTY BINDINGS:
 *    - Simple types (bool, int, real with no conversion) → property alias
 *    - Complex types (real with conversion) → regular property with onValueModified
 */

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    // Configuration property bindings
    property real cfg_gravity
    property real cfg_friction
    property real cfg_restitution
    property alias cfg_tickLength: tickLength.value

    property alias cfg_playSound: playSound.checked
    property alias cfg_soundVolume: soundVolume.value
    property alias cfg_maxConcurrentSounds: maxConcurrentSounds.value

    property alias cfg_autoBounce: autoBounce.checked
    property alias cfg_autoBounceStrength: autoBounceStrength.value

    property alias cfg_showHelpTexts: showHelpTexts.checked

    // Function to reset all values to defaults from main.xml
    function resetToDefaults() {
        cfg_gravity = 1.5;
        cfg_friction = 0.03;
        cfg_restitution = 0.8;
        cfg_tickLength = 20;
        cfg_playSound = false;
        cfg_soundVolume = 0.5;
        cfg_maxConcurrentSounds = 2;
        cfg_autoBounce = false;
        cfg_autoBounceStrength = 50;
        cfg_showHelpTexts = true;
    }

    // Add footer with reset button (alongside OK/Apply/Cancel)
    footer: RowLayout {
        QQC2.Button {
            text: i18n("Reset to Defaults")
            icon.name: "edit-undo"
            onClicked: page.resetToDefaults()
        }

        Item {
            Layout.fillWidth: true
        }
    }

    Kirigami.FormLayout {
        // Physics Section
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Physics")
        }

        // Plasma 6: SpinBox for decimals requires custom conversion
        // Qt6 removed the "decimals" property, so we multiply by 100 internally
        QQC2.SpinBox {
            id: gravity
            Kirigami.FormData.label: i18n("Gravity:")
            from: 0
            to: 1000
            stepSize: 10
            editable: true

            property int decimals: 2

            validator: DoubleValidator {
                bottom: gravity.from / 100.0
                top: gravity.to / 100.0
                decimals: gravity.decimals
                notation: DoubleValidator.StandardNotation
            }

            // Display value as decimal (divide by 100)
            textFromValue: function(value, locale) {
                return Number(value / 100.0).toLocaleString(locale, 'f', gravity.decimals)
            }

            // Parse input text and multiply by 100 for storage
            valueFromText: function(text, locale) {
                var parsed = Number.fromLocaleString(locale, text);
                // Clamp to valid range
                parsed = Math.max(gravity.from / 100.0, Math.min(gravity.to / 100.0, parsed));
                return Math.round(parsed * 100);
            }

            onValueModified: cfg_gravity = value / 100.0
        }

        Binding {
            target: gravity
            property: "value"
            value: cfg_gravity * 100
            when: !gravity.activeFocus  // Don't override while user is typing
        }

        QQC2.SpinBox {
            id: friction
            Kirigami.FormData.label: i18n("Friction:")
            from: 0
            to: 100
            stepSize: 1
            editable: true

            property int decimals: 2

            validator: DoubleValidator {
                bottom: friction.from / 100.0
                top: friction.to / 100.0
                decimals: friction.decimals
                notation: DoubleValidator.StandardNotation
            }

            // Display value as decimal (divide by 100)
            textFromValue: function(value, locale) {
                return Number(value / 100.0).toLocaleString(locale, 'f', friction.decimals)
            }

            // Parse input text and multiply by 100 for storage
            valueFromText: function(text, locale) {
                var parsed = Number.fromLocaleString(locale, text);
                // Clamp to valid range
                parsed = Math.max(friction.from / 100.0, Math.min(friction.to / 100.0, parsed));
                return Math.round(parsed * 100);
            }

            onValueModified: cfg_friction = value / 100.0
        }

        Binding {
            target: friction
            property: "value"
            value: cfg_friction * 100
            when: !friction.activeFocus
        }

        QQC2.SpinBox {
            id: restitution
            Kirigami.FormData.label: i18n("Restitution:")
            from: 0
            to: 100
            stepSize: 5
            editable: true

            property int decimals: 2

            validator: DoubleValidator {
                bottom: restitution.from / 100.0
                top: restitution.to / 100.0
                decimals: restitution.decimals
                notation: DoubleValidator.StandardNotation
            }

            // Display value as decimal (divide by 100)
            textFromValue: function(value, locale) {
                return Number(value / 100.0).toLocaleString(locale, 'f', restitution.decimals)
            }

            // Parse input text and multiply by 100 for storage
            valueFromText: function(text, locale) {
                var parsed = Number.fromLocaleString(locale, text);
                // Clamp to valid range
                parsed = Math.max(restitution.from / 100.0, Math.min(restitution.to / 100.0, parsed));
                return Math.round(parsed * 100);
            }

            onValueModified: cfg_restitution = value / 100.0
        }

        Binding {
            target: restitution
            property: "value"
            value: cfg_restitution * 100
            when: !restitution.activeFocus
        }

        QQC2.SpinBox {
            id: tickLength
            Kirigami.FormData.label: i18n("Tick length:")
            from: 16
            to: 50
            stepSize: 1

            textFromValue: function(value, locale) {
                return value + " ms"
            }

            valueFromText: function(text, locale) {
                return parseInt(text)
            }
        }

        // Sound Section
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Sound")
        }

        QQC2.CheckBox {
            id: playSound
            text: i18n("Play collision sounds")
        }

        QQC2.Slider {
            id: soundVolume
            Kirigami.FormData.label: i18n("Volume:")
            from: 0.0
            to: 1.0
            stepSize: 0.1
            enabled: playSound.checked
        }

        QQC2.SpinBox {
            id: maxConcurrentSounds
            Kirigami.FormData.label: i18n("Max concurrent sounds:")
            from: 1
            to: 5
            stepSize: 1
            enabled: playSound.checked
        }

        // Auto-bounce Section
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Auto-bounce")
        }

        QQC2.CheckBox {
            id: autoBounce
            text: i18n("Keep ball bouncing automatically")
        }

        QQC2.Slider {
            id: autoBounceStrength
            Kirigami.FormData.label: i18n("Strength:")
            from: 0
            to: 100
            stepSize: 10
            enabled: autoBounce.checked
        }

        // Miscellaneous Section
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Miscellaneous")
        }

        QQC2.CheckBox {
            id: showHelpTexts
            text: i18n("Show help texts")
        }
    }
}

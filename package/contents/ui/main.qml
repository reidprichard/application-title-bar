/*
 * SPDX-FileCopyrightText: 2024 Anton Kharuzhy <publicantroids@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.taskmanager as TaskManager
import "utils.js" as Utils

PlasmoidItem {
    id: root

    property TaskManager.TasksModel tasksModel
    property real elementHeight: height - plasmoid.configuration.widgetMargins * 2
    property real buttonMargins: plasmoid.configuration.widgetButtonsMargins
    property real buttonWidth: plasmoid.configuration.widgetButtonsAspectRatio / 100 * buttonHeight
    property real buttonHeight: elementHeight - buttonMargins * 2
    property var widgetAlignment: plasmoid.configuration.widgetHorizontalAlignment | plasmoid.configuration.widgetVerticalAlignment
    property KWinConfig kWinConfig

    Plasmoid.constraintHints: Plasmoid.CanFillArea
    Layout.fillWidth: plasmoid.configuration.widgetFillWidth
    preferredRepresentation: fullRepresentation

    Component {
        id: widgetElementLoaderDelegate

        Loader {
            id: widgetElementLoader

            required property var modelData

            onLoaded: function() {
                Utils.copyLayoutConstraint(item, widgetElementLoader);
                item.modelData = modelData;
            }
            sourceComponent: {
                switch (modelData.type) {
                case WidgetElement.Type.WindowControlButton:
                    return windowControlButton;
                case WidgetElement.Type.WindowTitle:
                    return windowTitle;
                case WidgetElement.Type.WindowIcon:
                    return windowIcon;
                case WidgetElement.Type.Spacer:
                    return spacerIcon;
                }
            }

            Binding {
                when: status === Loader.Ready
                widgetElementLoader.visible: plasmoid.configuration.widgetElementsDisabledMode === WidgetElement.DisabledMode.Hide ? item.enabled : true
            }

            Binding {
                function itemVisible(itemEnabled) {
                    switch (plasmoid.configuration.widgetElementsDisabledMode) {
                    case WidgetElement.DisabledMode.Hide:
                        return itemEnabled;
                    case WidgetElement.DisabledMode.HideKeepSpace:
                        return itemEnabled;
                    default:
                        return true;
                    }
                }

                when: status === Loader.Ready
                target: item
                property: "visible"
                value: itemVisible(item.enabled)
            }

        }

    }

    Component {
        id: windowControlButton

        WindowControlButton {
            id: windowControlButton

            property var modelData

            Layout.alignment: root.widgetAlignment
            Layout.preferredWidth: root.buttonWidth
            Layout.preferredHeight: root.buttonHeight
            buttonType: modelData.windowControlButtonType
            themeName: plasmoid.configuration.widgetButtonsAuroraeTheme
            iconTheme: plasmoid.configuration.widgetButtonsIconsTheme
            animationDuration: plasmoid.configuration.widgetButtonsAnimation
            onActionCall: (action) => {
                return tasksModel.activeWindow.actionCall(action);
            }
            enabled: tasksModel.hasActiveWindow && tasksModel.activeWindow.actionSupported(getAction())
            toggled: tasksModel.hasActiveWindow && tasksModel.activeWindow.buttonToggled(modelData.windowControlButtonType)
        }

    }

    Component {
        id: windowIcon

        Kirigami.Icon {
            property var modelData

            height: root.elementHeight
            Layout.alignment: root.widgetAlignment
            width: height
            source: tasksModel.activeWindow.icon || "window"
            enabled: tasksModel.hasActiveWindow && !!tasksModel.activeWindow.icon

            WidgetDragHandler {
                kWinConfig: root.kWinConfig
            }

            WidgetTapHandler {
                kWinConfig: root.kWinConfig
            }

            WidgetWheelHandler {
                kWinConfig: root.kWinConfig
                orientation: Qt.Vertical
            }

            WidgetWheelHandler {
                kWinConfig: root.kWinConfig
                orientation: Qt.Horizontal
            }

        }

    }

    Component {
        id: spacerIcon

        Rectangle {
            property var modelData

            height: root.elementHeight
            Layout.alignment: root.widgetAlignment
            width: height / 3
            color: "transparent"
            enabled: tasksModel.hasActiveWindow
        }

    }

    Component {
        id: windowTitle

        PlasmaComponents.Label {
            id: windowTitleLabel

            property var modelData
            property bool empty: text === undefined || text === ""
            property bool hideEmpty: empty && plasmoid.configuration.windowTitleHideEmpty

            function titleText(activeWindow, windowTitleSource) {
                switch (windowTitleSource) {
                case 0:
                    return tasksModel.activeWindow.appName;
                case 1:
                    return tasksModel.activeWindow.decoration;
                case 2:
                    return tasksModel.activeWindow.genericAppName;
                }
            }

            Layout.leftMargin: !hideEmpty ? plasmoid.configuration.windowTitleMarginsLeft : 0
            Layout.topMargin: !hideEmpty ? plasmoid.configuration.windowTitleMarginsTop : 0
            Layout.bottomMargin: !hideEmpty ? plasmoid.configuration.windowTitleMarginsBottom : 0
            Layout.rightMargin: !hideEmpty ? plasmoid.configuration.windowTitleMarginsRight : 0
            Layout.minimumWidth: plasmoid.configuration.windowTitleMinimumWidth
            Layout.maximumWidth: !hideEmpty ? plasmoid.configuration.windowTitleMaximumWidth : 0
            Layout.alignment: root.widgetAlignment
            Layout.fillWidth: plasmoid.configuration.widgetFillWidth
            text: titleText(tasksModel.activeWindow, plasmoid.configuration.windowTitleSource) || plasmoid.configuration.windowTitleUndefined
            font.pointSize: plasmoid.configuration.windowTitleFontSize
            font.bold: plasmoid.configuration.windowTitleFontBold
            fontSizeMode: plasmoid.configuration.windowTitleFontSizeMode
            maximumLineCount: 1
            elide: Text.ElideRight
            wrapMode: Text.WrapAnywhere
            enabled: tasksModel.hasActiveWindow

            WidgetDragHandler {
                kWinConfig: root.kWinConfig
            }

            WidgetTapHandler {
                kWinConfig: root.kWinConfig
            }

            WidgetWheelHandler {
                kWinConfig: root.kWinConfig
                orientation: Qt.Vertical
            }

            WidgetWheelHandler {
                kWinConfig: root.kWinConfig
                orientation: Qt.Horizontal
            }

        }

    }

    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        active: tasksModel.hasActiveWindow
        mainText: tasksModel.activeWindow.genericAppName || ""
    }

    kWinConfig: KWinConfig {
        Component.onCompleted: updateKWinShortcutNames()
    }

    tasksModel: ActiveTasksModel {
        id: tasksModel
    }

    fullRepresentation: RowLayout {
        id: widgetRow

        spacing: plasmoid.configuration.widgetSpacing
        Layout.margins: plasmoid.configuration.widgetMargins
        Layout.fillWidth: plasmoid.configuration.widgetFillWidth

        Rectangle {
            id: emptyWidgetPlaceholder

            color: "transparent"
            Layout.maximumWidth: Kirigami.Units.smallSpacing
            Layout.minimumWidth: Kirigami.Units.smallSpacing
            visible: widgetRow.Layout.minimumWidth <= Kirigami.Units.smallSpacing
        }

        Repeater {
            id: titleBarList

            property var elements: plasmoid.configuration.widgetElements

            onElementsChanged: function() {
                let array = [];
                for (var i = 0; i < elements.length; i++) {
                    array.push(Utils.widgetElementModelFromName(elements[i]));
                }
                model = array;
            }
            model: []
            delegate: widgetElementLoaderDelegate
        }

    }

}

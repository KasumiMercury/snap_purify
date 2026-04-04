pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import snap_purify

Window {
    id: root
    width: 800
    height: 600
    visible: true
    title: ImageManager.hasImage
           ? qsTr("snap_purify — %1").arg(ImageManager.fileName)
           : qsTr("snap_purify")
    color: Theme.windowBg

    readonly property real zoomMinLog: Math.log(0.1)
    readonly property real zoomMaxLog: Math.log(20)

    function zoomToSlider(zoom) {
        return (Math.log(zoom) - zoomMinLog) / (zoomMaxLog - zoomMinLog)
    }
    function sliderToZoom(val) {
        return Math.exp(zoomMinLog + val * (zoomMaxLog - zoomMinLog))
    }

    Shortcut {
        sequence: StandardKey.Paste
        onActivated: ImageManager.loadFromClipboard()
    }

    Shortcut {
        sequence: StandardKey.Open
        onActivated: openDialog.open()
    }

    Shortcut {
        sequence: "Ctrl+Shift+S"
        enabled: ImageManager.hasImage
        onActivated: exportDialog.open()
    }

    FileDialog {
        id: openDialog
        title: qsTr("Open Image")
        fileMode: FileDialog.OpenFile
        nameFilters: [
            "Images (*.png *.jpg *.jpeg *.bmp *.gif *.webp *.tiff *.tif *.svg)"
        ]
        onAccepted: ImageManager.loadFromFile(selectedFile)
    }

    FileDialog {
        id: exportDialog
        title: qsTr("Export Image")
        fileMode: FileDialog.SaveFile
        nameFilters: [
            "PNG (*.png)",
            "JPEG (*.jpg *.jpeg)",
            "BMP (*.bmp)",
            "WebP (*.webp)"
        ]
        onAccepted: ImageProcessor.exportImage(selectedFile)
    }

    DropArea {
        anchors.fill: parent

        onEntered: function(drag) {
            drag.accepted = true
        }

        onDropped: function(drop) {
            if (drop.hasUrls) {
                for (let i = 0; i < drop.urls.length; i++) {
                    if (ImageManager.isAcceptedFormat(drop.urls[i])) {
                        ImageManager.loadFromFile(drop.urls[i])
                        break
                    }
                }
            }
        }

        // --- Top toolbar ---
        Rectangle {
            id: topToolbar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 36
            color: Theme.panelBg
            z: 1

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: Theme.controlBg
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Rectangle {
                    width: openRow.width + 12; height: 24
                    radius: 4
                    color: openMa.containsMouse ? Theme.controlHoverBg : Theme.controlBg
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        id: openRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "\u2B06"
                            color: Theme.textPrimary
                            font.pixelSize: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: qsTr("Open")
                            color: Theme.textPrimary
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        id: openMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: openDialog.open()
                    }
                }

                Rectangle {
                    width: exportRow.width + 12; height: 24
                    radius: 4
                    color: exportMa.containsMouse ? Theme.controlHoverBg : Theme.controlBg
                    visible: ImageManager.hasImage
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        id: exportRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "\u2B07"
                            color: Theme.textPrimary
                            font.pixelSize: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: qsTr("Export")
                            color: Theme.textPrimary
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        id: exportMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: exportDialog.open()
                    }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                // Theme toggle button
                Rectangle {
                    width: themeRow.width + 12; height: 24
                    radius: 4
                    color: themeMa.containsMouse ? Theme.controlHoverBg : Theme.controlBg
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        id: themeRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: Theme.isDark ? "\u263E" : "\u2600"
                            color: Theme.textPrimary
                            font.pixelSize: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: qsTr("Theme")
                            color: Theme.textPrimary
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        id: themeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Theme.isDark = !Theme.isDark
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: !ImageManager.hasImage
            text: qsTr("Drop Image")
            font.pixelSize: 24
            color: Theme.textSecondary
        }

        ImageCanvas {
            id: imageCanvas
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: topToolbar.bottom
            anchors.bottom: toolbar.top
            visible: ImageManager.hasImage
            onExportRequested: exportDialog.open()
        }

        // --- Floating marker list panel ---
        Rectangle {
            id: markerListPanel
            visible: false
            x: 16
            y: 16
            width: 240
            height: 300
            z: 10
            color: Theme.panelBg
            border.color: Theme.borderColor
            border.width: 1
            radius: 6

            readonly property real minW: 180
            readonly property real minH: 150

            // Title bar
            Rectangle {
                id: panelTitleBar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 28
                color: Theme.titleBarBg
                radius: 6

                // Square off bottom corners
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 6
                    color: parent.color
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Markers")
                    color: Theme.textPrimary
                    font.pixelSize: 12
                    font.bold: true
                }

                // Close button
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20; height: 20
                    radius: 3
                    color: closeMa.containsMouse ? Theme.destructive : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "\u2715"
                        color: Theme.textPrimary
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: closeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: markerListPanel.visible = false
                    }
                }

                // Drag to move
                MouseArea {
                    anchors.fill: parent
                    anchors.rightMargin: 28
                    cursorShape: Qt.SizeAllCursor
                    property real dragStartX: 0
                    property real dragStartY: 0
                    property real origX: 0
                    property real origY: 0

                    onPressed: function(mouse) {
                        let pos = mapToItem(markerListPanel.parent, mouse.x, mouse.y)
                        dragStartX = pos.x
                        dragStartY = pos.y
                        origX = markerListPanel.x
                        origY = markerListPanel.y
                    }
                    onPositionChanged: function(mouse) {
                        if (!pressed) return
                        let pos = mapToItem(markerListPanel.parent, mouse.x, mouse.y)
                        let container = markerListPanel.parent
                        let newX = origX + (pos.x - dragStartX)
                        let newY = origY + (pos.y - dragStartY)
                        markerListPanel.x = Math.max(0, Math.min(newX, container.width - markerListPanel.width))
                        markerListPanel.y = Math.max(0, Math.min(newY, container.height - markerListPanel.height))
                    }
                }
            }

            // Marker list
            ListView {
                id: markerListView
                anchors.top: panelTitleBar.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 1
                anchors.bottomMargin: 12
                clip: true
                model: MarkerModel

                ScrollBar.vertical: ScrollBar {
                    id: markerScrollBar
                    policy: ScrollBar.AsNeeded

                    contentItem: Rectangle {
                        implicitWidth: 6
                        radius: 3
                        color: markerScrollBar.pressed ? Theme.scrollbarPressed
                            : markerScrollBar.hovered ? Theme.scrollbarHover : Theme.scrollbarDefault
                    }

                    background: Rectangle {
                        implicitWidth: 6
                        color: "transparent"
                    }
                }

                delegate: Rectangle {
                    required property int index
                    required property int markerId
                    required property real markerX
                    required property real markerY
                    required property real markerWidth
                    required property real markerHeight
                    required property int markerShapeType
                    required property int markerMode

                    readonly property var modeLabels: ["Fill", "Mosaic", "Crop", "Cutout"]

                    width: markerListView.width
                    height: 32
                    color: MarkerModel.selectedMarkerId === markerId
                        ? Theme.selectionBg : (listItemMa.containsMouse ? Theme.controlBg : "transparent")

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Marker #" + parent.markerId
                        color: MarkerModel.selectedMarkerId === parent.markerId ? Theme.accent : Theme.textPrimary
                        font.pixelSize: 12
                        font.bold: MarkerModel.selectedMarkerId === parent.markerId
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: parent.modeLabels[parent.markerMode] || ""
                        color: Theme.textSecondary
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: listItemMa
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton) {
                                listMarkerMenu.targetMarkerId = parent.markerId
                                listMarkerMenu.targetShapeType = parent.markerShapeType
                                listMarkerMenu.popup()
                            } else {
                                MarkerModel.selectedMarkerId = parent.markerId
                            }
                        }
                    }
                }
            }

            MarkerContextMenu {
                id: listMarkerMenu
                targetMarkerId: -1
                showGlobalActions: false
                onAdjustCornerRadiusRequested: function(markerId) {
                    imageCanvas.openRadiusPopup(markerId)
                }
                onSelectModeRequested: function(markerId) {
                    imageCanvas.openModePopup(markerId)
                }
            }

            // Resize handle (bottom-right corner)
            Rectangle {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: 14; height: 14
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "\u25E2"
                    color: resizeMa.containsMouse ? Theme.scrollbarHover : Theme.borderColor
                    font.pixelSize: 12
                }

                MouseArea {
                    id: resizeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.SizeFDiagCursor
                    property real dragStartX: 0
                    property real dragStartY: 0
                    property real origW: 0
                    property real origH: 0

                    onPressed: function(mouse) {
                        let pos = mapToItem(markerListPanel.parent, mouse.x, mouse.y)
                        dragStartX = pos.x
                        dragStartY = pos.y
                        origW = markerListPanel.width
                        origH = markerListPanel.height
                    }
                    onPositionChanged: function(mouse) {
                        if (!pressed) return
                        let pos = mapToItem(markerListPanel.parent, mouse.x, mouse.y)
                        markerListPanel.width = Math.max(markerListPanel.minW, origW + (pos.x - dragStartX))
                        markerListPanel.height = Math.max(markerListPanel.minH, origH + (pos.y - dragStartY))
                    }
                }
            }
        }

        // --- Bottom toolbar ---
        Rectangle {
            id: toolbar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 36
            color: Theme.panelBg
            visible: ImageManager.hasImage

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 1
                color: Theme.controlBg
            }

            // Left side buttons
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                // Marker list toggle
                Rectangle {
                    width: markerCountText.width + 16
                    height: 24
                    radius: 4
                    color: markerCountMa.containsMouse ? Theme.controlHoverBg : Theme.controlBg
                    visible: MarkerModel.count > 0

                    Text {
                        id: markerCountText
                        anchors.centerIn: parent
                        text: qsTr("%1 Markers").arg(MarkerModel.count)
                        color: markerListPanel.visible ? Theme.accent : Theme.textPrimary
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: markerCountMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: markerListPanel.visible = !markerListPanel.visible
                    }
                }

                // Preview toggle
                Rectangle {
                    width: previewToggleText.width + 16
                    height: 24
                    radius: 4
                    color: previewToggleMa.containsMouse ? Theme.controlHoverBg : Theme.controlBg

                    Text {
                        id: previewToggleText
                        anchors.centerIn: parent
                        text: ImageProcessor.previewEnabled ? qsTr("Hide Preview") : qsTr("Show Preview")
                        color: ImageProcessor.previewEnabled ? Theme.accent : Theme.textPrimary
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: previewToggleMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ImageProcessor.previewEnabled = !ImageProcessor.previewEnabled
                    }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                // Zoom percentage
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(imageCanvas.zoomLevel * 100) + "%"
                    color: Theme.textPrimary
                    font.pixelSize: 12
                    width: 40
                    horizontalAlignment: Text.AlignRight
                }

                // Zoom out button
                Rectangle {
                    width: 24; height: 24
                    radius: 4
                    color: zoomOutMa.containsMouse ? Theme.controlHoverBg : Theme.controlBg
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "\u2212"
                        color: Theme.textPrimary
                        font.pixelSize: 16
                    }
                    MouseArea {
                        id: zoomOutMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: imageCanvas.zoomAt(
                            imageCanvas.width / 2, imageCanvas.height / 2, 1 / 1.25)
                    }
                }

                // Zoom slider
                Slider {
                    id: zoomSlider
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 150
                    implicitHeight: 24
                    from: 0; to: 1
                    stepSize: 0
                    padding: 0

                    onMoved: {
                        let newZoom = root.sliderToZoom(value)
                        imageCanvas.zoomAt(
                            imageCanvas.width / 2, imageCanvas.height / 2,
                            newZoom / imageCanvas.zoomLevel)
                    }

                    Connections {
                        target: imageCanvas
                        function onZoomLevelChanged() {
                            if (!zoomSlider.pressed)
                                zoomSlider.value = root.zoomToSlider(imageCanvas.zoomLevel)
                        }
                    }

                    Component.onCompleted: value = root.zoomToSlider(1.0)

                    background: Rectangle {
                        implicitWidth: 150
                        implicitHeight: 4
                        y: (zoomSlider.height - height) / 2
                        width: zoomSlider.availableWidth
                        height: 4
                        radius: 2
                        color: Theme.sliderTrack

                        Rectangle {
                            width: zoomSlider.visualPosition * parent.width
                            height: parent.height
                            radius: 2
                            color: Theme.accent
                        }
                    }

                    handle: Rectangle {
                        x: zoomSlider.visualPosition * (zoomSlider.availableWidth - width)
                        y: (zoomSlider.height - height) / 2
                        width: 14; height: 14
                        radius: 7
                        color: zoomSlider.pressed ? Theme.sliderHandlePressed : Theme.sliderHandle
                    }
                }

                // Zoom in button
                Rectangle {
                    width: 24; height: 24
                    radius: 4
                    color: zoomInMa.containsMouse ? Theme.controlHoverBg : Theme.controlBg
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: Theme.textPrimary
                        font.pixelSize: 16
                    }
                    MouseArea {
                        id: zoomInMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: imageCanvas.zoomAt(
                            imageCanvas.width / 2, imageCanvas.height / 2, 1.25)
                    }
                }

                // Reset button
                Rectangle {
                    width: resetText.width + 16; height: 24
                    radius: 4
                    color: resetMa.containsMouse ? Theme.controlHoverBg : Theme.controlBg
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: resetText
                        anchors.centerIn: parent
                        text: "Reset"
                        color: Theme.textPrimary
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: resetMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            imageCanvas.zoomLevel = 1.0
                            imageCanvas.panX = 0
                            imageCanvas.panY = 0
                        }
                    }
                }

            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import snap_purify

Window {
    id: root
    width: 800
    height: 600
    visible: true
    title: ImageManager.hasImage
           ? qsTr("snap_purify — %1").arg(ImageManager.fileName)
           : qsTr("snap_purify")
    color: "#1e1e1e"

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

        Text {
            anchors.centerIn: parent
            visible: !ImageManager.hasImage
            text: qsTr("Drop Image")
            font.pixelSize: 24
            color: "#888888"
        }

        ImageCanvas {
            id: imageCanvas
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: toolbar.top
            visible: ImageManager.hasImage
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
            color: "#2a2a2a"
            border.color: "#555555"
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
                color: "#333333"
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
                    text: qsTr("マーカー一覧")
                    color: "#cccccc"
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
                    color: closeMa.containsMouse ? "#aa3333" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "\u2715"
                        color: "#cccccc"
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
                        color: markerScrollBar.pressed ? "#888888"
                            : markerScrollBar.hovered ? "#777777" : "#555555"
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

                    width: markerListView.width
                    height: 32
                    color: MarkerModel.selectedMarkerId === markerId
                        ? "#003d66" : (listItemMa.containsMouse ? "#3a3a3a" : "transparent")

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Marker #" + parent.markerId
                        color: MarkerModel.selectedMarkerId === parent.markerId ? "#00aaff" : "#cccccc"
                        font.pixelSize: 12
                        font.bold: MarkerModel.selectedMarkerId === parent.markerId
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "(%1, %2, %3\u00d7%4)"
                            .arg(Math.round(parent.markerX))
                            .arg(Math.round(parent.markerY))
                            .arg(Math.round(parent.markerWidth))
                            .arg(Math.round(parent.markerHeight))
                        color: "#888888"
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
                    color: resizeMa.containsMouse ? "#888888" : "#555555"
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
            color: "#2a2a2a"
            visible: ImageManager.hasImage

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 1
                color: "#3a3a3a"
            }

            // Marker list toggle (left side)
            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: markerCountText.width + 16
                height: 24
                radius: 4
                color: markerCountMa.containsMouse ? "#4a4a4a" : "#3a3a3a"
                visible: MarkerModel.count > 0

                Text {
                    id: markerCountText
                    anchors.centerIn: parent
                    text: qsTr("%1 個のマーカー").arg(MarkerModel.count)
                    color: markerListPanel.visible ? "#00aaff" : "#cccccc"
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

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                // Zoom percentage
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(imageCanvas.zoomLevel * 100) + "%"
                    color: "#cccccc"
                    font.pixelSize: 12
                    width: 40
                    horizontalAlignment: Text.AlignRight
                }

                // Zoom out button
                Rectangle {
                    width: 24; height: 24
                    radius: 4
                    color: zoomOutMa.containsMouse ? "#4a4a4a" : "#3a3a3a"
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "\u2212"
                        color: "#cccccc"
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
                        color: "#4a4a4a"

                        Rectangle {
                            width: zoomSlider.visualPosition * parent.width
                            height: parent.height
                            radius: 2
                            color: "#00aaff"
                        }
                    }

                    handle: Rectangle {
                        x: zoomSlider.visualPosition * (zoomSlider.availableWidth - width)
                        y: (zoomSlider.height - height) / 2
                        width: 14; height: 14
                        radius: 7
                        color: zoomSlider.pressed ? "#ffffff" : "#cccccc"
                    }
                }

                // Zoom in button
                Rectangle {
                    width: 24; height: 24
                    radius: 4
                    color: zoomInMa.containsMouse ? "#4a4a4a" : "#3a3a3a"
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: "#cccccc"
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
                    color: resetMa.containsMouse ? "#4a4a4a" : "#3a3a3a"
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: resetText
                        anchors.centerIn: parent
                        text: "Reset"
                        color: "#cccccc"
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

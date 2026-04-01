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

            // Marker selector (left side)
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                ComboBox {
                    id: markerSelector
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 160
                    implicitHeight: 28
                    model: MarkerModel
                    textRole: "markerLabel"
                    valueRole: "markerId"

                    displayText: MarkerModel.selectedMarkerId >= 0
                        ? "Marker #" + MarkerModel.selectedMarkerId
                        : qsTr("マーカー選択")

                    onActivated: function(index) {
                        MarkerModel.selectedMarkerId = currentValue
                    }

                    Connections {
                        target: MarkerModel
                        function onSelectedMarkerIdChanged() {
                            if (MarkerModel.selectedMarkerId < 0) {
                                markerSelector.currentIndex = -1
                            } else {
                                markerSelector.currentIndex = markerSelector.indexOfValue(MarkerModel.selectedMarkerId)
                            }
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: MarkerModel.count > 0
                        ? qsTr("%1 個のマーカー").arg(MarkerModel.count)
                        : ""
                    color: "#888888"
                    font.pixelSize: 12
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

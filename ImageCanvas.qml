import QtQuick
import snap_purify

Item {
    id: canvas

    property int selectedMarkerIndex: -1

    // --- Coordinate conversion helpers ---
    // Display offset: where the painted image starts within the Image element
    readonly property real displayScale: img.paintedWidth > 0
        ? img.paintedWidth / ImageManager.imageWidth : 1
    readonly property real offsetX: (img.width - img.paintedWidth) / 2
    readonly property real offsetY: (img.height - img.paintedHeight) / 2

    function imageToDisplayX(ix) { return ix * displayScale + offsetX }
    function imageToDisplayY(iy) { return iy * displayScale + offsetY }
    function imageToDisplayW(iw) { return iw * displayScale }
    function imageToDisplayH(ih) { return ih * displayScale }
    function displayToImageX(dx) { return (dx - offsetX) / displayScale }
    function displayToImageY(dy) { return (dy - offsetY) / displayScale }
    function displayToImageW(dw) { return dw / displayScale }
    function displayToImageH(dh) { return dh / displayScale }

    // Clamp image-coord rect to image bounds
    function clampRect(ix, iy, iw, ih) {
        let imgW = ImageManager.imageWidth
        let imgH = ImageManager.imageHeight
        let x = Math.max(0, Math.min(ix, imgW - iw))
        let y = Math.max(0, Math.min(iy, imgH - ih))
        let w = Math.min(iw, imgW)
        let h = Math.min(ih, imgH)
        return { x: x, y: y, width: w, height: h }
    }

    Image {
        id: img
        anchors.fill: parent
        visible: ImageManager.hasImage
        source: ImageManager.hasImage
                ? "image://snapimage/current?rev=" + ImageManager.revision
                : ""
        fillMode: Image.PreserveAspectFit
        asynchronous: false
        cache: false
    }

    // --- Drawing new rectangles ---
    MouseArea {
        id: drawArea
        anchors.fill: parent
        enabled: ImageManager.hasImage

        property bool drawing: false
        property real startX: 0
        property real startY: 0

        onPressed: function(mouse) {
            // Only start drawing if click is within the painted image area
            if (mouse.x < canvas.offsetX || mouse.x > canvas.offsetX + img.paintedWidth
                || mouse.y < canvas.offsetY || mouse.y > canvas.offsetY + img.paintedHeight) {
                mouse.accepted = false
                return
            }

            canvas.selectedMarkerIndex = -1
            drawing = true
            startX = mouse.x
            startY = mouse.y
            previewRect.visible = true
            previewRect.x = mouse.x
            previewRect.y = mouse.y
            previewRect.width = 0
            previewRect.height = 0
        }

        onPositionChanged: function(mouse) {
            if (!drawing) return
            let x = Math.max(canvas.offsetX, Math.min(mouse.x, canvas.offsetX + img.paintedWidth))
            let y = Math.max(canvas.offsetY, Math.min(mouse.y, canvas.offsetY + img.paintedHeight))
            previewRect.x = Math.min(startX, x)
            previewRect.y = Math.min(startY, y)
            previewRect.width = Math.abs(x - startX)
            previewRect.height = Math.abs(y - startY)
        }

        onReleased: function(mouse) {
            if (!drawing) return
            drawing = false
            previewRect.visible = false

            // Minimum size threshold (in display pixels)
            if (previewRect.width < 5 || previewRect.height < 5) return

            let ix = canvas.displayToImageX(previewRect.x)
            let iy = canvas.displayToImageY(previewRect.y)
            let iw = canvas.displayToImageW(previewRect.width)
            let ih = canvas.displayToImageH(previewRect.height)

            // Single marker mode: replace existing
            MarkerModel.clear()
            let idx = MarkerModel.addMarker(ix, iy, iw, ih)
            canvas.selectedMarkerIndex = idx
        }
    }

    // Preview rectangle while drawing
    Rectangle {
        id: previewRect
        visible: false
        color: "transparent"
        border.color: "#00aaff"
        border.width: 2
    }

    // --- Existing markers ---
    Repeater {
        model: MarkerModel

        delegate: Item {
            id: markerDelegate
            required property int index
            required property real markerX
            required property real markerY
            required property real markerWidth
            required property real markerHeight

            readonly property bool isSelected: canvas.selectedMarkerIndex === index

            x: canvas.imageToDisplayX(markerX)
            y: canvas.imageToDisplayY(markerY)
            width: canvas.imageToDisplayW(markerWidth)
            height: canvas.imageToDisplayH(markerHeight)

            // Marker border
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: markerDelegate.isSelected ? "#00aaff" : "#ffaa00"
                border.width: 2
            }

            // Move handle (entire body)
            MouseArea {
                id: moveArea
                anchors.fill: parent
                cursorShape: Qt.SizeAllCursor

                property real dragStartX: 0
                property real dragStartY: 0
                property real origImgX: 0
                property real origImgY: 0

                onPressed: function(mouse) {
                    canvas.selectedMarkerIndex = markerDelegate.index
                    let pos = mapToItem(canvas, mouse.x, mouse.y)
                    dragStartX = pos.x
                    dragStartY = pos.y
                    origImgX = markerDelegate.markerX
                    origImgY = markerDelegate.markerY
                }

                onPositionChanged: function(mouse) {
                    let pos = mapToItem(canvas, mouse.x, mouse.y)
                    let dx = pos.x - dragStartX
                    let dy = pos.y - dragStartY
                    let newIx = origImgX + canvas.displayToImageW(dx)
                    let newIy = origImgY + canvas.displayToImageH(dy)
                    let c = canvas.clampRect(newIx, newIy, markerDelegate.markerWidth, markerDelegate.markerHeight)
                    MarkerModel.updateMarker(markerDelegate.index, c.x, c.y, c.width, c.height)
                }
            }

            // Resize handles (4 corners)
            Repeater {
                model: [
                    { corner: "tl", hAlign: "left",  vAlign: "top" },
                    { corner: "tr", hAlign: "right", vAlign: "top" },
                    { corner: "bl", hAlign: "left",  vAlign: "bottom" },
                    { corner: "br", hAlign: "right", vAlign: "bottom" },
                ]

                delegate: Rectangle {
                    id: handle
                    required property var modelData
                    width: 10
                    height: 10
                    color: markerDelegate.isSelected ? "#00aaff" : "#ffaa00"
                    visible: markerDelegate.isSelected

                    x: modelData.hAlign === "left" ? -width / 2 : markerDelegate.width - width / 2
                    y: modelData.vAlign === "top"  ? -height / 2 : markerDelegate.height - height / 2

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: (handle.modelData.corner === "tl" || handle.modelData.corner === "br")
                                     ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor

                        property real dragStartX: 0
                        property real dragStartY: 0
                        property real origIx: 0
                        property real origIy: 0
                        property real origIw: 0
                        property real origIh: 0

                        onPressed: function(mouse) {
                            dragStartX = mapToItem(canvas, mouse.x, mouse.y).x
                            dragStartY = mapToItem(canvas, mouse.x, mouse.y).y
                            origIx = markerDelegate.markerX
                            origIy = markerDelegate.markerY
                            origIw = markerDelegate.markerWidth
                            origIh = markerDelegate.markerHeight
                        }

                        onPositionChanged: function(mouse) {
                            let pos = mapToItem(canvas, mouse.x, mouse.y)
                            let ddx = pos.x - dragStartX
                            let ddy = pos.y - dragStartY
                            let didx = canvas.displayToImageW(ddx)
                            let didy = canvas.displayToImageH(ddy)

                            let nx = origIx, ny = origIy, nw = origIw, nh = origIh
                            let corner = handle.modelData.corner

                            if (corner === "tl" || corner === "bl") {
                                nx = origIx + didx
                                nw = origIw - didx
                            } else {
                                nw = origIw + didx
                            }

                            if (corner === "tl" || corner === "tr") {
                                ny = origIy + didy
                                nh = origIh - didy
                            } else {
                                nh = origIh + didy
                            }

                            // Enforce minimum size (in image pixels)
                            let minSize = 5
                            if (nw < minSize) {
                                if (corner === "tl" || corner === "bl") {
                                    nx = origIx + origIw - minSize
                                }
                                nw = minSize
                            }
                            if (nh < minSize) {
                                if (corner === "tl" || corner === "tr") {
                                    ny = origIy + origIh - minSize
                                }
                                nh = minSize
                            }

                            // Clamp to image bounds
                            nx = Math.max(0, nx)
                            ny = Math.max(0, ny)
                            if (nx + nw > ImageManager.imageWidth)
                                nw = ImageManager.imageWidth - nx
                            if (ny + nh > ImageManager.imageHeight)
                                nh = ImageManager.imageHeight - ny

                            MarkerModel.updateMarker(markerDelegate.index, nx, ny, nw, nh)
                        }
                    }
                }
            }
        }
    }

    // Delete selected marker
    Shortcut {
        sequence: "Delete"
        enabled: canvas.selectedMarkerIndex >= 0
        onActivated: {
            MarkerModel.removeMarker(canvas.selectedMarkerIndex)
            canvas.selectedMarkerIndex = -1
        }
    }

    // Deselect on Escape
    Shortcut {
        sequence: "Escape"
        enabled: canvas.selectedMarkerIndex >= 0
        onActivated: canvas.selectedMarkerIndex = -1
    }
}

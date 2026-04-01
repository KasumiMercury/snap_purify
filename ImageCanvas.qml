import QtQuick
import QtQuick.Controls
import snap_purify

Item {
    id: canvas
    clip: true

    property int selectedMarkerIndex: -1

    // --- Zoom / Pan state ---
    property real zoomLevel: 1.0
    property real panX: 0.0
    property real panY: 0.0

    // --- Derived scale and origin ---
    readonly property real baseScale: (ImageManager.hasImage && ImageManager.imageWidth > 0 && ImageManager.imageHeight > 0)
        ? Math.min(width / ImageManager.imageWidth, height / ImageManager.imageHeight) : 1
    readonly property real effectiveScale: baseScale * zoomLevel
    readonly property real imgOriginX: (width - ImageManager.imageWidth * effectiveScale) / 2 + panX
    readonly property real imgOriginY: (height - ImageManager.imageHeight * effectiveScale) / 2 + panY

    // --- Coordinate conversion helpers ---
    function imageToDisplayX(ix) { return ix * effectiveScale + imgOriginX }
    function imageToDisplayY(iy) { return iy * effectiveScale + imgOriginY }
    function imageToDisplayW(iw) { return iw * effectiveScale }
    function imageToDisplayH(ih) { return ih * effectiveScale }
    function displayToImageX(dx) { return (dx - imgOriginX) / effectiveScale }
    function displayToImageY(dy) { return (dy - imgOriginY) / effectiveScale }
    function displayToImageW(dw) { return dw / effectiveScale }
    function displayToImageH(dh) { return dh / effectiveScale }

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

    // --- Zoom at cursor position ---
    function zoomAt(mouseX, mouseY, factor) {
        let imgPtX = (mouseX - imgOriginX) / effectiveScale
        let imgPtY = (mouseY - imgOriginY) / effectiveScale
        let newZoom = Math.max(0.1, Math.min(zoomLevel * factor, 20))
        let newES = baseScale * newZoom
        let newCenterX = (width - ImageManager.imageWidth * newES) / 2
        let newCenterY = (height - ImageManager.imageHeight * newES) / 2
        panX = mouseX - imgPtX * newES - newCenterX
        panY = mouseY - imgPtY * newES - newCenterY
        zoomLevel = newZoom
    }

    Image {
        id: img
        x: canvas.imgOriginX
        y: canvas.imgOriginY
        width: ImageManager.imageWidth * canvas.effectiveScale
        height: ImageManager.imageHeight * canvas.effectiveScale
        visible: ImageManager.hasImage
        source: ImageManager.hasImage
                ? "image://snapimage/current?rev=" + ImageManager.revision
                : ""
        fillMode: Image.Stretch
        asynchronous: false
        cache: false
    }

    // --- Zoom with Ctrl+Scroll ---
    WheelHandler {
        enabled: ImageManager.hasImage
        acceptedModifiers: Qt.ControlModifier
        target: null

        onWheel: function(event) {
            let factor = event.angleDelta.y > 0 ? 1.15 : (1 / 1.15)
            canvas.zoomAt(point.position.x, point.position.y, factor)
        }
    }

    // --- Drawing new rectangles + Middle-button panning ---
    MouseArea {
        id: drawArea
        anchors.fill: parent
        enabled: ImageManager.hasImage
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        property bool drawing: false
        property real startX: 0
        property real startY: 0

        property bool panning: false
        property real panStartX: 0
        property real panStartY: 0
        property real panOrigX: 0
        property real panOrigY: 0

        onPressed: function(mouse) {
            // Middle button → pan
            if (mouse.button === Qt.MiddleButton) {
                panning = true
                panStartX = mouse.x
                panStartY = mouse.y
                panOrigX = canvas.panX
                panOrigY = canvas.panY
                cursorShape = Qt.ClosedHandCursor
                return
            }

            // Left button → draw marker
            // Only start drawing if click is within the painted image area
            if (mouse.x < canvas.imgOriginX || mouse.x > canvas.imgOriginX + img.width
                || mouse.y < canvas.imgOriginY || mouse.y > canvas.imgOriginY + img.height) {
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
            if (panning) {
                canvas.panX = panOrigX + (mouse.x - panStartX)
                canvas.panY = panOrigY + (mouse.y - panStartY)
                return
            }

            if (!drawing) return
            let x = Math.max(canvas.imgOriginX, Math.min(mouse.x, canvas.imgOriginX + img.width))
            let y = Math.max(canvas.imgOriginY, Math.min(mouse.y, canvas.imgOriginY + img.height))
            previewRect.x = Math.min(startX, x)
            previewRect.y = Math.min(startY, y)
            previewRect.width = Math.abs(x - startX)
            previewRect.height = Math.abs(y - startY)
        }

        onReleased: function(mouse) {
            if (panning) {
                panning = false
                cursorShape = Qt.ArrowCursor
                return
            }

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

            Menu {
                id: markerContextMenu
                MenuItem {
                    text: qsTr("削除")
                    onTriggered: {
                        MarkerModel.removeMarker(markerDelegate.index)
                        canvas.selectedMarkerIndex = -1
                    }
                }
            }

            // Move handle (entire body)
            MouseArea {
                id: moveArea
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.SizeAllCursor

                property real dragStartX: 0
                property real dragStartY: 0
                property real origImgX: 0
                property real origImgY: 0

                onPressed: function(mouse) {
                    if (mouse.button === Qt.RightButton) {
                        canvas.selectedMarkerIndex = markerDelegate.index
                        markerContextMenu.popup()
                        return
                    }
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

    // Reset zoom/pan with Ctrl+0
    Shortcut {
        sequence: "Ctrl+0"
        onActivated: {
            canvas.zoomLevel = 1.0
            canvas.panX = 0
            canvas.panY = 0
        }
    }
}

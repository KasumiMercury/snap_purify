import QtQuick
import QtQuick.Controls
import snap_purify

Menu {
    id: root

    required property int targetMarkerId
    property bool showMarkerActions: true
    property bool showGlobalActions: false
    property int targetShapeType: 0

    signal adjustCornerRadiusRequested(int markerId)
    signal selectModeRequested(int markerId)
    signal exportRequested()

    palette.window: Theme.panelBg
    palette.text: Theme.textPrimary
    palette.windowText: Theme.textPrimary
    palette.buttonText: Theme.textPrimary
    palette.highlight: Theme.controlHoverBg
    palette.highlightedText: Theme.textPrimary
    palette.mid: Theme.borderColor

    // --- Marker-specific actions ---
    MenuItem {
        text: root.targetShapeType === 0 ? qsTr("Make Ellipse") : qsTr("Make Rectangle")
        visible: root.showMarkerActions
        height: visible ? implicitHeight : -root.spacing
        palette.text: Theme.textPrimary
        palette.windowText: Theme.textPrimary
        palette.buttonText: Theme.textPrimary
        palette.highlightedText: Theme.textPrimary
        onTriggered: {
            let newType = root.targetShapeType === 0 ? 1 : 0
            MarkerModel.updateMarkerShapeType(root.targetMarkerId, newType)
        }
    }
    MenuItem {
        text: qsTr("Select Mode")
        visible: root.showMarkerActions
        height: visible ? implicitHeight : -root.spacing
        palette.text: Theme.textPrimary
        palette.windowText: Theme.textPrimary
        palette.buttonText: Theme.textPrimary
        palette.highlightedText: Theme.textPrimary
        onTriggered: root.selectModeRequested(root.targetMarkerId)
    }
    MenuItem {
        text: qsTr("Adjust Corner Radius")
        visible: root.showMarkerActions && root.targetShapeType === 0
        height: visible ? implicitHeight : -root.spacing
        palette.text: Theme.textPrimary
        palette.windowText: Theme.textPrimary
        palette.buttonText: Theme.textPrimary
        palette.highlightedText: Theme.textPrimary
        onTriggered: root.adjustCornerRadiusRequested(root.targetMarkerId)
    }
    MenuItem {
        text: qsTr("Delete")
        visible: root.showMarkerActions
        height: visible ? implicitHeight : -root.spacing
        palette.text: Theme.textPrimary
        palette.windowText: Theme.textPrimary
        palette.buttonText: Theme.textPrimary
        palette.highlightedText: Theme.textPrimary
        onTriggered: MarkerModel.removeMarker(root.targetMarkerId)
    }

    // --- Global actions (canvas right-click only) ---
    MenuSeparator {
        visible: root.showMarkerActions && root.showGlobalActions
        height: visible ? implicitHeight : -root.spacing
        palette.mid: Theme.borderColor
    }
    MenuItem {
        text: ImageProcessor.previewEnabled ? qsTr("Hide Preview") : qsTr("Show Preview")
        visible: root.showGlobalActions
        height: visible ? implicitHeight : -root.spacing
        palette.text: Theme.textPrimary
        palette.windowText: Theme.textPrimary
        palette.buttonText: Theme.textPrimary
        palette.highlightedText: Theme.textPrimary
        onTriggered: ImageProcessor.previewEnabled = !ImageProcessor.previewEnabled
    }
    MenuItem {
        text: qsTr("Export Image...")
        visible: root.showGlobalActions && ImageManager.hasImage
        height: visible ? implicitHeight : -root.spacing
        palette.text: Theme.textPrimary
        palette.windowText: Theme.textPrimary
        palette.buttonText: Theme.textPrimary
        palette.highlightedText: Theme.textPrimary
        onTriggered: root.exportRequested()
    }
}

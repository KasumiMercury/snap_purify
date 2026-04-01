import QtQuick
import QtQuick.Controls
import snap_purify

Menu {
    id: root

    required property int targetMarkerId
    property bool showGlobalActions: false
    property int targetShapeType: 0

    signal adjustCornerRadiusRequested(int markerId)
    signal selectModeRequested(int markerId)

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
        palette.text: Theme.textPrimary
        palette.windowText: Theme.textPrimary
        palette.buttonText: Theme.textPrimary
        palette.highlightedText: Theme.textPrimary
        onTriggered: root.selectModeRequested(root.targetMarkerId)
    }
    MenuItem {
        text: qsTr("Adjust Corner Radius")
        visible: root.targetShapeType === 0
        height: visible ? implicitHeight : -root.spacing
        palette.text: Theme.textPrimary
        palette.windowText: Theme.textPrimary
        palette.buttonText: Theme.textPrimary
        palette.highlightedText: Theme.textPrimary
        onTriggered: root.adjustCornerRadiusRequested(root.targetMarkerId)
    }
    MenuItem {
        text: qsTr("Delete")
        palette.text: Theme.textPrimary
        palette.windowText: Theme.textPrimary
        palette.buttonText: Theme.textPrimary
        palette.highlightedText: Theme.textPrimary
        onTriggered: MarkerModel.removeMarker(root.targetMarkerId)
    }

    // --- Global actions (canvas right-click only) ---
    MenuSeparator {
        visible: root.showGlobalActions
        height: visible ? implicitHeight : -root.spacing
        palette.mid: Theme.borderColor
    }
    // Future global actions go here
}

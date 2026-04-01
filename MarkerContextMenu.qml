import QtQuick
import QtQuick.Controls
import snap_purify

Menu {
    id: root

    required property int targetMarkerId
    property bool showGlobalActions: false

    signal adjustCornerRadiusRequested(int markerId)

    palette.window: Theme.panelBg
    palette.text: Theme.textPrimary
    palette.windowText: Theme.textPrimary
    palette.buttonText: Theme.textPrimary
    palette.highlight: Theme.controlHoverBg
    palette.highlightedText: Theme.textPrimary
    palette.mid: Theme.borderColor

    // --- Marker-specific actions ---
    MenuItem {
        text: qsTr("Adjust Corner Radius")
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

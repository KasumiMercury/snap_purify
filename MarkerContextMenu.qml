import QtQuick
import QtQuick.Controls
import snap_purify

Menu {
    id: root

    required property int targetMarkerId
    property bool showGlobalActions: false

    // --- Marker-specific actions ---
    MenuItem {
        text: qsTr("削除")
        onTriggered: MarkerModel.removeMarker(root.targetMarkerId)
    }

    // --- Global actions (canvas right-click only) ---
    MenuSeparator {
        visible: root.showGlobalActions
        height: visible ? implicitHeight : -root.spacing
    }
    // Future global actions go here
}

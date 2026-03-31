import QtQuick
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
            anchors.fill: parent
            visible: ImageManager.hasImage
        }
    }
}

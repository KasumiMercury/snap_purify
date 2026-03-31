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

        Image {
            anchors.fill: parent
            visible: ImageManager.hasImage
            source: ImageManager.hasImage
                    ? "image://snapimage/current?rev=" + ImageManager.revision
                    : ""
            fillMode: Image.PreserveAspectFit
            asynchronous: false
            cache: false
        }
    }
}

import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: root
    width: 640
    height: 480
    visible: true
    color: "black"
    title: qsTr("BWApp")

    Loader {
        id: appLoader
        anchors.fill: parent
        source: "Splash.qml"
    }

    Connections {
        target: appLoader.item 
        ignoreUnknownSignals: true
        function onFinished() {
            appLoader.source = "Start.qml"
        }
    }
}

import QtQuick
import QtQuick.Controls
import BWApp

ApplicationWindow {
    id: root
    width: 448
    height: 896
    visible: true
    color: Theme.bg
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
            appLoader.source = "Start.qml";
        }
    }
}

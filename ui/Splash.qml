import QtQuick
import QtQuick.Effects

Rectangle {
    id: root
    anchors.fill: parent
    color: "black"

    property color logoColor: "#c0c0c0"
    signal finished();

    Rectangle {
        id: bgCircle
        anchors.centerIn: parent
        width: parent.width * 2.5
        height: width
        radius: width / 2
        color: "#c0c0c0" 
        scale: 1

        NumberAnimation on scale {
            from: 1.0
            to: 0.25
            duration: 1200
            easing.type: Easing.InOutQuart
            running: true
        }
    }

    Column {
        id: contentGroup
        anchors.centerIn: parent
        spacing: 15
        opacity: 1

        // FIX 1: Give the Item a size so the Column can space it correctly
        Item {
            width: 100
            height: 100
            anchors.horizontalCenter: parent.horizontalCenter

            Image {
                id: logo
                source: "qrc:qt/qml/BWApp/assets/images/logo.svg"
                anchors.fill: parent
                sourceSize.width: width
                sourceSize.height: height
                fillMode: Image.PreserveAspectFit
                visible: false
            }

            MultiEffect {
                id: effect
                source: logo
                anchors.fill: parent
                colorization: 1.0
                brightness: 1.0
                colorizationColor: root.logoColor
            }
        }

        Text {
            text: "BIOWATCH"
            color: root.logoColor
            font.pixelSize: 28
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    SequentialAnimation {
        running: true
        PauseAnimation { duration: 600 }

        ColorAnimation {
            target: root
            property: "logoColor"
            from: root.logoColor 
            to: "black"
            duration: 1000
        }

        onFinished: {
            root.finished()
        }
    }
}

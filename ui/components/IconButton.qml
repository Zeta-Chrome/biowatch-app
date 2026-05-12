import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Button {
    id: root
    property string dashboard: "None"
    property color iconColor: "gray"
    property alias iconSource: icon.source
    property real buttonRadius: 0

    hoverEnabled: Qt.platform.os !== "android"

    background: Rectangle {
        color: root.pressed ? "#3FFFFFFF" : (root.hovered ? "#1FFFFFFF" : "#00000000")
        radius: parent.width * root.buttonRadius
    }

    Image {
        id: icon
        anchors.centerIn: parent
        width: parent.width * 0.8
        height: parent.height * 0.8
        fillMode: Image.PreserveAspectFit
        layer.enabled: true
        smooth: true
        mipmap: true
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: root.iconColor
        }
    }
}

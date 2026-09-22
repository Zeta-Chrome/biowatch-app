import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Button {
    id: root
    property string dashboard: "None"
    property color iconColor: "gray"
    property alias iconSource: icon.source
    property real buttonRadius: 0

    // When true, the icon pulses in opacity - used for "scanning/connecting" states.
    property bool blinking: false
    property int blinkDurationMs: 700

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

        SequentialAnimation on opacity {
            running: root.blinking
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.25; duration: root.blinkDurationMs }
            NumberAnimation { from: 0.25; to: 1.0; duration: root.blinkDurationMs }
        }

        // Snap back to fully opaque the moment blinking stops.
        onOpacityChanged: {}
        Connections {
            target: root
            function onBlinkingChanged() { if (!root.blinking) icon.opacity = 1.0 }
        }
    }
}

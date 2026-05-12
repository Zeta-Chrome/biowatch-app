import QtQuick
import QtQuick.Layouts

Column {
    id: statItem
    property string label: ""
    property string value: "0"
    property string unit: ""
    spacing: 4
    Layout.fillWidth: true

    Text {
        text: statItem.label
        font.pixelSize: 12
        font.bold: true
        font.letterSpacing: 1.5
        color: "#666666"
        anchors.horizontalCenter: parent.horizontalCenter
    }
    Row {
        spacing: 2
        anchors.horizontalCenter: parent.horizontalCenter
        Text {
            text: statItem.value
            font.pixelSize: 36
            font.weight: Font.DemiBold
            color: "white"
        }
        Text {
            text: statItem.unit
            font.pixelSize: 14
            color: "#444444"
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
        }
    }
}

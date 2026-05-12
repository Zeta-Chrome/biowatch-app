import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "black"

    property string pageTitle: "Info"

    Flickable {
        anchors.fill: parent
        contentHeight: contentColumn.height + 40
        clip: true

        ColumnLayout {
            id: contentColumn
            width: parent.width - 40
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: "ABOUT BIOWATCH"
                    font.pixelSize: 14
                    font.bold: true
                    color: "#666666"
                }
                Text {
                    text: "An advanced health monitoring system designed for real-time tracking and health data analysis."
                    color: "#c0c0c0"
                    font.pixelSize: 16
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: specGrid.height + 30
                color: "#111111"
                radius: 10

                GridLayout {
                    id: specGrid
                    anchors.centerIn: parent
                    width: parent.width - 30
                    columns: 2
                    rowSpacing: 15

                    // Info Rows
                    InfoLabel {
                        label: "Firmware"
                        value: "v1.0.4-beta"
                    }
                    InfoLabel {
                        label: "MAC Address"
                        value: "AA:BB:CC:11:22:33"
                    }
                    InfoLabel {
                        label: "Device ID"
                        value: "BW-99042-X"
                    }
                    InfoLabel {
                        label: "Hardware"
                        value: "Rev 2.0"
                    }
                }
            }

            Item {
                Layout.preferredHeight: 20
            } // Bottom Padding
        }
    }

    // Helper Component
    component InfoLabel: ColumnLayout {
        id: infoLabel
        property string label: ""
        property string value: ""
        spacing: 2
        Layout.fillWidth: true
        Text {
            text: infoLabel.label
            color: "#666666"
            font.pixelSize: 12
            font.bold: true
        }
        Text {
            text: infoLabel.value
            color: "white"
            font.pixelSize: 15
            font.family: "Monospace"
        }
    }
}

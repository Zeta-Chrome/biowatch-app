import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BWApp

Rectangle {
    id: root
    color: "black"
    Layout.fillWidth: true
    Layout.fillHeight: true

    property string pageTitle: "Device"

    readonly property int state: appManager.ble.connectionState

    readonly property color statusColor: {
        if (state === BleManager.CONNECTED) return "#3ecf6b"
        if (state === BleManager.SCANNING || state === BleManager.CONNECTING) return "#3ecf6b"
        if (state === BleManager.ERROR) return "#d64545"
        return "#555555"
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: 0.85 * parent.width
        spacing: 28

        // Status Indicator
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 120
            height: 120
            radius: 60
            color: "#0A0A0A"
            border.width: 2
            border.color: root.statusColor

            Rectangle {
                id: innerRing
                anchors.centerIn: parent
                width: 70
                height: 70
                radius: 35
                color: root.statusColor
                opacity: 1.0

                SequentialAnimation on opacity {
                    id: pulseAnim
                    running: root.state === BleManager.SCANNING || root.state === BleManager.CONNECTING
                    loops: Animation.Infinite
                    NumberAnimation {
                        from: 1.0; to: 0.2
                        duration: root.state === BleManager.CONNECTING ? 350 : 700
                    }
                    NumberAnimation {
                        from: 0.2; to: 1.0
                        duration: root.state === BleManager.CONNECTING ? 350 : 700
                    }
                    onRunningChanged: {
                        if (!running)
                            innerRing.opacity = 1.0
                    }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: appManager.ble.statusText
            font.pixelSize: 18
            font.weight: Font.DemiBold
            color: "#EEEEEE"
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: detailLayout.implicitHeight + 28
            radius: 12
            color: "#0A0A0A"
            border.color: "#1E1E1E"
            border.width: 1
            visible: root.state === BleManager.CONNECTED

            ColumnLayout {
                id: detailLayout
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Text {
                    text: "DEVICE"
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1.5
                    color: "#666666"
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Name"; font.pixelSize: 13; color: "#888888" }
                    Item { Layout.fillWidth: true }
                    Text { text: appManager.ble.deviceName; font.pixelSize: 13; color: "#EEEEEE" }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: "#141414" }
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Firmware"; font.pixelSize: 13; color: "#888888" }
                    Item { Layout.fillWidth: true }
                    Text { text: "v" + appManager.firmwareVersion; font.pixelSize: 13; color: "#EEEEEE" }
                }
            }
        }

        Button {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            text: {
                if (root.state === BleManager.ERROR) return "Open App Settings"
                if (root.state === BleManager.CONNECTED) return "Disconnect"
                if (root.state === BleManager.SCANNING || root.state === BleManager.CONNECTING) return "Cancel"
                return "Connect to BioWatch"
            }
            background: Rectangle {
                radius: 10
                color: root.state === BleManager.CONNECTED ? "#2a1414" : (root.state === BleManager.ERROR ? "#2a2214" : "#14241a")
                border.color: root.state === BleManager.CONNECTED ? "#5a2a2a" : (root.state === BleManager.ERROR ? "#5a4a2a" : "#2a5a3a")
                border.width: 1
            }
            contentItem: Text {
                text: parent.text
                color: root.state === BleManager.CONNECTED ? "#e08080" : (root.state === BleManager.ERROR ? "#e0c080" : "#7fe0a0")
                font.pixelSize: 15
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: {
                if (root.state === BleManager.CONNECTED || root.state === BleManager.SCANNING || root.state === BleManager.CONNECTING)
                    appManager.ble.disconnectDevice()
                else
                    appManager.ble.scanAndConnect()
            }
        }
    }
}

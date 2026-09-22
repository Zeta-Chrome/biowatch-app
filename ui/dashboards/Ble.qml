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

    readonly property int state_: appManager.ble.connectionState
    readonly property bool isIdle: state_ === 0        // BleManager.Idle
    readonly property bool isScanning: state_ === 1    // BleManager.Scanning
    readonly property bool isConnecting: state_ === 2  // BleManager.Connecting
    readonly property bool isConnected: state_ === 3   // BleManager.Connected
    readonly property bool isError: state_ === 4       // BleManager.Error
    readonly property bool isPermissionDenied: state_ === 5 // BleManager.PermissionDenied

    readonly property color statusColor: {
        if (isConnected) return "#3ecf6b"
        if (isScanning || isConnecting) return "#3ecf6b"
        if (isError) return "#d64545"
        if (isPermissionDenied) return "#d6a94c"
        return "#555555"
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: 0.85 * parent.width
        spacing: 28

        // Big status indicator - blinks while scanning/connecting, solid when connected.
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 120
            height: 120
            radius: 60
            color: "#0A0A0A"
            border.width: 2
            border.color: root.statusColor

            Rectangle {
                anchors.centerIn: parent
                width: 70
                height: 70
                radius: 35
                color: root.statusColor

                SequentialAnimation on opacity {
                    running: root.isScanning || root.isConnecting
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.2; duration: root.isConnecting ? 350 : 700 }
                    NumberAnimation { from: 0.2; to: 1.0; duration: root.isConnecting ? 350 : 700 }
                }
                Connections {
                    target: root
                    function onIsScanningChanged() { if (!root.isScanning && !root.isConnecting) opacity = 1.0 }
                    function onIsConnectingChanged() { if (!root.isScanning && !root.isConnecting) opacity = 1.0 }
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
            visible: root.isConnected

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
                if (root.isPermissionDenied) return "Open App Settings"
                if (root.isConnected) return "Disconnect"
                if (root.isScanning || root.isConnecting) return "Cancel"
                return "Connect to BioWatch"
            }
            background: Rectangle {
                radius: 10
                color: root.isConnected ? "#2a1414" : (root.isPermissionDenied ? "#2a2214" : "#14241a")
                border.color: root.isConnected ? "#5a2a2a" : (root.isPermissionDenied ? "#5a4a2a" : "#2a5a3a")
                border.width: 1
            }
            contentItem: Text {
                text: parent.text
                color: root.isConnected ? "#e08080" : (root.isPermissionDenied ? "#e0c080" : "#7fe0a0")
                font.pixelSize: 15
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
            }
            onClicked: {
                if (root.isPermissionDenied)
                    appManager.ble.openAppSettings()
                else if (root.isConnected || root.isScanning || root.isConnecting)
                    appManager.ble.disconnectDevice()
                else
                    appManager.ble.scanAndConnect()
            }
        }
    }
}

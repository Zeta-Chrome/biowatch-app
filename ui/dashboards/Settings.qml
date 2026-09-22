import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BWApp

Rectangle {
    id: root
    color: "#000000"

    property string pageTitle: "Settings"
    property string appName: "Biowatch"
    property string manufacturer: "ZetaChrome"
    property int heightUnitMode: 0

    readonly property int heightFeet: Math.floor(appManager.heightCm / 30.48)
    readonly property int heightInches: Math.round((appManager.heightCm / 2.54) % 12)

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: mainCol.implicitHeight + 40
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: mainCol
            width: 0.9 * parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 16
            spacing: 16

            // =================================================================
            // CARD 1: DEVICE & SYSTEM
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: infoLayout.implicitHeight + 28
                radius: 12
                color: "#0A0A0A"
                border.color: "#1E1E1E"
                border.width: 1

                ColumnLayout {
                    id: infoLayout
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Text {
                        text: "DEVICE & SYSTEM"
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.5
                        color: "#666666"
                    }

                    // App Name
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Application"; font.pixelSize: 13; color: "#888888" }
                        Item { Layout.fillWidth: true }
                        Text { text: root.appName; font.pixelSize: 13; font.weight: Font.Medium; color: "#EEEEEE" }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#141414" }

                    // Manufacturer
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Manufacturer"; font.pixelSize: 13; color: "#888888" }
                        Item { Layout.fillWidth: true }
                        Text { text: root.manufacturer; font.pixelSize: 13; font.weight: Font.Medium; color: "#EEEEEE" }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#141414" }

                    // Firmware Version (Read-only)
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Firmware Revision"; font.pixelSize: 13; color: "#888888" }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            implicitWidth: fwText.implicitWidth + 12
                            implicitHeight: 22
                            radius: 4
                            color: "#161616"
                            border.color: "#262626"
                            border.width: 1

                            Text {
                                id: fwText
                                anchors.centerIn: parent
                                text: "v" + (appManager.firmwareVersion !== "" ? appManager.firmwareVersion : "0.0.0")
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: "#AAAAAA"
                            }
                        }
                    }
                }
            }

            // =================================================================
            // CARD 2: PHYSICAL PROFILE
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: profileLayout.implicitHeight + 28
                radius: 12
                color: "#0A0A0A"
                border.color: "#1E1E1E"
                border.width: 1

                ColumnLayout {
                    id: profileLayout
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "PHYSICAL PROFILE"
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1.5
                            color: "#666666"
                        }

                        Item { Layout.fillWidth: true }

                        // Unit Selector Switch
                        Rectangle {
                            implicitWidth: 76
                            implicitHeight: 24
                            radius: 4
                            color: "#141414"
                            border.color: "#222222"
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 2

                                Rectangle {
                                    width: 35; height: 20; radius: 3
                                    color: root.heightUnitMode === 0 ? "#262626" : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "cm"
                                        font.pixelSize: 11
                                        font.weight: root.heightUnitMode === 0 ? Font.DemiBold : Font.Normal
                                        color: root.heightUnitMode === 0 ? "#FFFFFF" : "#666666"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.heightUnitMode = 0
                                    }
                                }

                                Rectangle {
                                    width: 35; height: 20; radius: 3
                                    color: root.heightUnitMode === 1 ? "#262626" : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "ft"
                                        font.pixelSize: 11
                                        font.weight: root.heightUnitMode === 1 ? Font.DemiBold : Font.Normal
                                        color: root.heightUnitMode === 1 ? "#FFFFFF" : "#666666"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.heightUnitMode = 1
                                    }
                                }
                            }
                        }
                    }

                    // --- Height Input ---
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ColumnLayout {
                            spacing: 2
                            Text { text: "Height"; font.pixelSize: 13; color: "#888888" }
                            Text {
                                text: root.heightUnitMode === 0 
                                      ? "(" + root.heightFeet + "' " + root.heightInches + "\")"
                                      : "(" + Math.round(appManager.heightCm) + " cm)"
                                font.pixelSize: 11
                                color: "#444444"
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Mode 0: CM input
                        Rectangle {
                            visible: root.heightUnitMode === 0
                            implicitWidth: 100
                            implicitHeight: 34
                            radius: 6
                            color: "#141414"
                            border.color: cmInput.activeFocus ? "#555555" : "#222222"
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 4

                                TextInput {
                                    id: cmInput
                                    Layout.fillWidth: true
                                    text: Math.round(appManager.heightCm).toString()
                                    color: "#FFFFFF"
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    horizontalAlignment: TextInput.AlignRight
                                    inputMethodHints: Qt.ImhDigitsOnly
                                    validator: IntValidator { bottom: 30; top: 250 }
                                    onEditingFinished: {
                                        let val = parseFloat(text);
                                        if (!isNaN(val)) appManager.heightCm = val;
                                    }
                                }
                                Text { text: "cm"; color: "#555555"; font.pixelSize: 11 }
                            }
                        }

                        // Mode 1: FT + IN inputs
                        RowLayout {
                            visible: root.heightUnitMode === 1
                            spacing: 6

                            Rectangle {
                                implicitWidth: 50
                                implicitHeight: 34
                                radius: 6
                                color: "#141414"
                                border.color: ftInput.activeFocus ? "#555555" : "#222222"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    TextInput {
                                        id: ftInput
                                        Layout.fillWidth: true
                                        text: root.heightFeet.toString()
                                        color: "#FFFFFF"
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        horizontalAlignment: TextInput.AlignRight
                                        inputMethodHints: Qt.ImhDigitsOnly
                                        validator: IntValidator { bottom: 1; top: 8 }
                                        onEditingFinished: {
                                            let ft = parseInt(text) || 0;
                                            let inches = parseInt(inInput.text) || 0;
                                            appManager.heightCm = Math.round(((ft * 12) + inches) * 2.54);
                                        }
                                    }
                                    Text { text: "ft"; color: "#555555"; font.pixelSize: 10 }
                                }
                            }

                            Rectangle {
                                implicitWidth: 50
                                implicitHeight: 34
                                radius: 6
                                color: "#141414"
                                border.color: inInput.activeFocus ? "#555555" : "#222222"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    TextInput {
                                        id: inInput
                                        Layout.fillWidth: true
                                        text: root.heightInches.toString()
                                        color: "#FFFFFF"
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        horizontalAlignment: TextInput.AlignRight
                                        inputMethodHints: Qt.ImhDigitsOnly
                                        validator: IntValidator { bottom: 0; top: 11 }
                                        onEditingFinished: {
                                            let ft = parseInt(ftInput.text) || 0;
                                            let inches = parseInt(text) || 0;
                                            appManager.heightCm = Math.round(((ft * 12) + inches) * 2.54);
                                        }
                                    }
                                    Text { text: "in"; color: "#555555"; font.pixelSize: 10 }
                                }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#141414" }

                    // --- Weight Input ---
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ColumnLayout {
                            spacing: 2
                            Text { text: "Weight"; font.pixelSize: 13; color: "#888888" }
                            Text {
                                text: "(" + (appManager.weightKg * 2.20462).toFixed(1) + " lbs)"
                                font.pixelSize: 11
                                color: "#444444"
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            implicitWidth: 100
                            implicitHeight: 34
                            radius: 6
                            color: "#141414"
                            border.color: kgInput.activeFocus ? "#555555" : "#222222"
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 4

                                TextInput {
                                    id: kgInput
                                    Layout.fillWidth: true
                                    text: appManager.weightKg.toFixed(1)
                                    color: "#FFFFFF"
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    horizontalAlignment: TextInput.AlignRight
                                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                                    validator: DoubleValidator { bottom: 20.0; top: 300.0; decimals: 1 }
                                    onEditingFinished: {
                                        let val = parseFloat(text);
                                        if (!isNaN(val)) appManager.weightKg = val;
                                    }
                                }
                                Text { text: "kg"; color: "#555555"; font.pixelSize: 11 }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: storageLayout.implicitHeight + 28
                radius: 12
                color: "#0A0A0A"
                border.color: "#1E1E1E"
                border.width: 1

                ColumnLayout {
                    id: storageLayout
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    Text {
                        text: "STORAGE & MAINTENANCE"
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.5
                        color: "#666666"
                    }

                    Text {
                        text: "Clear all local health, environment, and activity records stored in the database."
                        font.pixelSize: 12
                        color: "#888888"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    // Clear All Data Action Button
                    Rectangle {
                        id: wipeBtn
                        Layout.fillWidth: true
                        implicitHeight: 44
                        radius: 8
                        color: btnMouse.pressed ? "#220D0D" : (btnMouse.containsMouse ? "#1C0A0A" : "#140707")
                        border.color: btnMouse.pressed ? "#A82B2B" : (btnMouse.containsMouse ? "#732424" : "#421818")
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: "Delete All Data"
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: "#FF5252"
                            }
                        }

                        MouseArea {
                            id: btnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: confirmDialog.open()
                        }
                    }

                }
            }
        }
    }

    Dialog {
        id: confirmDialog
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.85, 340)
        modal: true
        dim: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#121212"
            radius: 14
            border.color: "#282828"
            border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 16

            Text {
                text: "Erase All Records?"
                color: "#EEEEEE"
                font.pixelSize: 16
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "This action will permanently delete all stored activity, vitals, and environment logs from SQLite. This cannot be undone."
                color: "#999999"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Cancel Button
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: 8
                    color: cancelMouse.pressed ? "#222222" : "#181818"
                    border.color: "#303030"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: "#DDDDDD"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: confirmDialog.close()
                    }
                }

                // Confirm Wipe Button
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: 8
                    color: confirmMouse.pressed ? "#992222" : "#D32F2F"

                    Text {
                        anchors.centerIn: parent
                        text: "Yes, Delete"
                        color: "#FFFFFF"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: confirmMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            confirmDialog.close()
                            appManager.repository && appManager.repository.clearAllData()
                        }
                    }
                }
            }
        }
    }
}

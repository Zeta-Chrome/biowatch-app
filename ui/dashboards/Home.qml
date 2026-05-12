import QtQuick
import QtQuick.Layouts
import BWApp

Rectangle {
    id: root
    color: "black"
    Layout.fillWidth: true
    Layout.fillHeight: true

    property string dashboard: "Home"
    property string pageTitle: "Today's Stats"

    signal navigateRequested(string pageName)

    Rectangle {
        id: growCircle
        width: 10
        height: 10
        radius: 5
        opacity: 0
        visible: false
        z: 999
        property string targetPage: ""

        ParallelAnimation {
            id: growAnim
            NumberAnimation {
                target: growCircle
                property: "scale"
                from: 1
                to: 150
                duration: 750
                easing.type: Easing.InQuart
            }
            NumberAnimation {
                target: growCircle
                property: "opacity"
                from: 0.5
                to: 1.0
                duration: 250
            }
            onFinished: {
                root.navigateRequested(growCircle.targetPage);  // ← CHANGED
                growCircle.visible = false;
                growCircle.scale = 1;
            }
        }
    }

    function onClickAnimate(targetItem) {
        var globalPos = targetItem.mapToItem(root, targetItem.width / 2, targetItem.height / 2);
        growCircle.x = globalPos.x - growCircle.width / 2;
        growCircle.y = globalPos.y - growCircle.height / 2;
        growCircle.color = targetItem.iconColor;
        growCircle.targetPage = targetItem.dashboard;
        growCircle.visible = true;
        growAnim.restart();
    }

    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            id: infoBar
            Layout.fillWidth: true
            Layout.preferredHeight: parent.height * 0.2
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            spacing: 15

            StatItem {
                label: "STEPS"
                value: "4,281"
                unit: "st"
                Layout.fillWidth: true
            }
            StatItem {
                label: "CALORIES"
                value: "248"
                unit: "kcal"
                Layout.fillWidth: true
            }
            StatItem {
                label: "HEART"
                value: "72"
                unit: "bpm"
                Layout.fillWidth: true
            }
        }

        GridLayout {
            id: iconGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            Layout.margins: 25
            columnSpacing: 20
            rowSpacing: 20

            IconButton {
                id: calorie
                iconSource: "qrc:/qt/qml/BWApp/assets/images/calories.svg"
                buttonRadius: 0.2
                iconColor: "#b48c64"
                dashboard: "Calories.qml"
                Layout.fillWidth: true
                Layout.fillHeight: true
                onClicked: root.onClickAnimate(calorie)
            }

            IconButton {
                id: steps
                iconSource: "qrc:/qt/qml/BWApp/assets/images/steps.svg"
                buttonRadius: 0.2
                iconColor: "#323264"
                dashboard: "Steps.qml"
                Layout.fillWidth: true
                Layout.fillHeight: true
                onClicked: root.onClickAnimate(steps)
            }

            IconButton {
                id: heartRate
                iconSource: "qrc:/qt/qml/BWApp/assets/images/heart_rate.svg"
                buttonRadius: 0.2
                iconColor: "#b46464"
                dashboard: "HeartRate.qml"
                Layout.fillWidth: true
                Layout.fillHeight: true
                onClicked: root.onClickAnimate(heartRate)
            }

            IconButton {
                id: bloodO2
                iconSource: "qrc:/qt/qml/BWApp/assets/images/blood_O2.svg"
                buttonRadius: 0.2
                iconColor: "#643232"
                dashboard: "BloodO2.qml"
                Layout.fillWidth: true
                Layout.fillHeight: true
                onClicked: root.onClickAnimate(bloodO2)
            }

            IconButton {
                id: weather
                iconSource: "qrc:/qt/qml/BWApp/assets/images/weather.svg"
                buttonRadius: 0.2
                iconColor: "#787878"
                dashboard: "Weather.qml"
                Layout.fillWidth: true
                Layout.fillHeight: true
                onClicked: root.onClickAnimate(weather)
            }

            IconButton {
                id: batteryLevel
                iconSource: "qrc:/qt/qml/BWApp/assets/images/battery_level.svg"
                buttonRadius: 0.2
                iconColor: "#64b464"
                dashboard: "BatteryLevel.qml"
                Layout.fillWidth: true
                Layout.fillHeight: true
                onClicked: root.onClickAnimate(batteryLevel)
            }
        }
    }
}

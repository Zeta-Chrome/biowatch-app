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

    property int steps: 0
    property real calories: 0
    property real heartRate: 0

    signal navigateRequested(string pageName)

    function refresh() {
        var act = appManager.repository.getLatestActivity()
        steps = act.steps !== undefined ? act.steps : 0
        calories = act.calories_kcal !== undefined ? act.calories_kcal : 0

        var hr = appManager.repository.getLatestVital(0) // VITALS_HR
        root.heartRate = hr.value !== undefined ? hr.value : 0
    }

    Component.onCompleted: refresh()

    Connections {
        target: appManager.ble
        function onActivityUpdated() {
            var latest = appManager.repository.getLatestActivity()
            root.steps = latest.steps
            root.calories = latest.calories_kcal
        }
        function onVitalsUpdated(type) {
            var latest = appManager.repository.getLatestVital(root.vitalsType)
            if (type === 0)
                root.heartRate = latest.value || 0
        }
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
                value: Math.round(root.steps).toString()
                unit: "st"
                Layout.fillWidth: true
            }
            StatItem {
                label: "CALORIES"
                value: Math.round(root.calories).toString()
                unit: "kcal"
                Layout.fillWidth: true
            }
            StatItem {
                label: "HEART"
                value: Math.round(root.heartRate).toString()
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
                id: activity
                iconSource: "qrc:/qt/qml/BWApp/assets/images/steps.svg"
                buttonRadius: 0.2
                iconColor: "#323264"
                dashboard: "Activity.qml"
                Layout.fillWidth: true
                Layout.fillHeight: true
                onClicked: root.navigateRequested(dashboard)
            }

            IconButton {
                id: calorie
                iconSource: "qrc:/qt/qml/BWApp/assets/images/calories.svg"
                buttonRadius: 0.2
                iconColor: "#b48c64"
                dashboard: "Calories.qml"
                Layout.fillWidth: true
                Layout.fillHeight: true
                onClicked: root.navigateRequested(dashboard)
            }

            IconButton {
                id: heartRate
                iconSource: "qrc:/qt/qml/BWApp/assets/images/heart_rate.svg"
                buttonRadius: 0.2
                iconColor: "#b46464"
                dashboard: "HeartRate.qml"
                Layout.fillWidth: true
                Layout.fillHeight: true
                onClicked: root.navigateRequested(dashboard)
            }

            IconButton {
                id: bloodO2
                iconSource: "qrc:/qt/qml/BWApp/assets/images/blood_O2.svg"
                buttonRadius: 0.2
                iconColor: "#643232"
                dashboard: "BloodO2.qml"
                Layout.fillWidth: true
                Layout.fillHeight: true
                onClicked: root.navigateRequested(dashboard)
            }

            IconButton {
                id: environment
                iconSource: "qrc:/qt/qml/BWApp/assets/images/weather.svg"
                buttonRadius: 0.2
                iconColor: "#787878"
                dashboard: "Environment.qml"
                Layout.fillWidth: true
                Layout.fillHeight: true
                onClicked: root.navigateRequested(dashboard)
            }

            IconButton {
                id: battery
                iconSource: "qrc:/qt/qml/BWApp/assets/images/battery_health.svg"
                buttonRadius: 0.2
                iconColor: "#3e6b32"
                dashboard: "Battery.qml"
                Layout.fillWidth: true
                Layout.fillHeight: true
                onClicked: root.navigateRequested(dashboard)
            }

        }
    }
}

import QtQuick
import QtQuick.Layouts
import BWApp
import "../components"

Rectangle {
    id: root
    color: "black"
    Layout.fillWidth: true
    Layout.fillHeight: true

    property string pageTitle: "Environment"
    property string frame: "day"
    property var refDate: new Date()

    property real temp: 0
    property real humidity: 0
    property real lux: 0

    property var tempRows: []
    property var humidityRows: []
    property var luxRows: []
    property int rowsVersion: 0

    readonly property var metricDefs: [
        { key: "temperature", label: "Temp",     unit: "°C",  color: "#d68a4c" },
        { key: "humidity",    label: "Humidity", unit: "%",   color: "#4c9dd6" },
        { key: "lux",         label: "Light",    unit: "lux", color: "#d6c94c" }
    ]
    property int selectedMetric: 0
    readonly property var currentMetric: metricDefs[selectedMetric]

    readonly property var currentRows: {
        // Reference rowsVersion to force re-evaluation on reload()
        let _v = root.rowsVersion
        if (currentMetric.key === "temperature") return tempRows
        if (currentMetric.key === "humidity")    return humidityRows
        return luxRows
    }

    function reload() {
        var qDate = Qt.formatDate(root.refDate, "yyyy-MM-dd")
        var tf = chart.timeFrames[frame]

        root.tempRows = appManager.repository.getEnvironmentMetric("temperature", tf, qDate)
        root.humidityRows = appManager.repository.getEnvironmentMetric("humidity", tf, qDate)
        root.luxRows = appManager.repository.getEnvironmentMetric("lux", tf, qDate)
        root.rowsVersion++

        var latest = appManager.repository.getLatestEnvironment()
        root.temp = latest.temperature || 0
        root.humidity = latest.humidity || 0
        root.lux = latest.lux || 0
    }

    Component.onCompleted: reload()

    Connections {
        target: appManager.ble
        function onEnvironmentUpdated() {
            root.reload()
        }
    }

    function setFrame(f) { root.frame = f; root.reload() }
    function navigate(dir) {
        root.refDate = chart.shiftDate(root.refDate, root.frame, dir)
        root.reload()
    }

    Flickable {
        id: scroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight + 32
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: col
            width: 0.92 * parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 50
            spacing: 50

            // Stats Triple Card
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                StatItem { label: "TEMP"; value: root.temp.toFixed(1); unit: "°C"; Layout.fillWidth: true }
                StatItem { label: "HUMIDITY"; value: root.humidity.toFixed(0); unit: "%"; Layout.fillWidth: true }
                StatItem { label: "LIGHT"; value: root.lux.toFixed(0); unit: "lux"; Layout.fillWidth: true }
            }

            // Single Consolidated Unit: Tabs + Chart
            ColumnLayout {
                id: chartSection
                Layout.fillWidth: true
                spacing: 10

                // 1. Metric Tabs
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    Repeater {
                        model: root.metricDefs
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: 84
                            height: 30
                            radius: 8
                            color: root.selectedMetric === index ? modelData.color : "#141414"
                            border.color: "#222222"
                            border.width: root.selectedMetric === index ? 0 : 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                font.pixelSize: 11
                                font.weight: root.selectedMetric === index ? Font.DemiBold : Font.Normal
                                color: root.selectedMetric === index ? "#000000" : "#888888"
                            }
                            MouseArea { anchors.fill: parent; onClicked: root.selectedMetric = index }
                        }
                    }
                }

                // 2. Chart Card
                Rectangle {
                    id: chartCard
                    Layout.fillWidth: true
                    Layout.preferredHeight: width * 0.75
                    radius: 12
                    color: "#0A0A0A"
                    border.color: "#1E1E1E"
                    border.width: 1

                    LineChart {
                        id: chart
                        anchors.fill: parent
                        anchors.margins: 12
                        accentColor: root.currentMetric.color
                        unit: root.currentMetric.unit
                        availableFrames: ["day", "week", "month", "year"]
                        frame: root.frame
                        points: chart.toPoints(root.currentRows, "value")
                        xLabels: chart.xLabelsFor(root.frame, root.currentRows)
                        periodLabel: chart.formatPeriodLabel(root.frame, root.refDate)

                        onFrameRequested: (f) => root.setFrame(f)
                        onNavigateRequested: (dir) => root.navigate(dir)
                    }
                }
            }
        }
    }
}

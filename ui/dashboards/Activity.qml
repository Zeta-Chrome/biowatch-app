import QtQuick
import QtQuick.Layouts
import BWApp
import "../components"

Rectangle {
    id: root
    color: "black"
    Layout.fillWidth: true
    Layout.fillHeight: true

    property string pageTitle: "Activity"
    property string frame: "week"
    property var refDate: new Date()
    property var rows: []
    property int rowsVersion: 0

    property int totalSteps: 0
    property real totalDistanceM: 0
    property real avgSpeedKmh: 0
    property real totalDurationMin: 0

    function reload() {
        var qDate = Qt.formatDate(root.refDate, "yyyy-MM-dd")
        var tf = chart.timeFrames[frame]
        root.rows = appManager.repository.getActivity(tf, qDate)
        root.rowsVersion++

        var latest = appManager.repository.getLatestActivity()
        root.totalSteps = latest.steps || 0
        root.totalDistanceM = latest.distance_m || 0
        root.avgSpeedKmh = latest.speed_kmh || 0
        root.totalDurationMin = (latest.duration_ms || 0) / 60000
    }

    readonly property var metricDefs: [
        { key: "steps",       label: "Steps",    unit: "st",   color: "#5c5cd6", scale: 1 },
        { key: "distance_m",  label: "Distance", unit: "km",   color: "#4c9dd6", scale: 1 / 1000 },
        { key: "duration_ms", label: "Duration", unit: "min",  color: "#4cd69d", scale: 1 / 60000 },
        { key: "speed_kmh",   label: "Speed",    unit: "km/h", color: "#d68a4c", scale: 1 }
    ]
    property int selectedMetric: 0
    readonly property var currentMetric: metricDefs[selectedMetric]

    function scaledPoints(records, def) {
        let _v = root.rowsVersion
        var pts = []
        for (var i = 0; i < records.length; i++) {
            var raw = (records[i] && records[i][def.key] !== undefined) ? records[i][def.key] : 0
            pts.push({ x: i, y: (raw || 0) * def.scale })
        }
        return pts
    }

    Component.onCompleted: reload()

    Connections {
        target: appManager.ble
        function onActivityUpdated() {
            root.reload()
        }
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
            spacing: 30

            // 2x2 Stats Summary Grid
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                StatItem {
                    label: "STEPS"
                    value: Math.round(root.totalSteps).toString()
                    unit: "st"
                    Layout.fillWidth: true
                }
                StatItem {
                    label: "DISTANCE"
                    value: (root.totalDistanceM / 1000).toFixed(2)
                    unit: "km"
                    Layout.fillWidth: true
                }
                StatItem {
                    label: "DURATION"
                    value: Math.round(root.totalDurationMin).toString()
                    unit: "min"
                    Layout.fillWidth: true
                }
                StatItem {
                    label: "AVG SPEED"
                    value: root.avgSpeedKmh.toFixed(1)
                    unit: "km/h"
                    Layout.fillWidth: true
                }
            }

            // Metric Selectors + Chart Container
            ColumnLayout {
                id: chartSection
                Layout.fillWidth: true
                spacing: 10

                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    Repeater {
                        model: root.metricDefs
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: 78
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
                                color: root.selectedMetric === index ? "#FFFFFF" : "#888888"
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.selectedMetric = index
                            }
                        }
                    }
                }

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
                        availableFrames: ["week", "month", "year"]
                        frame: root.frame
                        points: root.scaledPoints(root.rows, root.currentMetric)
                        xLabels: chart.xLabelsFor(root.frame, root.rows)
                        periodLabel: chart.formatPeriodLabel(root.frame, root.refDate)

                        onFrameRequested: (f) => {
                            root.frame = f
                            root.reload()
                        }
                        onNavigateRequested: (dir) => {
                            root.refDate = chart.shiftDate(root.refDate, root.frame, dir)
                            root.reload()
                        }
                    }
                }
            }
        }
    }
}

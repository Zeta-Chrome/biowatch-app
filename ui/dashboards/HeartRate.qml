import QtQuick
import QtQuick.Layouts
import BWApp
import "../components"

Rectangle {
    id: root
    color: "black"
    Layout.fillWidth: true
    Layout.fillHeight: true

    property string pageTitle: "Heart Rate"
    readonly property int vitalsType: 0 // VITALS_HR

    property string frame: "day"
    property var refDate: new Date()
    property var rows: []
    property real latestBpm: 0

    function reload() {
        var qDate = Qt.formatDate(root.refDate, "yyyy-MM-dd")
        root.rows = appManager.repository.getVitals(root.vitalsType, chart.timeFrames[frame], qDate)
        var latest = appManager.repository.getLatestVital(root.vitalsType)
        root.latestBpm = latest.value || 0
    }

    Component.onCompleted: reload()

    Connections {
        target: appManager.ble
        function onVitalsUpdated(type) {
            if (type === root.vitalsType)
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
            spacing: 50

            StatItem {
                Layout.alignment: Qt.AlignHCenter
                label: "LATEST READING"
                value: Math.round(root.latestBpm).toString()
                unit: "bpm"
            }

            // Chart Card (height follows width, so it keeps a sane aspect ratio on any screen)
            Rectangle {
                id: chartCard
                Layout.fillWidth: true
                Layout.preferredHeight: chartCard.width * 0.75
                radius: 12
                color: "#0A0A0A"
                border.color: "#1E1E1E"
                border.width: 1

                LineChart {
                    id: chart
                    anchors.fill: parent
                    anchors.margins: 12
                    accentColor: "#b46464"
                    unit: "bpm"
                    availableFrames: ["day", "week", "month", "year"]
                    frame: root.frame
                    points: chart.toPoints(root.rows, "value")
                    xLabels: chart.xLabelsFor(root.frame, root.rows)
                    periodLabel: chart.formatPeriodLabel(root.frame, root.refDate)

                    onFrameRequested: (f) => { root.frame = f; root.reload() }
                    onNavigateRequested: (dir) => {
                        root.refDate = chart.shiftDate(root.refDate, root.frame, dir)
                        root.reload()
                    }
                }
            }
        }
    }
}

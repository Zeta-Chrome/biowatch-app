import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property color accentColor: "#5aa9e6"
    property string unit: ""
    property var points: []          // [{x: number, y: number}]
    property var xLabels: []         // display labels, same length as points (or thinned)
    property string frame: "week"    // "day" | "week" | "month" | "year"
    property var availableFrames: ["week", "month", "year"]
    property string periodLabel: ""  // e.g. "Sep 15 - Sep 21"
    property bool loading: false

    signal frameRequested(string frame)
    signal navigateRequested(int direction) // -1 = older, +1 = newer

    implicitHeight: 260

    readonly property real maxY: {
        if (points.length === 0) return 1
        let m = -Infinity
        for (let p of points) if (p.y > m) m = p.y
        return m <= 0 ? 1 : m
    }
    readonly property real minY: {
        if (points.length === 0) return 0
        let m = Infinity
        for (let p of points) if (p.y < m) m = p.y
        return m === Infinity ? 0 : Math.min(m, 0)
    }

    // -------------------------------------------------------------------------
    // Inline Helper Methods (Merged from .pragma library JS)
    // -------------------------------------------------------------------------
    readonly property var timeFrames: ({ day: 0, week: 1, month: 2, year: 3 })

    function shiftDate(jsDate, frameType, direction) {
        var d = new Date(jsDate.getTime())
        if (frameType === "day") d.setDate(d.getDate() + direction)
        else if (frameType === "week") d.setDate(d.getDate() + direction * 7)
        else if (frameType === "month") d.setMonth(d.getMonth() + direction)
        else if (frameType === "year") d.setFullYear(d.getFullYear() + direction)
        return d
    }

    function formatPeriodLabel(frameType, jsDate) {
        if (frameType === "day") {
            return jsDate.toLocaleDateString(Qt.locale(), "ddd, MMM d")
        } else if (frameType === "week") {
            var dow = jsDate.getDay() === 0 ? 7 : jsDate.getDay()
            var start = new Date(jsDate.getTime())
            start.setDate(start.getDate() - (dow - 1))
            var end = new Date(start.getTime())
            end.setDate(end.getDate() + 6)
            return start.toLocaleDateString(Qt.locale(), "MMM d") + " – " +
                   end.toLocaleDateString(Qt.locale(), "MMM d")
        } else if (frameType === "month") {
            return jsDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
        } else if (frameType === "year") {
            return jsDate.getFullYear().toString()
        }
        return ""
    }

    function toPoints(rows, valueKey) {
        var pts = []
        for (var i = 0; i < rows.length; i++) {
            pts.push({ x: i, y: rows[i][valueKey] !== undefined ? rows[i][valueKey] : 0 })
        }
        return pts
    }

    // Read directly as UTC to preserve raw local time sent by the hardware
    function xLabelsFor(frameType, rows) {
        var labels = []
        var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

        for (var i = 0; i < rows.length; i++) {
            var d = new Date(rows[i].timestamp * 1000)
            if (frameType === "day") {
                var hh = String(d.getUTCHours()).padStart(2, '0')
                var mm = String(d.getUTCMinutes()).padStart(2, '0')
                labels.push(hh + ":" + mm)
            } else if (frameType === "week") {
                labels.push(days[d.getUTCDay()])
            } else if (frameType === "month") {
                labels.push(d.getUTCDate().toString())
            } else if (frameType === "year") {
                labels.push(months[d.getUTCMonth()])
            }
        }
        return labels
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // --- Segmented frame selector ---
        Rectangle {
            visible: root.availableFrames.length > 1
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: segRow.implicitWidth + 8
            implicitHeight: 30
            radius: 8
            color: "#141414"
            border.color: "#222222"
            border.width: 1

            Row {
                id: segRow
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                    model: root.availableFrames
                    delegate: Rectangle {
                        required property string modelData
                        width: 60
                        height: 24
                        radius: 6
                        color: root.frame === modelData ? root.accentColor : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                            font.pixelSize: 11
                            font.weight: root.frame === modelData ? Font.DemiBold : Font.Normal
                            color: root.frame === modelData ? "#000000" : "#888888"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.frameRequested(modelData)
                        }
                    }
                }
            }
        }

        // --- Period navigation row ---
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "‹"
                font.pixelSize: 20
                color: "#666666"
                Layout.preferredWidth: 30
                horizontalAlignment: Text.AlignHCenter
                MouseArea { anchors.fill: parent; onClicked: root.navigateRequested(-1) }
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.periodLabel
                font.pixelSize: 12
                color: "#888888"
            }
            Text {
                text: "›"
                font.pixelSize: 20
                color: "#666666"
                Layout.preferredWidth: 30
                horizontalAlignment: Text.AlignHCenter
                MouseArea { anchors.fill: parent; onClicked: root.navigateRequested(1) }
            }
        }

        // --- Chart surface ---
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            MouseArea {
                id: swipeArea
                anchors.fill: parent
                property real startX: 0
                onPressed: (mouse) => startX = mouse.x
                onReleased: (mouse) => {
                    let dx = mouse.x - startX
                    if (dx > 40) root.navigateRequested(-1)
                    else if (dx < -40) root.navigateRequested(1)
                }
            }

            Canvas {
                id: canvas
                anchors.fill: parent
                antialiasing: true

                Connections {
                    target: root
                    function onPointsChanged() { canvas.requestPaint() }
                    function onXLabelsChanged() { canvas.requestPaint() }
                }

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    var w = width, h = height
                    var padL = 34, padR = 10, padT = 10, padB = 20
                    var plotW = w - padL - padR
                    var plotH = h - padT - padB

                    // gridlines
                    ctx.strokeStyle = "#1c1c1c"
                    ctx.lineWidth = 1
                    for (var g = 0; g <= 3; g++) {
                        var gy = padT + (plotH / 3) * g
                        ctx.beginPath()
                        ctx.moveTo(padL, gy)
                        ctx.lineTo(w - padR, gy)
                        ctx.stroke()
                    }

                    var range = root.maxY - root.minY
                    if (range <= 0) range = 1

                    function yFor(v) { return padT + plotH - ((v - root.minY) / range) * plotH }
                    function xFor(i) {
                        if (root.points.length <= 1) return padL + plotW / 2
                        return padL + (i / (root.points.length - 1)) * plotW
                    }

                    // y-axis labels (max / min)
                    ctx.fillStyle = "#555555"
                    ctx.font = "10px sans-serif"
                    ctx.textAlign = "right"
                    ctx.fillText(root.maxY.toFixed(0), padL - 6, padT + 4)
                    ctx.fillText(root.minY.toFixed(0), padL - 6, padT + plotH)

                    if (root.points.length === 0) {
                        ctx.fillStyle = "#444444"
                        ctx.textAlign = "center"
                        ctx.fillText("No data yet", w / 2, h / 2)
                        return
                    }

                    // filled area under the line
                    ctx.beginPath()
                    ctx.moveTo(xFor(0), yFor(root.points[0].y))
                    for (var i = 1; i < root.points.length; i++)
                        ctx.lineTo(xFor(i), yFor(root.points[i].y))
                    ctx.lineTo(xFor(root.points.length - 1), padT + plotH)
                    ctx.lineTo(xFor(0), padT + plotH)
                    ctx.closePath()
                    var grad = ctx.createLinearGradient(0, padT, 0, padT + plotH)
                    grad.addColorStop(0, Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.35))
                    grad.addColorStop(1, Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.02))
                    ctx.fillStyle = grad
                    ctx.fill()

                    // line
                    ctx.beginPath()
                    ctx.moveTo(xFor(0), yFor(root.points[0].y))
                    for (var j = 1; j < root.points.length; j++)
                        ctx.lineTo(xFor(j), yFor(root.points[j].y))
                    ctx.strokeStyle = root.accentColor
                    ctx.lineWidth = 2.5
                    ctx.lineJoin = "round"
                    ctx.stroke()

                    // points (only if few enough to not clutter)
                    if (root.points.length <= 40) {
                        ctx.fillStyle = root.accentColor
                        for (var k = 0; k < root.points.length; k++) {
                            ctx.beginPath()
                            ctx.arc(xFor(k), yFor(root.points[k].y), 2.5, 0, 2 * Math.PI)
                            ctx.fill()
                        }
                    }

                    // x-axis labels, thinned to avoid overlap
                    if (root.xLabels.length > 0) {
                        ctx.fillStyle = "#555555"
                        ctx.textAlign = "center"
                        var maxLabels = Math.max(2, Math.floor(plotW / 45))
                        var step = Math.max(1, Math.ceil(root.xLabels.length / maxLabels))
                        for (var m = 0; m < root.xLabels.length; m += step)
                            ctx.fillText(root.xLabels[m], xFor(m), h - 4)
                    }
                }
            }
        }
    }
}

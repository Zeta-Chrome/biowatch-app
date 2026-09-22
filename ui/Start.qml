import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BWApp

Rectangle {
    id: shellRoot
    anchors.fill: parent
    color: Theme.bg 

    function navigateTo(pageName) {
        var current = stackView.currentItem;
        if (current && current.dashboard) {
            var currentName = current.dashboard.replace("dashboards/", "");
            if (pageName === currentName || pageName === "dashboards/" + currentName)
                return;
        }
        var path = pageName.includes("/") ? pageName : "dashboards/" + pageName;
        stackView.push(path);
    }

    RowLayout {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 10
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        height: 50

        IconButton {
            id: navButton
            iconSource: {
                var item = stackView.currentItem;
                var isHome = item && item.dashboard && item.dashboard.includes("Home");
                return isHome ? "qrc:/qt/qml/BWApp/assets/images/settings.svg" :
                    "qrc:/qt/qml/BWApp/assets/images/home.svg";
            }
            buttonRadius: 0.2
            iconColor: "#666666"
            Layout.preferredWidth: 50
            Layout.preferredHeight: 50
            onClicked: {
                var item = stackView.currentItem;
                var isHome = item && item.dashboard && item.dashboard.includes("Home");
                if (isHome) {
                    shellRoot.navigateTo("Settings.qml");
                } else {
                    shellRoot.navigateTo("Home.qml");
                }
            }
        }

        Text {
            id: titleText
            text: (stackView.currentItem && stackView.currentItem.pageTitle) ? stackView.currentItem.pageTitle : "BioWatch"
            font.pixelSize: 24
            font.bold: true
            color: "#c0c0c0"
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        IconButton {
            id: bleButton
            iconSource: "qrc:/qt/qml/BWApp/assets/images/ble.svg"
            buttonRadius: 0.2
            // Idle=0 gray, Scanning=1/Connecting=2 green+blink, Connected=3 solid green,
            // Error=4 red, PermissionDenied=5 amber
            iconColor: {
                switch (appManager.ble.connectionState) {
                    case 3: return "#3ecf6b"  // Connected
                    case 1:
                    case 2: return "#3ecf6b"  // Scanning / Connecting (blinking)
                    case 4: return "#d64545"  // Error
                    case 5: return "#d6a94c"  // PermissionDenied
                    default: return "#666666" // Idle
                }
            }
            blinking: appManager.ble.connectionState === 1 || appManager.ble.connectionState === 2
            blinkDurationMs: appManager.ble.connectionState === 2 ? 350 : 700
            Layout.preferredWidth: 50
            Layout.preferredHeight: 50
            onClicked: shellRoot.navigateTo("Ble.qml")
        }
    }

    StackView {
        id: stackView
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 5
        initialItem: "dashboards/Home.qml"

        onCurrentItemChanged: {
            if (currentItem && currentItem.navigateRequested) {
                currentItem.navigateRequested.connect(shellRoot.navigateTo);
            }
        }

        pushEnter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 300
            }
        }
        pushExit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 300
            }
        }
        popEnter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 300
            }
        }
        popExit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 300
            }
        }
    }
}

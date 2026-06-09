/* ============================================================
 * SerikaOS — Premium SDDM Login Theme (Astronaut Mod)
 * Left-aligned frosted glass sidebar with modern typography
 * ============================================================ */
import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: "#0a0b16"
    property string selectedUser: "liveuser"
    property string batteryStatus: "..."
    property string networkStatus: "..."
    property string hostnameText: "serikaos"
    property string currentLayout: "US"

    function updateBattery() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "file:///sys/class/power_supply/BAT0/capacity", true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    var cap = xhr.responseText.trim();
                    var xhrState = new XMLHttpRequest();
                    xhrState.open("GET", "file:///sys/class/power_supply/BAT0/status", true);
                    xhrState.onreadystatechange = function() {
                        if (xhrState.readyState === XMLHttpRequest.DONE) {
                            var status = (xhrState.status === 200 || xhrState.status === 0) ? xhrState.responseText.trim() : "Unknown";
                            var isCharging = (status === "Charging");
                            root.batteryStatus = cap + "%" + (isCharging ? " ⚡" : "");
                        }
                    }
                    xhrState.send();
                } else {
                    root.batteryStatus = "100%";
                }
            }
        }
        xhr.send();
    }

    function updateNetwork() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "file:///proc/net/route", true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    var lines = xhr.responseText.split('\n');
                    var connected = false;
                    for (var i = 1; i < lines.length; i++) {
                        var fields = lines[i].split('\t');
                        if (fields.length > 1 && fields[1] !== "00000000") {
                            root.networkStatus = fields[0];
                            connected = true;
                            break;
                        }
                    }
                    if (!connected) root.networkStatus = "Offline";
                } else {
                    root.networkStatus = "Offline";
                }
            }
        }
        xhr.send();
    }

    function updateHostname() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "file:///etc/hostname", true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    root.hostnameText = xhr.responseText.trim();
                }
            }
        }
        xhr.send();
    }

    function cycleLayout() {
        if (typeof keyboard === "undefined" || keyboard.layouts.length === 0) return;
        var nextIndex = (keyboard.currentLayout + 1) % keyboard.layouts.length;
        keyboard.currentLayout = nextIndex;
        root.currentLayout = keyboard.layouts[nextIndex].shortName;
    }

    function isHumanUser(name) {
        var systemUsers = ["sddm", "nobody", "daemon", "bin", "sys", "mail", "ftp", "http", "dbus", "polkitd", "avahi", "colord", "git", "rtkit", "uuidd", "ntp"];
        return name && systemUsers.indexOf(name) === -1;
    }

    function pickInitialUser() {
        if (typeof userModel === "undefined" || userModel.count === 0) {
            return "liveuser";
        }
        for (var i = 0; i < userModel.count; i++) {
            var candidate = userModel.data(userModel.index(i, 0), Qt.UserRole + 1);
            if (isHumanUser(candidate)) {
                return candidate;
            }
        }
        return "liveuser";
    }

    /* ── Background Logic ── */
    Image {
        id: backgroundImage
        anchors.fill: parent
        source: "Background.jpg"
        fillMode: Image.PreserveAspectCrop
        smooth: true
    }

    /* ── Sidebar Layout ── */
    Rectangle {
        id: sidebar
        anchors.left: parent.left
        width: Math.max(400, parent.width * 0.28)
        height: parent.height
        
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#f00a0b16" }
            GradientStop { position: 1.0; color: "#e01a1b2e" }
        }

        /* ── Sidebar Border ── */
        Rectangle {
            anchors.right: parent.right
            width: 1
            height: parent.height
            color: "#405cc6d0"
        }
    }

    /* ── Content Container (Over Sidebar) ── */
    ColumnLayout {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: sidebar.width
        anchors.leftMargin: 40
        anchors.rightMargin: 40
        anchors.topMargin: 100
        anchors.bottomMargin: 60
        spacing: 32

        /* ── Header / Branding ── */
        Column {
            Layout.fillWidth: true
            spacing: 16
            
            Image {
                id: logoImage
                source: "Logo.png"
                width: parent.width * 0.85
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
            
            Text {
                text: "Rolling • High Performance"
                font.pixelSize: 12
                font.letterSpacing: 1.5
                color: "#5cc6d0" // Serika Teal
                opacity: 0.8
            }
        }

        /* ── Clock Section (Big & Bold) ── */
        Column {
            Layout.fillWidth: true
            spacing: 4
            
            Text {
                id: timeLabel
                font.pixelSize: 84
                font.weight: Font.ExtraLight
                color: "#ffffff"
                opacity: 0.95
                function updateTime() {
                    text = Qt.formatTime(new Date(), "HH:mm")
                }
            }
            
            Text {
                id: dateLabel
                font.pixelSize: 18
                font.letterSpacing: 1
                color: "#6a6a8a"
                function updateDate() {
                    text = Qt.formatDate(new Date(), "dddd, MMMM d")
                }
            }
        }

        Item { Layout.fillHeight: true }

        /* ── Login Input Area ── */
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 16

            /* ── Username Field with Live Search ── */
            QQC2.TextField {
                id: usernameField
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                placeholderText: "Username"
                placeholderTextColor: "#4a4b5e"
                font.pixelSize: 15
                color: "#ffffff"
                leftPadding: 16
                text: root.selectedUser

                background: Rectangle {
                    radius: 8
                    color: "#1a1b2e"
                    border.color: usernameField.activeFocus ? "#5cc6d0" : "#2a2b3e"
                    border.width: usernameField.activeFocus ? 2 : 1
                    Behavior on border.color { ColorAnimation { duration: 200 } }
                }

                onTextChanged: {
                    root.selectedUser = text
                }
            }

            /* ── Password Field ── */
            QQC2.TextField {
                id: passwordField
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                placeholderText: "Password"
                placeholderTextColor: "#4a4b5e"
                echoMode: TextInput.Password
                font.pixelSize: 15
                color: "#ffffff"
                leftPadding: 16
                focus: true

                background: Rectangle {
                    radius: 8
                    color: "#1a1b2e"
                    border.color: passwordField.activeFocus ? "#e8a0bf" : "#2a2b3e"
                    border.width: passwordField.activeFocus ? 2 : 1
                    Behavior on border.color { ColorAnimation { duration: 200 } }
                }

                Keys.onReturnPressed: sddm.login(usernameField.text, passwordField.text, sessionBox.currentIndex)
            }

            /* ── Session Selection ── */
            QQC2.ComboBox {
                id: sessionBox
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                model: sessionModel
                currentIndex: sessionModel.lastIndex
                textRole: "name"
                font.pixelSize: 13

                background: Rectangle {
                    radius: 8
                    color: "#1a1b2e"
                    border.color: "#2a2b3e"
                    border.width: 1
                }

                contentItem: Text {
                    text: sessionBox.displayText
                    color: "#6a6a8a"
                    leftPadding: 16
                    verticalAlignment: Text.AlignVCenter
                }

                popup: QQC2.Popup {
                    y: sessionBox.height + 4
                    width: sessionBox.width
                    implicitHeight: contentItem.implicitHeight
                    padding: 1

                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: sessionBox.popup.visible ? sessionBox.delegateModel : null
                        currentIndex: sessionBox.highlightedIndex
                        QQC2.ScrollIndicator.vertical: QQC2.ScrollIndicator { }
                    }

                    background: Rectangle {
                        color: "#1a1b2e"
                        radius: 8
                        border.color: "#30e8a0bf"
                    }
                }

                delegate: QQC2.ItemDelegate {
                    width: sessionBox.width
                    contentItem: Text {
                        text: name
                        color: highlighted ? "#0a0b16" : "#c8c8d8"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: highlighted ? "#e8a0bf" : "transparent"
                        radius: 6
                    }
                }
            }

            /* ── Action Button ── */
            QQC2.Button {
                id: loginButton
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                
                contentItem: Text {
                    text: "SIGN IN"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    font.letterSpacing: 2
                    color: "#0a0b16"
                    horizontalAlignment: Text.AlignHCenter
                }

                background: Rectangle {
                    radius: 8
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#e8a0bf" }
                        GradientStop { position: 1.0; color: "#5cc6d0" }
                    }
                    opacity: loginButton.hovered ? 1.0 : 0.9
                }

                onClicked: sddm.login(usernameField.text, passwordField.text, sessionBox.currentIndex)
            }
        }

        Item { Layout.fillHeight: true }

        /* ── User Profiles (Live Search Filtered Icons) ── */
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            Repeater {
                model: userModel

                delegate: Rectangle {
                    property string profileName: (typeof name !== "undefined" && name) ? name : ((modelData && modelData.name) ? modelData.name : root.selectedUser)
                    visible: root.isHumanUser(profileName) && (usernameField.text === "" || profileName.toLowerCase().indexOf(usernameField.text.toLowerCase()) !== -1)
                    Layout.preferredWidth: visible ? 40 : 0
                    Layout.preferredHeight: visible ? 40 : 0
                    radius: 20
                    color: (profileName === root.selectedUser) ? "#405cc6d0" : "#302a2b3e"
                    border.color: (profileName === root.selectedUser) ? "#5cc6d0" : "#3a3b4e"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: profileName && profileName.length > 0 ? profileName.charAt(0).toUpperCase() : "U"
                        color: "#d8e9ff"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.selectedUser = profileName
                            usernameField.text = profileName
                            passwordField.text = ""
                            passwordField.focus = true
                        }
                    }
                }
            }
        }

        /* ── Bottom System Buttons ── */
        Row {
            Layout.alignment: Qt.AlignBottom
            spacing: 24

            Text {
                text: "Suspend"
                font.pixelSize: 12
                color: "#6a6a8a"
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: parent.color = "#ffffff"
                    onExited: parent.color = "#6a6a8a"
                    onClicked: sddm.suspend()
                }
            }
            Text {
                text: "Reboot"
                font.pixelSize: 12
                color: "#6a6a8a"
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: parent.color = "#ffffff"
                    onExited: parent.color = "#6a6a8a"
                    onClicked: sddm.reboot()
                }
            }
            Text {
                text: "Shut Down"
                font.pixelSize: 12
                color: "#6a6a8a"
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: parent.color = "#ffffff"
                    onExited: parent.color = "#6a6a8a"
                    onClicked: sddm.powerOff()
                }
            }
        }
    }

    /* ── Top Status Bar (Real-time Indicators) ── */
    Row {
        id: statusBar
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 40
        spacing: 12

        // Hostname / OS indicator
        Rectangle {
            width: hostnameLabel.implicitWidth + 20
            height: 28
            radius: 14
            color: "#2012131f"
            border.color: "#30e8a0bf"
            border.width: 1

            Text {
                id: hostnameLabel
                anchors.centerIn: parent
                text: root.hostnameText.toUpperCase()
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1
                color: "#e8a0bf"
            }
        }

        // Battery Indicator
        Rectangle {
            width: batteryLabel.implicitWidth + 24
            height: 28
            radius: 14
            color: "#2012131f"
            border.color: "#305cc6d0"
            border.width: 1

            Text {
                id: batteryLabel
                anchors.centerIn: parent
                text: "BAT: " + root.batteryStatus
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1
                color: "#5cc6d0"
            }
        }

        // Network Indicator
        Rectangle {
            width: networkLabel.implicitWidth + 24
            height: 28
            radius: 14
            color: "#2012131f"
            border.color: root.networkStatus === "Offline" ? "#30ff5555" : "#305cc6d0"
            border.width: 1

            Text {
                id: networkLabel
                anchors.centerIn: parent
                text: root.networkStatus === "Offline" ? "✈ OFFLINE" : "NET: " + root.networkStatus.toUpperCase()
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1
                color: root.networkStatus === "Offline" ? "#ff5555" : "#5cc6d0"
            }
        }

        // Keyboard Layout Indicator (Clickable layout switcher)
        Rectangle {
            id: layoutButton
            width: layoutLabel.implicitWidth + 20
            height: 28
            radius: 14
            color: layoutMouseArea.containsMouse ? "#402a2b3e" : "#2012131f"
            border.color: "#30e8a0bf"
            border.width: 1

            Text {
                id: layoutLabel
                anchors.centerIn: parent
                text: "KEY: " + root.currentLayout.toUpperCase()
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1
                color: "#e8a0bf"
            }

            MouseArea {
                id: layoutMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.cycleLayout()
            }
        }
    }

    /* ── Timers ── */
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: { timeLabel.updateTime(); dateLabel.updateDate(); }
    }

    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: {
            root.updateBattery();
            root.updateNetwork();
        }
    }

    Component.onCompleted: {
        timeLabel.updateTime();
        dateLabel.updateDate();
        root.updateBattery();
        root.updateNetwork();
        root.updateHostname();
        if (typeof keyboard !== "undefined" && keyboard.layouts.length > 0) {
            root.currentLayout = keyboard.layouts[keyboard.currentLayout].shortName;
        }
        if (!root.selectedUser || root.selectedUser === "" || !root.isHumanUser(root.selectedUser)) {
            root.selectedUser = root.pickInitialUser();
        }
        usernameField.text = root.selectedUser;
        passwordField.focus = true;
    }
}

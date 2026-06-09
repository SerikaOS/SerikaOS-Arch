/* ============================================================
 * SerikaOS — Premium SDDM Login Theme
 * Frosted glass panel with animations
 * Themed around Serika Kuromi — Blue Archive
 * ============================================================ */
import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: "#1a1b2e"
    property string selectedUser: "liveuser"
    property var hiddenUsers: ["sddm", "nobody", "daemon", "bin", "sys", "mail", "ftp",
                               "http", "dbus", "polkitd", "git", "rtkit", "uuidd",
                               "ntp", "avahi", "colord", "tss", "systemd"]

    property string batteryStatusText: "🔋 --%"
    property bool hasBattery: false
    property string networkStatusText: "Offline"
    property bool isOnline: false

    function updateBattery() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "file:///sys/class/power_supply/BAT0/capacity");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    var capacity = xhr.responseText.trim();
                    hasBattery = true;
                    var statusXhr = new XMLHttpRequest();
                    statusXhr.open("GET", "file:///sys/class/power_supply/BAT0/status");
                    statusXhr.onreadystatechange = function() {
                        if (statusXhr.readyState === XMLHttpRequest.DONE) {
                            var status = statusXhr.responseText.trim();
                            var charging = (status === "Charging");
                            batteryStatusText = (charging ? "⚡ " : "🔋 ") + capacity + "%";
                        }
                    }
                    statusXhr.send();
                } else {
                    var xhr1 = new XMLHttpRequest();
                    xhr1.open("GET", "file:///sys/class/power_supply/BAT1/capacity");
                    xhr1.onreadystatechange = function() {
                        if (xhr1.readyState === XMLHttpRequest.DONE) {
                            if (xhr1.status === 200 || xhr1.status === 0) {
                                var capacity = xhr1.responseText.trim();
                                hasBattery = true;
                                var statusXhr1 = new XMLHttpRequest();
                                statusXhr1.open("GET", "file:///sys/class/power_supply/BAT1/status");
                                statusXhr1.onreadystatechange = function() {
                                    if (statusXhr1.readyState === XMLHttpRequest.DONE) {
                                        var status = statusXhr1.responseText.trim();
                                        var charging = (status === "Charging");
                                        batteryStatusText = (charging ? "⚡ " : "🔋 ") + capacity + "%";
                                    }
                                }
                                statusXhr1.send();
                            } else {
                                hasBattery = false;
                            }
                        }
                    }
                    xhr1.send();
                }
            }
        }
        xhr.send();
    }

    function updateNetwork() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "file:///proc/net/route");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    var lines = xhr.responseText.split('\n');
                    var online = false;
                    var activeIface = "";
                    for (var i = 1; i < lines.length; i++) {
                        var parts = lines[i].replace(/\s+/g, ' ').trim().split(' ');
                        if (parts.length >= 2) {
                            var iface = parts[0];
                            var dest = parts[1];
                            if (dest === "00000000") {
                                online = true;
                                activeIface = iface;
                                break;
                            }
                        }
                    }
                    isOnline = online;
                    if (online) {
                        if (activeIface.indexOf("wl") === 0 || activeIface.indexOf("wlan") === 0) {
                            networkStatusText = "📶  Connected (" + activeIface + ")";
                        } else {
                            networkStatusText = "🔌  Connected (" + activeIface + ")";
                        }
                    } else {
                        networkStatusText = "✈  Offline";
                    }
                } else {
                    networkStatusText = "✈  Offline";
                    isOnline = false;
                }
            }
        }
        xhr.send();
    }


    function isHumanUser(name) {
        if (!name || name === "") {
            return false
        }

        var lowered = name.toLowerCase()
        for (var i = 0; i < hiddenUsers.length; i++) {
            if (lowered === hiddenUsers[i] || lowered.indexOf("systemd-") === 0) {
                return false
            }
        }

        return true
    }

    function pickInitialUser() {
        if (typeof userModel === "undefined" || userModel.count === 0) {
            return "liveuser"
        }

        for (var i = 0; i < userModel.count; i++) {
            var candidate = userModel.data(userModel.index(i, 0), Qt.UserRole + 1)
            if (isHumanUser(candidate)) {
                return candidate
            }
        }

        return "liveuser"
    }

    /* ── Background Image ── */
    Image {
        id: backgroundImage
        anchors.fill: parent
        source: "Background.jpg"
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
    }

    /* ── Blur the background for depth ── */
    FastBlur {
        anchors.fill: backgroundImage
        source: backgroundImage
        radius: 40
        cached: true
    }

    /* ── Dark cinematic overlay ── */
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#B01a1b2e" }
            GradientStop { position: 0.5; color: "#9012131f" }
            GradientStop { position: 1.0; color: "#B01a1b2e" }
        }
    }

    Rectangle {
        width: parent.width * 0.28
        height: width
        radius: width / 2
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: -width * 0.18
        anchors.topMargin: -height * 0.1
        color: "#285cc6d0"
        opacity: 0.55
        layer.enabled: true
        layer.effect: FastBlur {
            radius: 96
        }
    }

    Rectangle {
        width: parent.width * 0.24
        height: width
        radius: width / 2
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: -width * 0.12
        anchors.bottomMargin: -height * 0.18
        color: "#22e8a0bf"
        opacity: 0.5
        layer.enabled: true
        layer.effect: FastBlur {
            radius: 88
        }
    }

    Column {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 40
        spacing: 10

        Rectangle {
            width: premiumLabel.implicitWidth + 28
            height: 34
            radius: 17
            color: "#2212131f"
            border.color: "#335cc6d0"
            border.width: 1

            Text {
                id: premiumLabel
                anchors.centerIn: parent
                text: "Curated live experience"
                color: "#c8f4f7"
                font.pixelSize: 12
                font.letterSpacing: 1.1
            }
        }

        Text {
            text: "Designed to feel polished from boot to desktop"
            color: "#8790ab"
            font.pixelSize: 13
            font.letterSpacing: 0.4
        }
    }

    /* ── Decorative accent line at top ── */
    Rectangle {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * 0.3
        height: 2
        radius: 1
        opacity: 0.6
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.3; color: "#e8a0bf" }
            GradientStop { position: 0.7; color: "#5cc6d0" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    /* ── Clock (top right) ── */
    ColumnLayout {
        id: clockContainer
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 40
        spacing: 4

        Text {
            id: timeLabel
            font.pixelSize: 56
            font.weight: Font.Light
            font.letterSpacing: 2
            color: "#e8a0bf"
            Layout.alignment: Qt.AlignRight
            opacity: 0.9

            function updateTime() {
                text = Qt.formatTime(new Date(), "HH:mm")
            }
        }

        Text {
            id: dateLabel
            font.pixelSize: 16
            font.letterSpacing: 1
            color: "#6a6a8a"
            Layout.alignment: Qt.AlignRight

            function updateDate() {
                text = Qt.formatDate(new Date(), "dddd, MMMM d yyyy")
            }
        }
    }

    /* ── Top Status Bar (Real-time Indicators) ── */
    Row {
        id: statusBar
        anchors.top: clockContainer.bottom
        anchors.right: parent.right
        anchors.topMargin: 12
        anchors.rightMargin: 40
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
                text: "🖥  " + (typeof sddm !== "undefined" && sddm.hostName ? sddm.hostName : "serikaos")
                color: "#e8a0bf"
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 1
            }
        }

        // Network Indicator
        Rectangle {
            width: networkLabel.implicitWidth + 20
            height: 28
            radius: 14
            color: "#2012131f"
            border.color: root.isOnline ? "#305cc6d0" : "#306a6a8a"
            border.width: 1

            Text {
                id: networkLabel
                anchors.centerIn: parent
                text: root.networkStatusText
                color: root.isOnline ? "#5cc6d0" : "#6a6a8a"
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 1
            }
        }

        // Battery Indicator
        Rectangle {
            visible: root.hasBattery
            width: visible ? (batteryLabel.implicitWidth + 20) : 0
            height: 28
            radius: 14
            color: "#2012131f"
            border.color: "#30e8a0bf"
            border.width: 1

            Text {
                id: batteryLabel
                anchors.centerIn: parent
                text: root.batteryStatusText
                color: "#e8a0bf"
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 1
            }
        }

        // Keyboard Layout switcher
        Rectangle {
            width: layoutLabel.implicitWidth + 20
            height: 28
            radius: 14
            color: "#2012131f"
            border.color: "#305cc6d0"
            border.width: 1

            Text {
                id: layoutLabel
                anchors.centerIn: parent
                text: "⌨  " + (typeof keyboard !== "undefined" && keyboard.layouts && keyboard.layouts.length > 0 ? keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase() : "US")
                color: "#5cc6d0"
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 1
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (typeof keyboard !== "undefined" && keyboard.layouts && keyboard.layouts.length > 1) {
                        keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
                    }
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            timeLabel.updateTime()
            dateLabel.updateDate()
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.updateBattery()
            root.updateNetwork()
        }
    }

    /* ── Frosted Glass Login Panel ── */
    Rectangle {
        id: loginPanel
        anchors.centerIn: parent
        width: 400
        height: 480
        radius: 24
        color: "#D012131f"
        border.color: "#2a2b3e"
        border.width: 1

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: 4
            radius: 40
            samples: 81
            color: "#60000000"
        }
    }

    /* ── Login Panel Content ── */
    ColumnLayout {
        anchors.centerIn: parent
        width: 340
        spacing: 16

        /* ── OS Branding ── */
        Text {
            text: "SerikaOS"
            font.pixelSize: 32
            font.bold: true
            font.letterSpacing: 2
            color: "#e8a0bf"
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: "Polished, calm, ready to go"
            font.pixelSize: 14
            font.letterSpacing: 1
            color: "#6a6a8a"
            Layout.alignment: Qt.AlignHCenter
        }

        /* ── Accent divider ── */
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 50
            height: 2
            radius: 1
            color: "#5cc6d0"
            opacity: 0.5
        }

        Item { Layout.preferredHeight: 8 }

        /* ── Username / User Search Field ── */
        QQC2.TextField {
            id: usernameField
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            placeholderText: "  Username or Search..."
            placeholderTextColor: "#4a4b5e"
            font.pixelSize: 14
            font.letterSpacing: 0.5
            color: "#c8c8d8"
            leftPadding: 44
            text: root.selectedUser

            background: Rectangle {
                radius: 12
                color: "#1a1b2e"
                border.color: usernameField.activeFocus ? "#e8a0bf" : "#2a2b3e"
                border.width: usernameField.activeFocus ? 2 : 1
                Behavior on border.color { ColorAnimation { duration: 200 } }
            }

            // Left-aligned avatar indicator inside the text field!
            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 10
                width: 24
                height: 24
                radius: 12
                color: "#27364a"
                border.color: "#3a4b60"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: root.selectedUser.length > 0 ? root.selectedUser.charAt(0).toUpperCase() : "U"
                    color: "#d8e9ff"
                    font.pixelSize: 11
                    font.bold: true
                }
            }

            onTextChanged: {
                var typed = text.trim()
                if (typed !== "" && typed !== root.selectedUser) {
                    root.selectedUser = typed
                }
            }
        }

        /* ── Password Field ── */
        QQC2.TextField {
            id: passwordField
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            placeholderText: "  Password"
            placeholderTextColor: "#4a4b5e"
            echoMode: TextInput.Password
            font.pixelSize: 14
            font.letterSpacing: 0.5
            color: "#c8c8d8"
            leftPadding: 16

            background: Rectangle {
                radius: 12
                color: "#1a1b2e"
                border.color: passwordField.activeFocus ? "#5cc6d0" : "#2a2b3e"
                border.width: passwordField.activeFocus ? 2 : 1

                Behavior on border.color {
                    ColorAnimation { duration: 200 }
                }
            }

            Keys.onReturnPressed: sddm.login(root.selectedUser, passwordField.text, sessionBox.currentIndex)
        }

        /* ── Session Selector ── */
        QQC2.ComboBox {
            id: sessionBox
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            model: sessionModel
            currentIndex: sessionModel.lastIndex
            textRole: "name"
            font.pixelSize: 13

            background: Rectangle {
                radius: 12
                color: "#1a1b2e"
                border.color: "#2a2b3e"
                border.width: 1
            }

            contentItem: Text {
                text: sessionBox.displayText
                font: sessionBox.font
                color: "#6a6a8a"
                leftPadding: 16
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            indicator: Text {
                text: "▾"
                color: "#6a6a8a"
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 14
            }
        }

        Item { Layout.preferredHeight: 4 }

        /* ── Login Button ── */
        QQC2.Button {
            id: loginButton
            Layout.fillWidth: true
            Layout.preferredHeight: 50

            contentItem: Text {
                text: "Enter SerikaOS"
                font.pixelSize: 16
                font.bold: true
                font.letterSpacing: 1
                color: "#1a1b2e"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                radius: 12
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: loginButton.pressed ? "#c87a9a" : (loginButton.hovered ? "#f0b8d4" : "#e8a0bf")
                    }
                    GradientStop {
                        position: 1.0
                        color: loginButton.pressed ? "#b06a8a" : (loginButton.hovered ? "#e8a0bf" : "#d48aaa")
                    }
                }

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            onClicked: sddm.login(root.selectedUser, passwordField.text, sessionBox.currentIndex)
        }

        /* ── Error Message ── */
        Text {
            id: errorMessage
            text: ""
            font.pixelSize: 12
            font.letterSpacing: 0.5
            color: "#ff6b6b"
            Layout.alignment: Qt.AlignHCenter
            visible: text !== ""
            opacity: visible ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }
        }
    }

    /* ── Power Buttons (bottom right) ── */
    RowLayout {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 40
        spacing: 12

        QQC2.Button {
            id: suspendButton
            contentItem: Text {
                text: "⏾"
                font.pixelSize: 18
                color: "#6a6a8a"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                implicitWidth: 44; implicitHeight: 44
                radius: 22
                color: suspendButton.hovered ? "#2a2b3e" : "transparent"
                border.color: suspendButton.hovered ? "#3a3b4e" : "transparent"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            onClicked: sddm.suspend()
        }

        QQC2.Button {
            id: rebootButton
            contentItem: Text {
                text: "⟳"
                font.pixelSize: 18
                color: "#5cc6d0"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                implicitWidth: 44; implicitHeight: 44
                radius: 22
                color: rebootButton.hovered ? "#2a2b3e" : "transparent"
                border.color: rebootButton.hovered ? "#3a3b4e" : "transparent"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            onClicked: sddm.reboot()
        }

        QQC2.Button {
            id: powerButton
            contentItem: Text {
                text: "⏻"
                font.pixelSize: 18
                color: "#e8a0bf"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                implicitWidth: 44; implicitHeight: 44
                radius: 22
                color: powerButton.hovered ? "#2a2b3e" : "transparent"
                border.color: powerButton.hovered ? "#3a3b4e" : "transparent"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            onClicked: sddm.powerOff()
        }
    }

    /* ── User Profiles (bottom-left, Windows-like chooser with live search filtering) ── */
    RowLayout {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 40
        anchors.bottomMargin: 74
        spacing: 10

        Repeater {
            model: userModel

            delegate: Rectangle {
                property string profileName: (typeof name !== "undefined" && name) ? name : ((modelData && modelData.name) ? modelData.name : root.selectedUser)
                visible: root.isHumanUser(profileName) && (usernameField.text === "" || profileName.toLowerCase().indexOf(usernameField.text.toLowerCase()) !== -1)
                Layout.preferredWidth: visible ? 44 : 0
                Layout.preferredHeight: visible ? 44 : 0
                radius: 22
                color: (profileName === root.selectedUser) ? "#405cc6d0" : "#302a2b3e"
                border.color: (profileName === root.selectedUser) ? "#5cc6d0" : "#3a3b4e"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: profileName && profileName.length > 0 ? profileName.charAt(0).toUpperCase() : "U"
                    color: "#d8e9ff"
                    font.pixelSize: 14
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

    /* ── SerikaOS branding (bottom left) ── */
    Text {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 40
        text: "SerikaOS"
        font.pixelSize: 12
        font.letterSpacing: 2
        color: "#3a3b4e"
    }

    /* ── Initialize ── */
    Component.onCompleted: {
        timeLabel.updateTime()
        dateLabel.updateDate()
        if (!root.selectedUser || root.selectedUser === "" || !root.isHumanUser(root.selectedUser)) {
            root.selectedUser = root.pickInitialUser()
        }
        usernameField.text = root.selectedUser
        passwordField.focus = true
        root.updateBattery()
        root.updateNetwork()
    }

    /* ── Login Error Handler ── */
    Connections {
        target: sddm
        function onLoginFailed() {
            errorMessage.text = "Incorrect username or password"
            passwordField.text = ""
            passwordField.focus = true

            /* Shake animation on error */
            shakeAnimation.start()
        }
        function onLoginSucceeded() {
            errorMessage.text = ""
        }
    }

    /* ── Panel shake on error ── */
    SequentialAnimation {
        id: shakeAnimation
        NumberAnimation { target: loginPanel; property: "anchors.horizontalCenterOffset"; to: -10; duration: 50 }
        NumberAnimation { target: loginPanel; property: "anchors.horizontalCenterOffset"; to: 10; duration: 50 }
        NumberAnimation { target: loginPanel; property: "anchors.horizontalCenterOffset"; to: -6; duration: 50 }
        NumberAnimation { target: loginPanel; property: "anchors.horizontalCenterOffset"; to: 6; duration: 50 }
        NumberAnimation { target: loginPanel; property: "anchors.horizontalCenterOffset"; to: 0; duration: 50 }
    }

    /* ── Keyboard shortcuts ── */
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            sddm.login(root.selectedUser, passwordField.text, sessionBox.currentIndex)
            event.accepted = true
        }
    }
}

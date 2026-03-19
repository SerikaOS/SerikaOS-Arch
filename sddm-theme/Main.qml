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

            Text {
                text: "Welcome back, " + root.selectedUser
                color: "#c8c8d8"
                font.pixelSize: 16
                font.weight: Font.Medium
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

                Keys.onReturnPressed: sddm.login(root.selectedUser, passwordField.text, sessionBox.currentIndex)
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

                onClicked: sddm.login(root.selectedUser, passwordField.text, sessionBox.currentIndex)
            }
        }

        Item { Layout.fillHeight: true }

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

    /* ── Timers ── */
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: { timeLabel.updateTime(); dateLabel.updateDate(); }
    }

    Component.onCompleted: {
        timeLabel.updateTime();
        dateLabel.updateDate();
    }
}

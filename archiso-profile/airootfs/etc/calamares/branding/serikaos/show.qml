/* ============================================================
 * SerikaOS — Calamares Installation Slideshow
 * Premium animated slideshow with Serika Kuromi theming
 * ============================================================ */
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Presentation {
    id: presentation

    Timer {
        interval: 6000
        running: true
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    /* ── Slide 1: Welcome ── */
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1a1b2e"

            /* Subtle gradient overlay */
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#1a1b2e" }
                    GradientStop { position: 1.0; color: "#12131f" }
                }
            }

            /* Decorative top accent line */
            Rectangle {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.4
                height: 3
                radius: 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.3; color: "#e8a0bf" }
                    GradientStop { position: 0.7; color: "#5cc6d0" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 24

                Text {
                    text: "Welcome to SerikaOS"
                    font.pixelSize: 36
                    font.bold: true
                    font.letterSpacing: 1
                    color: "#e8a0bf"
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 60
                    height: 2
                    radius: 1
                    color: "#5cc6d0"
                    opacity: 0.6
                }

                Text {
                    text: "A premium rolling Linux distribution"
                    font.pixelSize: 17
                    color: "#c8c8d8"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Themed around Serika Kuromi — Blue Archive"
                    font.pixelSize: 14
                    color: "#6a6a8a"
                    Layout.alignment: Qt.AlignHCenter
                }

                Item { Layout.preferredHeight: 20 }

                Text {
                    text: "Your system is being installed. This will take a few minutes."
                    font.pixelSize: 13
                    color: "#6a6a8a"
                    Layout.alignment: Qt.AlignHCenter
                }

                /* Progress dots */
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8
                    Repeater {
                        model: 3
                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: "#5cc6d0"
                            opacity: 0.4 + index * 0.2
                        }
                    }
                }
            }
        }
    }

    /* ── Slide 2: Your Rules ── */
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1a1b2e"

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#12131f" }
                    GradientStop { position: 1.0; color: "#1a1b2e" }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 24

                Text {
                    text: "🔓"
                    font.pixelSize: 48
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Your System, Your Rules"
                    font.pixelSize: 30
                    font.bold: true
                    color: "#5cc6d0"
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 60; height: 2; radius: 1
                    color: "#e8a0bf"; opacity: 0.5
                }

                Column {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    Text {
                        text: "✦  Zero bloatware — every app was chosen by you"
                        font.pixelSize: 15; color: "#c8c8d8"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "✦  9 desktop environments to choose from"
                        font.pixelSize: 15; color: "#c8c8d8"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "✦  4 kernels — standard, zen, hardened, or LTS"
                        font.pixelSize: 15; color: "#c8c8d8"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "✦  You own every decision about your machine"
                        font.pixelSize: 15; color: "#c8c8d8"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }

    /* ── Slide 3: Privacy ── */
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1a1b2e"

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#1a1b2e" }
                    GradientStop { position: 1.0; color: "#12131f" }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 24

                Text {
                    text: "🛡️"
                    font.pixelSize: 48
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Privacy First"
                    font.pixelSize: 30
                    font.bold: true
                    color: "#e8a0bf"
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 60; height: 2; radius: 1
                    color: "#5cc6d0"; opacity: 0.5
                }

                Grid {
                    Layout.alignment: Qt.AlignHCenter
                    columns: 2
                    columnSpacing: 40
                    rowSpacing: 14

                    Text { text: "🔒  DNS-over-HTTPS"; font.pixelSize: 15; color: "#c8c8d8" }
                    Text { text: "🔒  MAC Randomization"; font.pixelSize: 15; color: "#c8c8d8" }
                    Text { text: "🔒  Kernel Hardening"; font.pixelSize: 15; color: "#c8c8d8" }
                    Text { text: "🔒  Telemetry Blocked"; font.pixelSize: 15; color: "#c8c8d8" }
                    Text { text: "🔒  AppArmor Support"; font.pixelSize: 15; color: "#c8c8d8" }
                    Text { text: "🔒  Firejail Sandboxing"; font.pixelSize: 15; color: "#c8c8d8" }
                }

                Item { Layout.preferredHeight: 8 }

                Text {
                    text: "Your data stays on your machine. Period."
                    font.pixelSize: 14
                    font.italic: true
                    color: "#6a6a8a"
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    /* ── Slide 4: Power ── */
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1a1b2e"

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#12131f" }
                    GradientStop { position: 1.0; color: "#1a1b2e" }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 24

                Text {
                    text: "⚡"
                    font.pixelSize: 48
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Pure SerikaOS Power"
                    font.pixelSize: 30
                    font.bold: true
                    color: "#d4a853"
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 60; height: 2; radius: 1
                    color: "#d4a853"; opacity: 0.5
                }

                Column {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    Text {
                        text: "⚡  Rolling release — always bleeding edge"
                        font.pixelSize: 15; color: "#c8c8d8"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "⚡  Full access to the AUR ecosystem when enabled"
                        font.pixelSize: 15; color: "#c8c8d8"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "⚡  Powered by pacman — fast, reliable, transparent"
                        font.pixelSize: 15; color: "#c8c8d8"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "⚡  Optimized with zstd compression & zram"
                        font.pixelSize: 15; color: "#c8c8d8"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }

    /* ── Slide 5: Premium Experience ── */
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1a1b2e"

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#1a1b2e" }
                    GradientStop { position: 1.0; color: "#12131f" }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 24

                Text {
                    text: "✨"
                    font.pixelSize: 48
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Premium by Design"
                    font.pixelSize: 30
                    font.bold: true
                    color: "#e8a0bf"
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 60; height: 2; radius: 1
                    color: "#e8a0bf"; opacity: 0.5
                }

                Column {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    Text {
                        text: "✦  Custom GRUB bootloader theme"
                        font.pixelSize: 15; color: "#c8c8d8"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "✦  Themed SDDM login screen with frosted glass"
                        font.pixelSize: 15; color: "#c8c8d8"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "✦  Matching KDE & Hyprland color schemes"
                        font.pixelSize: 15; color: "#c8c8d8"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "✦  Custom wallpapers, sounds & icon themes"
                        font.pixelSize: 15; color: "#c8c8d8"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "✦  Custom fastfetch with SerikaOS ASCII art"
                        font.pixelSize: 15; color: "#c8c8d8"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }

    /* ── Slide 6: Serika Kuromi ── */
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1a1b2e"

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#12131f" }
                    GradientStop { position: 1.0; color: "#1a1b2e" }
                }
            }

            /* Decorative bottom accent line */
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.4
                height: 3
                radius: 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.3; color: "#e8a0bf" }
                    GradientStop { position: 0.7; color: "#d4a853" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 24

                Text {
                    text: "💜"
                    font.pixelSize: 48
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Serika Kuromi"
                    font.pixelSize: 30
                    font.bold: true
                    color: "#e8a0bf"
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 60; height: 2; radius: 1
                    color: "#d4a853"; opacity: 0.5
                }

                Text {
                    text: "Every pixel themed with love.\nFrom Blue Archive, with care."
                    font.pixelSize: 16
                    color: "#c8c8d8"
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.5
                    Layout.alignment: Qt.AlignHCenter
                }

                Item { Layout.preferredHeight: 10 }

                /* Color palette preview */
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6
                    Repeater {
                        model: ["#1a1b2e", "#2a2b3e", "#e8a0bf", "#5cc6d0", "#d4a853", "#c8c8d8", "#6a6a8a"]
                        Rectangle {
                            width: 28; height: 28; radius: 6
                            color: modelData
                            border.color: "#3a3b4e"
                            border.width: 1
                        }
                    }
                }

                Item { Layout.preferredHeight: 10 }

                Text {
                    text: "Thank you for choosing SerikaOS ♡"
                    font.pixelSize: 14
                    font.italic: true
                    color: "#6a6a8a"
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}

import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }
    height: 36
    color: "transparent"

    // Module state
    property string cpuText: "..."
    property string memText: "..."
    property string tempText: "..."
    property string netText: "..."
    property string kernelText: ""
    property string packagesText: ""
    property string mpdText: ""

    // Tokyo Night palette
    readonly property color moduleBg:    "#160654"
    readonly property color fg:          "#c0caf5"
    readonly property color accent:      "#7aa2f7"
    readonly property color urgentColor: "#f7768e"
    readonly property string monoFont:   "SpaceMono Nerd Font"

    // ── Clock ────────────────────────────────────────────────────────
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // ── System stats (polled every 3s, separate processes) ────────────
    Process {
        id: cpuProc
        running: false
        command: ["bash", "-c", "top -bn1 | grep '%Cpu' | awk '{printf \"%.0f\", $2}'"]
        stdout: SplitParser { onRead: line => root.cpuText  = line.trim() }
    }
    Process {
        id: memProc
        running: false
        command: ["bash", "-c", "free --si -g | awk 'NR==2{print $3}'"]
        stdout: SplitParser { onRead: line => root.memText  = line.trim() + "GiB" }
    }
    Process {
        id: tempProc
        running: false
        command: ["bash", "-c", "awk '{printf \"%.0f\", $1/1000}' /sys/class/hwmon/hwmon1/temp1_input 2>/dev/null || echo N/A"]
        stdout: SplitParser { onRead: line => root.tempText = line.trim() + "°C" }
    }
    Process {
        id: netProc
        running: false
        command: ["bash", "-c", "ip -br link show enp39s0 2>/dev/null | awk '{print $2}' || echo offline"]
        stdout: SplitParser { onRead: line => root.netText  = line.trim() }
    }
    Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.running  = false; cpuProc.running  = true
            memProc.running  = false; memProc.running  = true
            tempProc.running = false; tempProc.running = true
            netProc.running  = false; netProc.running  = true
        }
    }

    // ── Kernel version (one-shot) ────────────────────────────────────
    Process {
        running: true
        command: ["bash", "-c", "uname -r | cut -d'-' -f1"]
        stdout: SplitParser {
            onRead: line => root.kernelText = line.trim()
        }
    }

    // ── Package updates (every 10 min) ───────────────────────────────
    Process {
        id: pkgProc
        running: false
        command: [
            "bash", "-c",
            "a=$(checkupdates 2>/dev/null | wc -l);" +
            "b=$(yay -Qum 2>/dev/null | wc -l);" +
            "t=$((a+b));" +
            "if [ $t -gt 0 ]; then" +
            "  echo \"($a/$b)\";" +
            "else" +
            "  echo 'Up to date.';" +
            "fi"
        ]
        stdout: SplitParser {
            onRead: line => root.packagesText = line.trim()
        }
    }
    Timer {
        interval: 600000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: { pkgProc.running = false; pkgProc.running = true }
    }

    // ── MPD via mpc (every 5s) ───────────────────────────────────────
    Process {
        id: mpdProc
        running: false
        command: ["bash", "-c", "mpc --format '%artist% - %title%' current 2>/dev/null || echo ''"]
        stdout: SplitParser {
            onRead: line => root.mpdText = line.trim()
        }
    }
    Timer {
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: { mpdProc.running = false; mpdProc.running = true }
    }

    // ── Layout ───────────────────────────────────────────────────────
    Item {
        anchors.fill: parent

        // LEFT ────────────────────────────────────────────────────────
        RowLayout {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: 4
            }
            spacing: 4

            // Workspaces
            Rectangle {
                color: root.moduleBg
                height: 30
                implicitWidth: wsRow.implicitWidth + 8
                radius: 4

                RowLayout {
                    id: wsRow
                    anchors.centerIn: parent
                    spacing: 0

                    Repeater {
                        model: 9

                        Item {
                            required property int index
                            readonly property int wsId: index + 1
                            readonly property bool isActive:
                                Hyprland.focusedWorkspace !== null &&
                                Hyprland.focusedWorkspace.id === wsId

                            width: 22
                            height: 28

                            // Active underline
                            Rectangle {
                                anchors {
                                    bottom: parent.bottom
                                    horizontalCenter: parent.horizontalCenter
                                }
                                width: 14
                                height: 2
                                color: isActive ? root.accent : "transparent"
                            }

                            Text {
                                anchors.centerIn: parent
                                text: wsId.toString()
                                color: isActive ? root.accent : root.fg
                                font.family: root.monoFont
                                font.pixelSize: 12
                                font.bold: isActive
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: Hyprland.dispatch("workspace " + wsId)
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }
                }
            }

            // Clock
            Rectangle {
                color: root.moduleBg
                height: 30
                implicitWidth: clockLabel.implicitWidth + 16
                radius: 4

                Text {
                    id: clockLabel
                    anchors.centerIn: parent
                    text: " " + Qt.formatDateTime(clock.date, "HH:mm:ss")
                    color: root.fg
                    font.family: root.monoFont
                    font.pixelSize: 13
                }
            }

            // Kernel
            Rectangle {
                color: root.moduleBg
                height: 30
                implicitWidth: kernelLabel.implicitWidth + 16
                radius: 4
                visible: root.kernelText.length > 0

                Text {
                    id: kernelLabel
                    anchors.centerIn: parent
                    text: " " + root.kernelText
                    color: root.fg
                    font.family: root.monoFont
                    font.pixelSize: 13
                }
            }

            // Packages
            Rectangle {
                color: root.moduleBg
                height: 30
                implicitWidth: pkgLabel.implicitWidth + 16
                radius: 4
                visible: root.packagesText.length > 0

                Text {
                    id: pkgLabel
                    anchors.centerIn: parent
                    text: " " + root.packagesText
                    color: root.fg
                    font.family: root.monoFont
                    font.pixelSize: 13
                }
            }

            // MPD
            Rectangle {
                color: root.moduleBg
                height: 30
                implicitWidth: Math.min(mpdLabel.implicitWidth + 16, 260)
                radius: 4
                visible: root.mpdText.length > 0
                clip: true

                Text {
                    id: mpdLabel
                    anchors.centerIn: parent
                    width: Math.min(implicitWidth, 240)
                    text: " " + root.mpdText
                    color: root.accent
                    font.family: root.monoFont
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }
            }
        }

        // CENTER – active window title ─────────────────────────────────
        Rectangle {
            anchors.centerIn: parent
            color: root.moduleBg
            height: 30
            width: Math.min(winTitle.implicitWidth + 16, 500)
            radius: 4
            clip: true

            Text {
                id: winTitle
                anchors.centerIn: parent
                width: Math.min(implicitWidth, 480)
                text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
                color: root.fg
                font.family: root.monoFont
                font.pixelSize: 13
                elide: Text.ElideRight
            }
        }

        // RIGHT ───────────────────────────────────────────────────────
        RowLayout {
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: 4
            }
            spacing: 4

            // System Tray
            Rectangle {
                id: trayModule
                color: root.moduleBg
                height: 30
                implicitWidth: trayRow.implicitWidth + 16
                radius: 16
                visible: trayRow.implicitWidth > 0

                RowLayout {
                    id: trayRow
                    anchors.centerIn: parent
                    spacing: 6

                    Repeater {
                        model: SystemTray.items

                        delegate: Item {
                            required property var modelData

                            width: 18
                            height: 18

                            Image {
                                anchors.fill: parent
                                source: {
                                    var icon = modelData.icon
                                    if (!icon || icon.length === 0) return ""
                                    if (icon.startsWith("/") || icon.startsWith("file://"))
                                        return icon
                                    return Quickshell.iconPath(icon) || ""
                                }
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                hoverEnabled: true

                                ToolTip.visible: containsMouse
                                ToolTip.text: modelData.tooltipTitle || modelData.title || ""

                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton && modelData.hasMenu)
                                        modelData.menu.open(this, mouseX, mouseY)
                                }
                            }
                        }
                    }
                }
            }

            // Temperature
            Rectangle {
                color: root.moduleBg
                height: 30
                implicitWidth: tempLabel.implicitWidth + 16
                radius: 4

                Text {
                    id: tempLabel
                    anchors.centerIn: parent
                    text: " " + root.tempText
                    color: root.fg
                    font.family: root.monoFont
                    font.pixelSize: 13
                }
            }

            // CPU
            Rectangle {
                color: root.moduleBg
                height: 30
                implicitWidth: cpuLabel.implicitWidth + 16
                radius: 4

                Text {
                    id: cpuLabel
                    anchors.centerIn: parent
                    text: " " + root.cpuText + "%"
                    color: root.fg
                    font.family: root.monoFont
                    font.pixelSize: 13
                }
            }

            // Memory
            Rectangle {
                color: root.moduleBg
                height: 30
                implicitWidth: memLabel.implicitWidth + 16
                radius: 4

                Text {
                    id: memLabel
                    anchors.centerIn: parent
                    text: " " + root.memText
                    color: root.fg
                    font.family: root.monoFont
                    font.pixelSize: 13
                }
            }

            // Network
            Rectangle {
                color: root.moduleBg
                height: 30
                implicitWidth: netLabel.implicitWidth + 16
                radius: 4

                Text {
                    id: netLabel
                    anchors.centerIn: parent
                    text: " " + root.netText
                    color: root.fg
                    font.family: root.monoFont
                    font.pixelSize: 13
                }
            }

            // Volume (PipeWire)
            Rectangle {
                id: volModule
                color: root.moduleBg
                height: 30
                implicitWidth: volLabel.implicitWidth + 16
                radius: 4

                readonly property var  sink:     Pipewire.defaultAudioSink
                readonly property real vol:      sink && sink.audio ? sink.audio.volume : 0
                readonly property bool isMuted:  sink && sink.audio ? sink.audio.muted  : false

                readonly property string volIcon: {
                    if (isMuted || vol <= 0) return ""
                    if (vol < 0.34)          return ""
                    if (vol < 0.67)          return ""
                    return ""
                }

                Text {
                    id: volLabel
                    anchors.centerIn: parent
                    text: volModule.isMuted
                          ? " Muted"
                          : (volModule.volIcon + " " + Math.round(volModule.vol * 100) + "%")
                    color: volModule.isMuted ? root.urgentColor : root.fg
                    font.family: root.monoFont
                    font.pixelSize: 13
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        if (volModule.sink && volModule.sink.audio)
                            volModule.sink.audio.muted = !volModule.sink.audio.muted
                    }
                    onWheel: wheel => {
                        if (volModule.sink && volModule.sink.audio) {
                            var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                            volModule.sink.audio.volume =
                                Math.max(0, Math.min(1.5, volModule.sink.audio.volume + delta))
                        }
                    }
                }
            }
        }
    }
}

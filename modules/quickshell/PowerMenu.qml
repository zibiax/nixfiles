import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Power menu – triggered via: qs ipc call powermenu
// Hyprland bind: bind = SUPER SHIFT, SPACE, exec, qs ipc call powermenu
FloatingWindow {
    id: root

    // Left-center, matching the original rofi powermenu position
    x: screen ? screen.x + 15 : 15
    y: screen ? screen.y + Math.round((screen.height - height) / 2) : 560

    width:  115
    height: confirmState ? 150 : 325
    color:  "#1a1b26"

    Behavior on height { NumberAnimation { duration: 120 } }

    // ── State ─────────────────────────────────────────────────────────
    property bool   confirmState:   false
    property string pendingAction:  ""
    property string pendingLabel:   ""

    onVisibleChanged: {
        if (!visible) {
            confirmState  = false
            pendingAction = ""
        }
    }

    Keys.onEscapePressed: {
        if (confirmState) confirmState = false
        else root.visible = false
    }

    // ── Execute after confirmation ────────────────────────────────────
    Process {
        id: execProc
        running: false
        command: ["bash", "-c", root.pendingAction]
        onExited: root.visible = false
    }

    Process {
        id: lockProc
        running: false
        command: ["hyprlock"]
        onExited: root.visible = false
    }

    function triggerAction() {
        if (pendingAction === "lock") {
            lockProc.running = true
        } else {
            execProc.running = false
            execProc.running = true
        }
        root.visible = false
    }

    function requestAction(action, label) {
        pendingAction = action
        pendingLabel  = label
        confirmState  = true
    }

    // ── UI ────────────────────────────────────────────────────────────
    Item {
        anchors.fill: parent

        // Main buttons
        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6
            visible: !root.confirmState

            Repeater {
                model: [
                    { icon: "", label: "Shutdown", action: "systemctl poweroff"      },
                    { icon: "", label: "Reboot",   action: "systemctl reboot"        },
                    { icon: "", label: "Lock",     action: "lock"                    },
                    { icon: "", label: "Suspend",  action: "systemctl suspend"       },
                    { icon: "", label: "Logout",   action: "hyprctl dispatch exit 0" }
                ]

                delegate: Rectangle {
                    required property var modelData

                    width:  parent.width
                    height: 48
                    color:  actionArea.containsMouse ? "#282a3a" : "#1e2030"
                    radius: 4

                    Behavior on color { ColorAnimation { duration: 80 } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        color: "#c0caf5"
                        font.family: "feather"
                        font.pixelSize: 24
                    }

                    MouseArea {
                        id: actionArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    root.requestAction(modelData.action, modelData.label)
                    }
                }
            }
        }

        // Confirmation overlay
        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8
            visible: root.confirmState

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.pendingLabel + "?"
                color: "#c0caf5"
                font.family: "SpaceMono Nerd Font"
                font.pixelSize: 12
                font.bold: true
            }

            Repeater {
                model: [
                    { icon: "", yes: true  },
                    { icon: "", yes: false }
                ]

                delegate: Rectangle {
                    required property var modelData

                    width:  parent.width
                    height: 40
                    color:  confirmArea.containsMouse
                            ? (modelData.yes ? "#364a82" : "#2d2030")
                            : "#1e2030"
                    radius: 4

                    Behavior on color { ColorAnimation { duration: 80 } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        color: "#c0caf5"
                        font.family: "feather"
                        font.pixelSize: 22
                    }

                    MouseArea {
                        id: confirmArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.yes) root.triggerAction()
                            else               root.confirmState = false
                        }
                    }
                }
            }
        }
    }
}

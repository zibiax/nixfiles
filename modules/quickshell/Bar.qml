import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Port of waybar/config-dp-1.jsonc + waybar/style.css. Waybar only runs on
// DP-1 (see scripts/local/relaunch.sh), so this bar does too.
PanelWindow {
    id: root

    screen: Quickshell.screens.find(s => s.name === "DP-1") ?? Quickshell.screens[0]
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 36
    exclusiveZone: 36
    color: "transparent"
    // Matched by the blur layer rule in hypr/hyprland.{lua,conf}.
    WlrLayershell.namespace: "quickshell-bar"

    readonly property color moduleBg: "#160654"
    readonly property color accent: "#7aa2f7"
    readonly property color urgent: "#f7768e"
    readonly property string netInterface: "enp39s0"
    // hwmonN numbering changes between boots; this is the CPU's k10temp (Tctl).
    readonly property string hwmonPath: "/sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon*/temp1_input"

    property string cpuText: ""
    property string memText: ""
    property string tempText: ""
    property string netText: ""
    property string kernelText: ""
    property string packagesText: ""
    property string mpdText: ""
    property bool clockAlt: false

    // hyprland.lua only accepts Lua dispatchers ("hl.dsp.focus(...)"); the
    // plain ones are kept for a hyprland.conf setup.
    function focusWorkspace(ws) {
        Hyprland.dispatch(Hyprland.usingLua
            ? "hl.dsp.focus({ workspace = " + JSON.stringify(ws) + " })"
            : "workspace " + ws)
    }

    function poll(proc) {
        if (!proc.running) proc.running = true
    }

    // ── Clock ────────────────────────────────────────────────────────
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // ── CPU: waybar's bare "{}" is the 1-minute load average ──────────
    Process {
        id: cpuProc
        command: ["cat", "/proc/loadavg"]
        stdout: SplitParser { onRead: line => root.cpuText = Number(line.split(" ")[0]) + "%" }
    }

    // ── Memory: (MemTotal - MemAvailable) in GiB ──────────────────────
    Process {
        id: memProc
        command: ["cat", "/proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                const kb = key => Number((text.match(new RegExp("^" + key + ":\\s+(\\d+)", "m")) || [0, 0])[1])
                // waybar rounds to 2 decimals and drops trailing zeros (14.7, not 14.70)
                root.memText = Number(((kb("MemTotal") - kb("MemAvailable")) / 1048576).toFixed(2)) + "GiB"
            }
        }
    }

    // ── Temperature ──────────────────────────────────────────────────
    Process {
        id: tempProc
        command: ["sh", "-c", "cat " + root.hwmonPath]
        stdout: SplitParser {
            onRead: line => root.tempText = Math.round(Number(line) / 1000) + "°C"
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            root.poll(cpuProc)
            root.poll(memProc)
            root.poll(tempProc)
        }
    }

    // ── Network: "<ifname> " while the link is up, hidden otherwise ──
    Process {
        id: netProc
        command: ["cat", "/sys/class/net/" + root.netInterface + "/operstate"]
        stdout: SplitParser {
            onRead: line => root.netText = line.trim() === "up" ? root.netInterface + " " : ""
        }
        onExited: code => { if (code !== 0) root.netText = "" }
    }
    Timer {
        interval: 10000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.poll(netProc)
    }

    // ── Kernel (once) ────────────────────────────────────────────────
    Process {
        running: true
        command: ["sh", "-c", "uname -r | cut -d '-' -f1"]
        stdout: SplitParser { onRead: line => root.kernelText = line.trim() }
    }

    // ── nixpkgs lock age, same script as waybar's custom/pacman ───────
    Process {
        id: pkgProc
        command: ["sh", "-c", "$HOME/.config/waybar/scripts/package-updates.sh"]
        stdout: SplitParser { onRead: line => root.packagesText = line.trim() }
    }
    Timer {
        interval: 600000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.poll(pkgProc)
    }

    // ── MPD: waybar's mpd module formats ─────────────────────────────
    function escapeHtml(s) {
        return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    }
    Process {
        id: mpdProc
        command: ["mpc", "--format", "%artist%\t%title%", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "") return // mpd down, see onExited
                const lines = text.trim().split("\n")
                const opts = lines[lines.length - 1]
                const on = key => new RegExp(key + ":\\s*on").test(opts)
                const state = lines.length >= 3 ? (lines[1].match(/^\[(\w+)\]/) || [])[1] : "stopped"
                const blue = s => "<font color=\"#7aa2f7\">" + s + "</font>"

                if (state === "playing") {
                    const [artist, title] = lines[0].split("\t")
                    root.mpdText = blue(" ") + root.escapeHtml((artist || "") + " - " + (title || ""))
                } else if (state === "paused") {
                    root.mpdText = ""
                } else {
                    root.mpdText = (on("consume") ? " " : "")
                        + (on("random") ? " " : "<font color=\"#f53c3c\"></font> ")
                        + (on("repeat") ? " " : "")
                        + (on("single") ? "1 " : "")
                        + "Stopped "
                }
            }
        }
        onExited: code => { if (code !== 0) root.mpdText = "Disconnected " }
    }
    // Refresh on every player/option change, plus waybar's 10s interval.
    Process {
        id: mpdIdle
        running: true
        command: ["mpc", "idleloop", "player", "options"]
        stdout: SplitParser { onRead: root.poll(mpdProc) }
    }
    Timer {
        interval: 10000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            root.poll(mpdProc)
            root.poll(mpdIdle)
        }
    }

    // ── Volume ───────────────────────────────────────────────────────
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    // ── Layout ───────────────────────────────────────────────────────
    Item {
        anchors.fill: parent

        // LEFT: ws1..9, clock, kernel, pacman, mpd
        RowLayout {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            spacing: 0

            // custom/ws*: only existing or focused workspaces are shown.
            Repeater {
                model: 9

                Rectangle {
                    id: ws
                    required property int index
                    readonly property int wsId: index + 1
                    readonly property bool active: Hyprland.focusedWorkspace?.id === wsId
                    readonly property bool exists: Hyprland.workspaces.values.some(w => w.id === wsId)

                    visible: active || exists
                    implicitWidth: wsLabel.implicitWidth + 12
                    implicitHeight: 30
                    color: wsMouse.containsMouse ? "#ed2b2b" : root.moduleBg

                    Text {
                        id: wsLabel
                        anchors.centerIn: parent
                        text: ws.wsId
                        color: wsMouse.containsMouse ? "#cdd6f4" : "#c0caf5"
                        font.family: "SpaceMono Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: 14
                    }

                    // box-shadow: inset 0 -2px #7aa2f7
                    Rectangle {
                        visible: ws.active
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: 2
                        color: root.accent
                    }

                    MouseArea {
                        id: wsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.focusWorkspace(ws.wsId)
                        onWheel: wheel => root.focusWorkspace(wheel.angleDelta.y > 0 ? "e-1" : "e+1")
                    }
                }
            }

            BarModule {
                icon: root.clockAlt ? "" : ""
                text: Qt.formatDateTime(clock.date, root.clockAlt ? "dd-MM-yyyy" : "HH:mm:ss")
                onClicked: root.clockAlt = !root.clockAlt
            }

            BarModule {
                icon: ""
                text: root.kernelText
                radius: 8
            }

            BarModule {
                icon: ""
                text: root.packagesText
                radius: 8
            }

            // #mpd has no rule in style.css: no block, default text colour.
            Text {
                visible: root.mpdText.length > 0
                text: root.mpdText
                textFormat: Text.StyledText
                color: "#c0caf5"
                font.family: "SpaceMono Nerd Font"
                font.weight: Font.Black
                font.pixelSize: 14
            }
        }

        // CENTER: hyprland/window, max-length 48
        BarModule {
            anchors.centerIn: parent
            radius: 8
            text: {
                // Hyprland.activeToplevel stays null until the next focus
                // event; the Wayland toplevel list knows it immediately.
                const t = ToplevelManager.activeToplevel?.title ?? ""
                return t.length > 48 ? t.slice(0, 47) + "…" : t
            }
        }

        // RIGHT: tray, temperature, cpu, memory, network, pulseaudio
        RowLayout {
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            spacing: 0

            Rectangle {
                visible: SystemTray.items.values.length > 0
                implicitWidth: trayRow.implicitWidth + 20
                implicitHeight: 30
                Layout.rightMargin: 16
                radius: 16
                color: root.moduleBg

                Row {
                    id: trayRow
                    anchors.centerIn: parent
                    spacing: 8

                    Repeater {
                        model: SystemTray.items

                        Image {
                            id: trayIcon
                            required property var modelData
                            width: 18
                            height: 18
                            source: modelData.icon
                            sourceSize: Qt.size(18, 18)
                            smooth: true

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                onClicked: mouse => {
                                    const item = trayIcon.modelData
                                    if (mouse.button === Qt.MiddleButton) {
                                        item.secondaryActivate()
                                    } else if (item.hasMenu && (mouse.button === Qt.RightButton || item.onlyMenu)) {
                                        const p = trayIcon.mapToItem(null, mouse.x, mouse.y)
                                        item.display(root, p.x, p.y)
                                    } else {
                                        item.activate()
                                    }
                                }
                                onWheel: wheel => trayIcon.modelData.scroll(wheel.angleDelta.y, false)
                            }
                        }
                    }
                }
            }

            BarModule {
                icon: ""
                iconFont: "feather"
                text: root.tempText
                topLeftRadius: 8
                bottomLeftRadius: 8
            }

            BarModule {
                icon: ""
                text: root.cpuText
            }

            BarModule {
                icon: ""
                iconFont: "feather"
                text: root.memText
            }

            BarModule {
                text: root.netText
            }

            BarModule {
                readonly property bool muted: root.sink?.audio?.muted ?? false
                readonly property int volume: Math.round((root.sink?.audio?.volume ?? 0) * 100)

                visible: root.sink !== null
                icon: muted ? "" : volume < 34 ? "" : volume < 67 ? "" : ""
                iconFont: "feather"
                iconColor: muted ? root.urgent : root.accent
                text: muted ? "Muted" : volume + "%"
                onClicked: Quickshell.execDetached(["pavucontrol"])
                onScrolled: wheel => {
                    const audio = root.sink?.audio
                    if (!audio) return
                    const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                    audio.volume = Math.max(0, Math.min(1, audio.volume + step))
                }
            }
        }
    }
}

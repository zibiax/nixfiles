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
    property string gpuText: ""
    property string memText: ""
    property string tempText: ""
    property string netText: ""
    property string kernelText: ""
    // check-updates.sh output, see the script for the fields
    property var updates: null
    readonly property int updateCount: updates ? updates.inputs.length + (updates.rebuild ? 1 : 0) : 0
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

    // ── CPU: busy share of all threads since the previous poll ───────
    property var cpuPrev: null
    Process {
        id: cpuProc
        command: ["head", "-n1", "/proc/stat"]
        stdout: SplitParser {
            onRead: line => {
                // cpu user nice system idle iowait irq softirq steal (guest is already in user)
                const f = line.trim().split(/\s+/).slice(1, 9).map(Number)
                const total = f.reduce((a, b) => a + b, 0)
                const idle = f[3] + f[4]
                const prev = root.cpuPrev
                root.cpuPrev = { total, idle }
                if (prev && total > prev.total)
                    root.cpuText = Math.round(100 * (1 - (idle - prev.idle) / (total - prev.total))) + "%"
            }
        }
    }

    // ── GPU: temperature and utilisation; hidden without nvidia-smi ──
    Process {
        id: gpuProc
        command: ["nvidia-smi", "--query-gpu=temperature.gpu,utilization.gpu", "--format=csv,noheader,nounits"]
        stdout: SplitParser {
            onRead: line => {
                const [temp, util] = line.split(",").map(v => v.trim())
                root.gpuText = temp + "°C " + util + "%"
            }
        }
        onExited: code => { if (code !== 0) root.gpuText = "" }
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
            root.poll(gpuProc)
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

    // ── Updates: GitHub's flake.lock (bumped by CI) vs the checkout ───
    Process {
        id: pkgProc
        command: ["sh", "-c", "$HOME/.local/scripts/check-updates.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const u = JSON.parse(text)
                    root.updates = u.error ? null : Object.assign(u, { checked: Qt.formatTime(new Date(), "HH:mm") })
                } catch (e) {
                    root.updates = null
                }
            }
        }
    }
    Timer {
        interval: 1800000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.poll(pkgProc)
    }

    // ── Volume ───────────────────────────────────────────────────────
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    // ── Update window, opened from the updates pill ──────────────────
    PopupWindow {
        id: updatesPopup
        visible: false
        anchor.item: updatesModule
        anchor.rect.y: updatesModule.height + 6
        implicitWidth: 340
        implicitHeight: updatesCol.implicitHeight + 28
        color: "transparent"

        // Click outside to close.
        HyprlandFocusGrab {
            windows: [updatesPopup]
            active: updatesPopup.visible
            onCleared: updatesPopup.visible = false
        }

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: root.moduleBg
            border.color: root.accent
            border.width: 1

            Column {
                id: updatesCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 14
                }
                spacing: 8

                component PopupText: Text {
                    width: parent.width
                    wrapMode: Text.Wrap
                    color: "#c0caf5"
                    font.family: "SpaceMono Nerd Font"
                    font.pixelSize: 13
                }

                PopupText {
                    text: "System updates"
                    color: root.accent
                    font.weight: Font.Black
                    font.pixelSize: 15
                }

                PopupText {
                    visible: root.updates === null
                    text: pkgProc.running ? "Checking…" : "Couldn't check for updates."
                }

                PopupText {
                    visible: root.updates?.offline ?? false
                    text: "GitHub unreachable, showing local state only."
                    color: root.urgent
                }

                PopupText {
                    visible: root.updates !== null && root.updateCount === 0 && root.updates.behind === 0
                    text: "Everything is up to date."
                }

                PopupText {
                    visible: (root.updates?.behind ?? 0) > 0
                    text: root.updates ? root.updates.behind + " new commit" + (root.updates.behind === 1 ? "" : "s") + " on GitHub" : ""
                }

                Repeater {
                    model: root.updates?.inputs ?? []
                    PopupText {
                        required property var modelData
                        text: "<font color=\"#7aa2f7\">" + modelData.name + "</font>  " + modelData.from + " → " + modelData.to
                        textFormat: Text.StyledText
                    }
                }

                PopupText {
                    visible: root.updates?.rebuild ?? false
                    text: "Rebuild pending: the running system is older than flake.lock."
                    color: root.urgent
                }

                PopupText {
                    visible: root.updates !== null
                    text: "Checked " + (root.updates?.checked ?? "")
                    color: "#565f89"
                    font.pixelSize: 11
                }

                Row {
                    spacing: 8

                    component PopupButton: Rectangle {
                        id: button
                        property string label
                        signal clicked
                        implicitWidth: buttonText.implicitWidth + 24
                        implicitHeight: 28
                        radius: 14
                        color: buttonMouse.containsMouse ? root.accent : "#24283b"
                        Text {
                            id: buttonText
                            anchors.centerIn: parent
                            text: button.label
                            color: buttonMouse.containsMouse ? root.moduleBg : "#c0caf5"
                            font.family: "SpaceMono Nerd Font"
                            font.weight: Font.Black
                            font.pixelSize: 13
                        }
                        MouseArea {
                            id: buttonMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: button.clicked()
                        }
                    }

                    PopupButton {
                        label: pkgProc.running ? "Checking…" : "Check now"
                        onClicked: root.poll(pkgProc)
                    }

                    // `upgrade` (home/linux/desktop.nix) pulls CI's flake.lock and rebuilds.
                    PopupButton {
                        label: "Upgrade"
                        onClicked: {
                            updatesPopup.visible = false
                            Quickshell.execDetached(["ghostty", "-e", "zsh", "-ic",
                                "upgrade; echo; read -k1 '?Done, press any key to close'"])
                        }
                    }
                }
            }
        }
    }

    // ── Layout ───────────────────────────────────────────────────────
    Item {
        anchors.fill: parent

        // LEFT: ws1..9, clock, kernel, updates
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
                iconFont: "feather"
                text: Qt.formatDateTime(clock.date, root.clockAlt ? "dd-MM-yyyy" : "HH:mm:ss")
                onClicked: root.clockAlt = !root.clockAlt
                topRightRadius: 8
                bottomRightRadius: 8
            }

            BarModule {
                icon: ""
                text: root.kernelText
                radius: 16
                Layout.leftMargin: 16
            }

            BarModule {
                id: updatesModule
                icon: ""
                iconColor: root.updateCount > 0 ? root.urgent : root.accent
                text: root.updates === null ? ""
                    : root.updateCount > 0 ? root.updateCount + (root.updateCount === 1 ? " update" : " updates")
                    : root.updates.behind > 0 ? root.updates.behind + " new" : "Up to date"
                onClicked: {
                    updatesPopup.visible = !updatesPopup.visible
                    if (updatesPopup.visible) root.poll(pkgProc)
                }
                radius: 16
                Layout.leftMargin: 16
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

        // RIGHT: tray, cpu, gpu, memory, network, pulseaudio
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
                icon: ""
                iconFont: "feather"
                text: root.tempText && root.cpuText ? root.tempText + " " + root.cpuText : root.tempText + root.cpuText
                topLeftRadius: 8
                bottomLeftRadius: 8
            }

            BarModule {
                icon: "󰢮"
                text: root.gpuText
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

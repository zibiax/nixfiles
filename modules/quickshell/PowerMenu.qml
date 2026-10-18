import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

// Port of rofi/powermenu (powermenu.sh + powermenu.rasi).
// Toggle: qs ipc call powermenu toggle
PanelWindow {
    id: root

    visible: false
    // Full-screen and transparent so a click outside closes it (click-to-exit).
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    // Stay clear of the bar, so centring matches rofi's (work area, not screen).
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-powermenu"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // tokyonight.rasi
    readonly property color background: "#15161e"
    readonly property color backgroundAlt: "#1a1b26"
    readonly property color foreground: "#c0caf5"
    readonly property color selected: "#7aa2f7"

    // feather glyphs from powermenu.sh. Lock skips the confirmation, as before;
    // hyprlock replaces betterlockscreen, which is X11-only.
    readonly property var actions: [
        { icon: "", command: ["systemctl", "poweroff"], confirm: true },
        { icon: "", command: ["systemctl", "reboot"], confirm: true },
        { icon: "", command: ["hyprlock"], confirm: false },
        { icon: "", command: ["systemctl", "suspend"], confirm: true },
        { icon: "", command: null, confirm: true } // logout
    ]
    readonly property var answers: ["", ""] // yes, no

    property int current: 0
    property int pending: -1 // action waiting for "Are you Sure?"

    function toggle() {
        if (!visible) {
            screen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
            current = 0
            pending = -1
        }
        visible = !visible
    }
    onVisibleChanged: if (visible) keys.forceActiveFocus()

    function run(index) {
        const action = actions[index]
        visible = false
        if (action.command)
            Quickshell.execDetached(action.command)
        else
            Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.exit()" : "exit")
    }

    function choose(index) {
        if (pending < 0) {
            if (actions[index].confirm) {
                pending = index
                current = 0
            } else {
                run(index)
            }
        } else if (index === 0) {
            run(pending)
        } else {
            visible = false // "no" exits, like the script
        }
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true

        readonly property int count: root.pending < 0 ? root.actions.length : root.answers.length

        Keys.onEscapePressed: root.visible = false
        Keys.onReturnPressed: root.choose(root.current)
        Keys.onEnterPressed: root.choose(root.current)
        Keys.onDownPressed: root.current = (root.current + 1) % count
        Keys.onRightPressed: root.current = (root.current + 1) % count
        Keys.onTabPressed: root.current = (root.current + 1) % count
        Keys.onUpPressed: root.current = (root.current - 1 + count) % count
        Keys.onLeftPressed: root.current = (root.current - 1 + count) % count
        Keys.onBacktabPressed: root.current = (root.current - 1 + count) % count

        MouseArea {
            anchors.fill: parent
            onClicked: root.visible = false
        }
    }

    // element { padding: 20px 0; background: @background-alt; }
    // element selected.normal { background: @selected; text-color: @background; }
    // element-text { font: "feather bold 24"; }
    component Element: Rectangle {
        id: element
        required property string glyph
        required property int index

        readonly property bool isCurrent: root.current === index

        implicitHeight: glyphText.implicitHeight + 40
        color: isCurrent ? root.selected : root.backgroundAlt

        Text {
            id: glyphText
            anchors.centerIn: parent
            text: element.glyph
            color: element.isCurrent ? root.background : root.foreground
            font.family: "feather"
            font.bold: true
            font.pointSize: 24
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.current = element.index
            onClicked: root.choose(element.index)
        }
    }

    // window { location: west; width: 115px; x-offset: 15px; }
    // mainbox { padding: 15px; }  listview { lines: 5; spacing: 15px; }
    Rectangle {
        visible: root.pending < 0
        x: 15
        anchors.verticalCenter: parent.verticalCenter
        width: 115
        height: menu.implicitHeight + 30
        color: root.background

        MouseArea { anchors.fill: parent } // swallow clicks inside

        Column {
            id: menu
            x: 15
            y: 15
            width: parent.width - 30
            spacing: 15

            Repeater {
                model: root.actions

                Element {
                    required property var modelData
                    width: menu.width
                    glyph: modelData.icon
                }
            }
        }
    }

    // Confirmation: centred, 350px, message + two columns.
    Rectangle {
        visible: root.pending >= 0
        anchors.centerIn: parent
        width: 350
        height: confirm.implicitHeight + 30
        color: root.background

        MouseArea { anchors.fill: parent } // swallow clicks inside

        Column {
            id: confirm
            x: 15
            y: 15
            width: parent.width - 30
            spacing: 15

            // message { padding: 12px; background: @background-alt; }
            Rectangle {
                width: parent.width
                height: message.implicitHeight + 24
                color: root.backgroundAlt

                Text {
                    id: message
                    anchors.centerIn: parent
                    text: "Are you Sure?"
                    color: root.foreground
                    font.family: "SpaceMono Nerd Font"
                    font.pointSize: 10
                }
            }

            Row {
                width: parent.width
                spacing: 15

                Repeater {
                    model: root.answers

                    Element {
                        required property var modelData
                        width: (confirm.width - 15) / 2
                        glyph: modelData
                    }
                }
            }
        }
    }
}

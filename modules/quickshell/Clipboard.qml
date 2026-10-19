import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Port of scripts/local/rofi-cliphist.sh: cliphist history, same look as the launcher.
// Toggle: qs ipc call clipboard toggle
PanelWindow {
    id: root

    visible: false
    // Full-screen and transparent so a click outside the box closes it,
    // like rofi's click-to-exit.
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
    WlrLayershell.namespace: "quickshell-clipboard"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // tokyonight.rasi
    readonly property color background: "#15161e"
    readonly property color foreground: "#c0caf5"
    readonly property color accent: "#7aa2f7"
    readonly property color selected: "#7aa2f7"
    readonly property string font: "SpaceMono Nerd Font"

    function toggle() {
        if (!visible) {
            screen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
            search.text = ""
            list.currentIndex = 0
            cliphist.running = true
        }
        visible = !visible
    }
    onVisibleChanged: if (visible) search.forceActiveFocus()

    // `cliphist list`: "<id>\t<preview>" per line, newest first.
    Process {
        id: cliphist
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            id: listing
        }
    }

    // rofi's default "normal" matching: every word must appear somewhere.
    readonly property var entries: {
        const words = search.text.toLowerCase().split(/\s+/).filter(w => w.length > 0)
        return listing.text.split("\n")
            .filter(line => line.includes("\t"))
            .map(line => ({ line: line, preview: line.slice(line.indexOf("\t") + 1) }))
            .filter(e => words.every(w => e.preview.toLowerCase().includes(w)))
    }

    function paste(index) {
        if (index < 0 || index >= entries.length) return
        // Same pipeline as the rofi script; the line goes in as $1, not into the script.
        Quickshell.execDetached(["sh", "-c", 'printf "%s\\n" "$1" | cliphist decode | wl-copy', "sh", entries[index].line])
        visible = false
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    // window { width: 550px; height: 360px; }
    Rectangle {
        anchors.centerIn: parent
        width: 550
        height: 360
        color: root.background
        clip: true

        MouseArea { anchors.fill: parent } // swallow clicks inside

        // inputbar { padding: 5px; children: [prompt, entry]; }
        Item {
            id: inputbar
            x: 5
            y: 5
            width: parent.width - 10
            height: prompt.y + prompt.height

            // prompt { margin: 20px 0 0 20px; padding: 6px; border-radius: 4px; }
            Rectangle {
                id: prompt
                x: 20
                y: 20
                width: promptText.implicitWidth + 12
                height: promptText.implicitHeight + 12
                radius: 4
                color: root.accent

                Text {
                    id: promptText
                    anchors.centerIn: parent
                    text: " 󰅌  Clipboard "
                    color: root.background
                    font.family: root.font
                    font.pointSize: 13
                }
            }

            // entry { margin: 20px 0 0 10px; padding: 6px; }
            TextInput {
                id: search
                x: prompt.x + prompt.width + 10 + 6
                anchors.verticalCenter: prompt.verticalCenter
                width: inputbar.width - x - 6
                color: root.foreground
                selectionColor: root.accent
                font.family: root.font
                font.pointSize: 13
                focus: root.visible
                clip: true

                Keys.onEscapePressed: root.visible = false
                Keys.onReturnPressed: root.paste(list.currentIndex)
                Keys.onEnterPressed: root.paste(list.currentIndex)
                Keys.onDownPressed: list.currentIndex = Math.min(list.currentIndex + 1, list.count - 1)
                Keys.onUpPressed: list.currentIndex = Math.max(list.currentIndex - 1, 0)
                Keys.onTabPressed: list.currentIndex = (list.currentIndex + 1) % Math.max(list.count, 1)
                Keys.onBacktabPressed: list.currentIndex = (list.currentIndex - 1 + list.count) % Math.max(list.count, 1)
                onTextChanged: list.currentIndex = 0
            }
        }

        // listview { margin: 10px 0 0 20px; padding: 6px 0 0; } -- one column,
        // clipboard lines are too long for the launcher's two.
        ListView {
            id: list
            anchors {
                top: inputbar.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                topMargin: 5 + 10 + 6 + 2 // inputbar padding + listview margin/padding
                leftMargin: 20
                rightMargin: 20
            }
            model: root.entries
            interactive: true
            highlightFollowsCurrentItem: false
            boundsBehavior: Flickable.StopAtBounds

            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            // element { padding: 4px; }
            // element selected { background-color: @background; text-color: @selected; }
            delegate: Item {
                id: entry
                required property var modelData
                required property int index
                readonly property bool isCurrent: ListView.isCurrentItem

                width: list.width
                height: 36

                Text {
                    anchors {
                        fill: parent
                        margins: 4
                    }
                    verticalAlignment: Text.AlignVCenter
                    text: entry.modelData.preview
                    textFormat: Text.PlainText
                    color: entry.isCurrent ? root.selected : root.foreground
                    font.family: root.font
                    font.pointSize: 13
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.paste(entry.index)
                }
            }
        }
    }
}

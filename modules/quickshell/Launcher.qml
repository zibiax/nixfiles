import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Port of rofi/config.rasi (drun) with the tokyonight rofi theme.
// Toggle: qs ipc call launcher toggle
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
    WlrLayershell.namespace: "quickshell-launcher"
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
        }
        visible = !visible
    }
    onVisibleChanged: if (visible) search.forceActiveFocus()

    // rofi's drun history, shared with rofi: "<count> <id>.desktop" per line.
    FileView {
        id: historyFile
        path: Quickshell.env("HOME") + "/.cache/rofi3.druncache"
        watchChanges: true
        onFileChanged: reload()
    }
    // The file is kept sorted by count; equal counts keep their order.
    readonly property var history: {
        const ids = []
        const counts = {}
        for (const line of historyFile.text().split("\n")) {
            const m = line.match(/^(\d+) (.+)\.desktop$/)
            if (m) {
                ids.push(m[2])
                counts[m[2]] = Number(m[1])
            }
        }
        return { ids: ids, counts: counts }
    }
    function recordLaunch(entry) {
        const counts = Object.assign({}, history.counts)
        const ids = history.ids.includes(entry.id) ? history.ids.slice() : history.ids.concat(entry.id)
        counts[entry.id] = (counts[entry.id] || 0) + 1
        ids.sort((a, b) => counts[b] - counts[a])
        historyFile.setText(ids.map(id => counts[id] + " " + id + ".desktop").join("\n") + "\n")
    }

    // rofi's default "normal" matching: every word must appear somewhere.
    // History order first, then alphabetical, like rofi with history on.
    readonly property var apps: {
        const words = search.text.toLowerCase().split(/\s+/).filter(w => w.length > 0)
        const rank = id => {
            const i = history.ids.indexOf(id)
            return i < 0 ? Infinity : i
        }
        return DesktopEntries.applications.values
            .filter(a => !a.noDisplay)
            .filter(a => {
                const hay = [a.name, a.genericName, ...(a.keywords || [])].join(" ").toLowerCase()
                return words.every(w => hay.includes(w))
            })
            .sort((a, b) => rank(a.id) - rank(b.id) || a.name.localeCompare(b.name))
    }

    function launch(index) {
        if (index < 0 || index >= apps.length) return
        const entry = apps[index]
        // execute() ignores Terminal=true; rofi runs those in its terminal.
        if (entry.runInTerminal)
            Quickshell.execDetached({
                command: ["kitty", "-e"].concat(Array.from(entry.command)),
                workingDirectory: entry.workingDirectory
            })
        else
            entry.execute()
        recordLaunch(entry)
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
                    text: "   Apps "
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
                Keys.onReturnPressed: root.launch(list.currentIndex)
                Keys.onEnterPressed: root.launch(list.currentIndex)
                Keys.onDownPressed: list.currentIndex = Math.min(list.currentIndex + 1, list.count - 1)
                Keys.onUpPressed: list.currentIndex = Math.max(list.currentIndex - 1, 0)
                Keys.onTabPressed: list.currentIndex = (list.currentIndex + 1) % Math.max(list.count, 1)
                Keys.onBacktabPressed: list.currentIndex = (list.currentIndex - 1 + list.count) % Math.max(list.count, 1)
                onTextChanged: list.currentIndex = 0
            }
        }

        // listview { margin: 10px 0 0 20px; padding: 6px 0 0; columns: 2; }
        // rofi fills the first column top to bottom, then the second.
        GridView {
            id: list
            anchors {
                top: inputbar.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                topMargin: 5 + 10 + 6 + 2 // inputbar padding + listview margin/padding
                leftMargin: 20
            }
            model: root.apps
            cellWidth: width / 2
            cellHeight: 36
            flow: GridView.FlowTopToBottom
            interactive: true
            highlightFollowsCurrentItem: false
            boundsBehavior: Flickable.StopAtBounds

            onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

            // element { padding: 4px; } element-icon { size: 24px; }
            // element selected { background-color: @background; text-color: @selected; }
            delegate: Item {
                id: entry
                required property var modelData
                required property int index
                readonly property bool isCurrent: GridView.isCurrentItem

                width: list.cellWidth
                height: list.cellHeight

                Row {
                    anchors {
                        fill: parent
                        margins: 4
                    }
                    spacing: 1

                    Image {
                        width: 24
                        height: 24
                        anchors.verticalCenter: parent.verticalCenter
                        source: Quickshell.iconPath(entry.modelData.icon, "application-x-executable")
                        sourceSize: Qt.size(24, 24)
                        smooth: true
                    }

                    Text {
                        width: parent.width - 25
                        anchors.verticalCenter: parent.verticalCenter
                        text: entry.modelData.name
                        color: entry.isCurrent ? root.selected : root.foreground
                        font.family: root.font
                        font.pointSize: 13
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.launch(entry.index)
                }
            }
        }
    }
}

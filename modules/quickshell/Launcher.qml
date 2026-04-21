import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// App launcher – triggered via: qs ipc call launcher
// Hyprland bind: bind = SUPER, SPACE, exec, qs ipc call launcher
FloatingWindow {
    id: root

    // Centre on the primary screen
    x: screen ? screen.x + Math.round((screen.width  - width)  / 2) : 1445
    y: screen ? screen.y + Math.round((screen.height - height) / 2) : 530

    width:  550
    height: 400
    color:  "#1a1b26"

    onVisibleChanged: {
        if (visible) {
            searchInput.text = ""
            searchInput.forceActiveFocus()
        }
    }

    // ── Filtered app list ─────────────────────────────────────────────
    property var filteredApps: {
        var search = searchInput.text.toLowerCase().trim()
        var all = DesktopEntries.applications.values || []
        var visible = all.filter(a => !a.noDisplay)
        if (search.length === 0)
            return visible.sort((a, b) => a.name.localeCompare(b.name))
        return visible.filter(a => {
            var name     = a.name.toLowerCase()
            var generic  = (a.genericName || "").toLowerCase()
            var keywords = (a.keywords || []).join(" ").toLowerCase()
            return name.includes(search) ||
                   generic.includes(search) ||
                   keywords.includes(search)
        }).sort((a, b) => a.name.localeCompare(b.name))
    }

    // ── Global keys ───────────────────────────────────────────────────
    Keys.onEscapePressed: root.visible = false

    // ── UI ────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        // Search bar
        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: "#1e2030"
            radius: 6
            border.color: searchInput.activeFocus ? "#7aa2f7" : "#282a3a"
            border.width: 2

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 12
                    rightMargin: 12
                }
                spacing: 8

                Text {
                    text: "  Apps "
                    color: "#7aa2f7"
                    font.family: "SpaceMono Nerd Font"
                    font.pixelSize: 13
                    font.bold: true
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: "#c0caf5"
                    font.family: "SpaceMono Nerd Font"
                    font.pixelSize: 13
                    verticalAlignment: TextInput.AlignVCenter
                    focus: true
                    height: parent.height
                    clip: true

                    Keys.onDownPressed:  appList.currentIndex = Math.min(appList.currentIndex + 1, appList.count - 1)
                    Keys.onUpPressed:    appList.currentIndex = Math.max(appList.currentIndex - 1, 0)
                    Keys.onReturnPressed: {
                        if (appList.currentIndex >= 0 && appList.currentIndex < root.filteredApps.length) {
                            root.filteredApps[appList.currentIndex].execute()
                            root.visible = false
                        }
                    }
                }
            }
        }

        // App list
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ListView {
                id: appList
                model: root.filteredApps
                currentIndex: 0
                spacing: 2

                onModelChanged: currentIndex = 0

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width:  ListView.view.width
                    height: 44
                    color:  ListView.isCurrentItem ? "#1e2030" : "transparent"
                    radius: 4

                    RowLayout {
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                        spacing: 10

                        Image {
                            width:  24
                            height: 24
                            Layout.alignment: Qt.AlignVCenter
                            source: {
                                var icon = modelData.icon || ""
                                if (icon.length === 0) return ""
                                if (icon.startsWith("/") || icon.startsWith("file://"))
                                    return icon
                                return Quickshell.iconPath(icon) || ""
                            }
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }

                        Text {
                            Layout.fillWidth: true
                            text:  modelData.name
                            color: parent.parent.ListView.isCurrentItem ? "#7aa2f7" : "#c0caf5"
                            font.family:  "SpaceMono Nerd Font"
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.filteredApps[index].execute()
                            root.visible = false
                        }
                    }
                }
            }
        }
    }
}

import QtQuick

// One waybar module (style.css): blue icon + white text on a #160654 block,
// 3px vertical margin inside the 36px bar, 10px side padding. Hidden when
// the text is empty, like waybar does.
Rectangle {
    id: mod

    property string icon: ""
    // waybar's "SpaceMono Nerd Font, feather": SpaceMono covers some of the
    // icons, feather the rest. Qt's fallback doesn't reach feather, so
    // modules whose icon only feather has set iconFont: "feather".
    property string iconFont: "SpaceMono Nerd Font"
    property color iconColor: "#7aa2f7"
    property string text: ""
    property color textColor: "#ffffff"
    property int padding: 10

    signal clicked(var mouse)
    signal scrolled(var wheel)

    visible: text.length > 0
    implicitWidth: row.implicitWidth + 2 * padding
    implicitHeight: 30
    color: "#160654"

    Row {
        id: row
        anchors.centerIn: parent

        Text {
            visible: mod.icon.length > 0
            text: mod.icon + " "
            color: mod.iconColor
            font.family: mod.iconFont
            font.weight: Font.Black
            font.pixelSize: 14
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: mod.text
            color: mod.textColor
            font.family: "SpaceMono Nerd Font"
            font.weight: Font.Black
            font.pixelSize: 14
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => mod.clicked(mouse)
        onWheel: wheel => mod.scrolled(wheel)
    }
}

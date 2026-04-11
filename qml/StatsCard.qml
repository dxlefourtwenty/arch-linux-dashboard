import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property color  cFg: "white"
    property string cFont: "sans"
    property int    cFontSize: 16
    property real   infoFontSize: cFontSize * 1.1
    property int    rowGap: 24

    color: "transparent"

    property string osGlyph: SystemInfo.osName.indexOf("Arch Linux") !== -1 ? "󰣇" : "󰌽"
    property string deGlyph: SystemInfo.deName.indexOf("Hyprland") !== -1 ? "" : "󱂬"
    property string uptimeGlyph: "󰁫"

    Column {
        anchors.fill: parent
        spacing: root.rowGap

        Text {
            width: parent.width
            text: root.osGlyph + " : " + SystemInfo.osName
            color: root.cFg
            font.family: root.cFont
            font.pixelSize: root.infoFontSize
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.deGlyph + " : " + SystemInfo.deName
            color: root.cFg
            font.family: root.cFont
            font.pixelSize: root.infoFontSize
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.uptimeGlyph + " : up " + SystemInfo.uptimeText
            color: root.cFg
            font.family: root.cFont
            font.pixelSize: root.infoFontSize
            elide: Text.ElideRight
        }
    }
}

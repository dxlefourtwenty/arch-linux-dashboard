import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property color  cFg: "white"
    property string cFont: "sans"
    property int    cFontSize: 16
    property real   infoFontSize: cFontSize * 1.1
    property int    rowGap: 16
    property int    infoTopMargin: 0

    color: "transparent"

    property string osGlyph: SystemInfo.osName.indexOf("Arch Linux") !== -1 ? "󰣇" : "󰌽"
    property string deGlyph: SystemInfo.deName.indexOf("Hyprland") !== -1 ? "" : "󱂬"
    property string themeGlyph: ""
    property string uptimeGlyph: "󰁫"
    property string themeDisplayName: {
        const name = SystemInfo.themeName
        if (!name || name.length === 0) return name
        const normalizedName = name.replace(/-/g, " ").trim()
        if (normalizedName.length === 0) return normalizedName
        return normalizedName
            .split(/\s+/)
            .map(function(word) {
                return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
            })
            .join(" ")
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: root.infoTopMargin
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
            text: root.themeGlyph + " : " + root.themeDisplayName
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

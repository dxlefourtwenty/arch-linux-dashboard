import QtQuick
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root

    property color  cFg:          "white"
    property string cFont:        "sans"
    property int    cFontSize:    16
    property color  cBorder:      "#444444"
    property int    cBorderWidth: 2
    property int    bottomPad:    12
    property int    avatarSize:   78
    property int    avatarTopMargin: 1
    property int    avatarYOffset: 0
    property int    avatarBottomMargin: 0
    property int    avatarFallbackFontSize: 24
    property int    spacing: 8
    property real   hoverScale:   1.08
    property int    hoverAnimMs:  140

    color: "transparent"

    Column {
        anchors.centerIn: parent
        spacing: root.spacing

        Item {
            width: 1
            height: root.avatarTopMargin
        }

        Item {
            width: root.avatarSize
            height: root.avatarSize
            anchors.horizontalCenter: parent.horizontalCenter
            transformOrigin: Item.Center
            scale: avatarHover.hovered ? root.hoverScale : 1.0
            z: avatarHover.hovered ? 1 : 0
            Behavior on scale {
                NumberAnimation {
                    duration: root.hoverAnimMs
                    easing.type: Easing.OutCubic
                }
            }

            HoverHandler {
                id: avatarHover
            }

            Item {
                id: avatarCircle
                width: root.avatarSize
                height: root.avatarSize
                y: root.avatarYOffset

                Image {
                    id: avatarImage
                    anchors.fill: parent
                    source: AppConfig.profileImage.startsWith("file:")
                            ? AppConfig.profileImage
                            : "file://" + AppConfig.profileImage
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: avatarImage
                    visible: AppConfig.profileImage.toString().length > 0
                    maskSource: Rectangle {
                        width: avatarCircle.width
                        height: avatarCircle.height
                        radius: width / 2
                    }
                }
            }

            Rectangle {
                anchors.fill: avatarCircle
                radius: width / 2
                color: "transparent"
                border.width: root.cBorderWidth
                border.color: root.cBorder
            }

            Text {
                anchors.centerIn: avatarCircle
                text: "?"
                color: root.cFg
                font.family: root.cFont
                font.pixelSize: root.avatarFallbackFontSize
                visible: AppConfig.profileImage.toString().length === 0
            }
        }

        Item {
            width: 1
            height: root.avatarBottomMargin
        }

        Text {
            width: root.width
            text: AppConfig.username
            color: root.cFg
            font.family: root.cFont
            font.pixelSize: root.cFontSize
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAnywhere
            elide: Text.ElideRight
        }

        Item {
            width: 1
            height: root.bottomPad
        }
    }
}

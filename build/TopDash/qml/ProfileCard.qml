import QtQuick
import Qt5Compat.GraphicalEffects

// ProfileCard.qml

Rectangle {
    id: root

    property color  cFg:          "white"
    property string cFont:        "sans"
    property int    cFontSize:    16
    property color  cBorder:      "#444444"
    property int    cBorderWidth: 2
    property int    bottomPad:    24

    color: "transparent"

    Column {
        anchors.centerIn: parent
        spacing: 10

        Item {
            width: 96
            height: 96
            anchors.horizontalCenter: parent.horizontalCenter

            Item {
                id: avatarCircle
                width: 96
                height: 96
                y: -10

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

            // Border overlay on top so it isn't obscured by the image
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
                font.pixelSize: 28
                visible: AppConfig.profileImage.toString().length === 0
            }
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

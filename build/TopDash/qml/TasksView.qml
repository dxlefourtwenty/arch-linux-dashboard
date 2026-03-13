import QtQuick
import QtQuick.Layouts

Item {
    id: root
    clip: true

    property color  cFg:       "white"
    property color  cMuted:    "#888888"
    property string cFont:     "sans"
    property int    cFontSize: 16
    property string selectedDateKey: ""
    property int    taskIndent: 8
    property int    taskCharCutoff: 240
    property int    tasksPerPage: 3
    property int    pageIndex: 0
    property int    paginationTopGap: 0

    function load(dateKey) {
        selectedDateKey = dateKey
        reloadCurrent()
    }

    function totalPages() {
        if (allTasksModel.count === 0) return 0
        return Math.ceil(allTasksModel.count / Math.max(1, tasksPerPage))
    }

    function canGoPrev() {
        return pageIndex > 0
    }

    function canGoNext() {
        return pageIndex + 1 < totalPages()
    }

    function goPrevPage() {
        if (!canGoPrev()) return
        pageIndex -= 1
        rebuildPageModel()
    }

    function goNextPage() {
        if (!canGoNext()) return
        pageIndex += 1
        rebuildPageModel()
    }

    function rebuildPageModel() {
        pageTasksModel.clear()

        if (allTasksModel.count === 0) {
            pageIndex = 0
            return
        }

        const safePageSize = Math.max(1, tasksPerPage)
        const pages = Math.ceil(allTasksModel.count / safePageSize)
        if (pageIndex >= pages) pageIndex = pages - 1
        if (pageIndex < 0) pageIndex = 0

        const start = pageIndex * safePageSize
        const end = Math.min(allTasksModel.count, start + safePageSize)
        for (let i = start; i < end; i++) {
            pageTasksModel.append({ text: allTasksModel.get(i).text })
        }
    }

    function reloadCurrent() {
        allTasksModel.clear()
        pageTasksModel.clear()
        pageIndex = 0
        if (!selectedDateKey.length) return

        const tasks = AppConfig.tasksForDate(selectedDateKey)
        for (let i = 0; i < tasks.length; i++) {
            const raw = tasks[i].toString().trim()
            if (!raw.length) continue
            const cutoff = taskCharCutoff > 0 ? taskCharCutoff : 240
            const text = raw.length > cutoff ? raw.slice(0, cutoff) + "..." : raw
            allTasksModel.append({ text: text })
        }

        rebuildPageModel()
    }

    ListModel { id: allTasksModel }
    ListModel { id: pageTasksModel }

    Item {
        anchors.fill: parent

        ListView {
            id: taskList
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: pagerRow.visible
                ? (pagerRow.height + root.paginationTopGap)
                : 0
            model: pageTasksModel
            spacing: 8
            clip: true
            interactive: false

            delegate: Item {
                width: ListView.view.width
                height: Math.max(bullet.implicitHeight, line.implicitHeight)

                Text {
                    id: bullet
                    text: "•"
                    color: root.cFg
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize
                    anchors.left: parent.left
                    anchors.leftMargin: root.taskIndent
                }

                Text {
                    id: line
                    text: model.text
                    textFormat: Text.PlainText
                    color: root.cFg
                    font.family: root.cFont
                    font.pixelSize: root.cFontSize
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                    anchors.left: parent.left
                    anchors.leftMargin: root.taskIndent + 22
                    anchors.right: parent.right
                    anchors.rightMargin: root.taskIndent
                }
            }
        }

        Text {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: root.taskIndent
            visible: allTasksModel.count === 0
            text: "No tasks."
            color: root.cMuted
            font.family: root.cFont
            font.pixelSize: root.cFontSize
        }

        RowLayout {
            id: pagerRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            visible: root.canGoPrev() || root.canGoNext()

            Text {
                text: "< Prev"
                visible: root.canGoPrev()
                color: root.cFg
                font.family: root.cFont
                font.pixelSize: Math.max(12, root.cFontSize - 1)

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.goPrevPage()
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "Next >"
                visible: root.canGoNext()
                color: root.cFg
                font.family: root.cFont
                font.pixelSize: Math.max(12, root.cFontSize - 1)

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.goNextPage()
                }
            }
        }
    }
}

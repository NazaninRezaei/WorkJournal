import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Journal 1.0

ApplicationWindow {
    id: root
    width: 900
    height: 720
    visible: true
    title: "Journal"
    color: journal.theme.bg
    font.family: "Segoe UI"
    font.pixelSize: 14

    property bool showingTag: false
    property string activeTag: ""
    property var tagResults: []
    property int activeEntry: -1
    property string activeKind: ""
    property bool snippetFocused: false
    property int pendingFocusIndex: -1

    property real lastCheckAt: 0

    function addCheckAndFocus() {
        var now = Date.now()
        if (now - lastCheckAt < 80)
            return
        lastCheckAt = now
        showingTag = false
        journal.currentEntries.addCheck()
        pendingFocusIndex = journal.currentEntries.count - 1
        entriesView.positionViewAtEnd()
    }

    function addCodeSnippet() {
        if (!showingTag && activeKind === "note" && activeEntry >= 0)
            journal.currentEntries.addSnippet(activeEntry)
        else
            journal.currentEntries.addCodeNote()
        showingTag = false
    }

    function openDatePicker() {
        var parts = Qt.formatDate(journal.currentDate, "yyyy-MM-dd").split("-")
        datePicker.viewDate = new Date(Number(parts[0]), Number(parts[1]) - 1, 1)
        datePicker.open()
    }

    function openTag(tag) {
        activeTag = tag
        tagResults = journal.notesForTag(tag)
        showingTag = true
        searchPopup.visible = false
    }

    function swatchFor(id) {
        if (id === "midnight") return "#07090f"
        if (id === "forest") return "#173028"
        if (id === "plum") return "#24182e"
        if (id === "sand") return "#f3eee6"
        return "#16233a"
    }

    palette.window: journal.theme.bg
    palette.windowText: journal.theme.text
    palette.base: journal.theme.surface
    palette.text: journal.theme.text
    palette.button: journal.theme.button
    palette.buttonText: journal.theme.text
    palette.highlight: journal.theme.accent
    palette.highlightedText: journal.theme.accentInk
    palette.mid: journal.theme.line
    palette.placeholderText: journal.theme.faint

    component NavyButton: Button {
        id: navyButton
        implicitHeight: 36
        leftPadding: 14
        rightPadding: 14
        font.pixelSize: 13
        font.family: "Segoe UI"
        contentItem: Text {
            text: navyButton.text
            font: navyButton.font
            color: navyButton.enabled ? journal.theme.text : journal.theme.faint
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 8
            color: navyButton.down ? journal.theme.buttonDown : (navyButton.hovered ? journal.theme.buttonHover : journal.theme.button)
            border.color: navyButton.hovered ? journal.theme.accent : journal.theme.buttonLine
        }
    }

    JournalModel { id: journal }

    RowLayout {
        id: topbar
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 16 }
        spacing: 10

        Label {
            text: "Journal"
            font.pixelSize: 22
            font.bold: true
            color: journal.theme.text
        }

        TextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: "Search notes…"
            placeholderTextColor: journal.theme.faint
            color: journal.theme.text
            font.pixelSize: 14
            leftPadding: 14
            rightPadding: 14
            background: Rectangle {
                radius: 18
                color: journal.theme.surface
                border.color: searchField.activeFocus ? journal.theme.accent : journal.theme.line
            }
            onTextChanged: {
                searchPopup.results = journal.search(text)
                searchPopup.visible = text.length > 0 && searchPopup.results.length > 0
            }
        }

        NavyButton { text: "Today"; onClicked: journal.goToToday() }
        NavyButton { text: "Theme"; onClicked: themePopup.open() }
        NavyButton { text: "Keys"; onClicked: keysPopup.open() }
    }

    Rectangle {
        id: searchPopup
        property var results: []
        anchors { top: topbar.bottom; topMargin: 6; horizontalCenter: parent.horizontalCenter }
        width: parent.width - 220
        height: visible ? Math.min(results.length * 52 + 8, 268) : 0
        visible: false
        radius: 12
        color: journal.theme.surface
        border.color: journal.theme.line
        z: 10

        ListView {
            id: searchResults
            anchors { fill: parent; margins: 4 }
            clip: true
            model: searchPopup.results
            delegate: ItemDelegate {
                id: resultRow
                width: searchResults.width
                implicitHeight: 52
                contentItem: ColumnLayout {
                    spacing: 2
                    Label {
                        text: modelData.date
                        color: journal.theme.accent
                        font.pixelSize: 12
                        font.bold: true
                    }
                    Label {
                        text: modelData.text
                        font.pixelSize: 13
                        color: journal.theme.muted
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
                background: Rectangle {
                    color: resultRow.hovered ? journal.theme.buttonHover : "transparent"
                    radius: 8
                }
                onClicked: {
                    var entryDate = modelData ? modelData.date : ""
                    var parts = entryDate ? entryDate.split("-") : []
                    if (parts.length === 3)
                        journal.changeCurrentDate(Number(parts[0]), Number(parts[1]), Number(parts[2]))
                    searchField.text = ""
                    searchPopup.visible = false
                }
            }
        }
    }

    Rectangle {
        id: safetyBar
        anchors { top: topbar.bottom; topMargin: 10; left: parent.left; right: parent.right; margins: 16 }
        height: 40
        radius: 10
        color: journal.theme.surface
        border.color: journal.theme.line

        RowLayout {
            anchors { fill: parent; leftMargin: 14; rightMargin: 8; topMargin: 4; bottomMargin: 4 }
            spacing: 10
            Label {
                text: journal.storageDir
                color: journal.theme.muted
                font.pixelSize: 12
                Layout.fillWidth: true
                elide: Text.ElideMiddle
            }
            NavyButton {
                text: "Choose folder"
                onClicked: folderDialog.open()
            }
        }
    }

    Rectangle {
        id: book
        anchors {
            top: safetyBar.bottom; topMargin: 12
            left: parent.left; right: parent.right
            bottom: pager.top
            margins: 16
        }
        color: journal.theme.book
        border.color: journal.theme.line
        radius: 16

        ColumnLayout {
            anchors { fill: parent; margins: 20 }
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Label {
                        text: journal.currentDate.toLocaleString(Qt.locale("en_US"), "dddd, d MMMM yyyy")
                        color: journal.theme.text
                        font.pixelSize: 18
                        font.bold: true
                        font.family: "Segoe UI"
                        elide: Text.ElideRight
                    }
                    Label {
                        text: "·"
                        color: journal.theme.accent
                        font.pixelSize: 18
                    }
                    Label {
                        text: journal.currentShamsiDisplay
                        color: journal.theme.text
                        font.pixelSize: 16
                        font.family: "Segoe UI"
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                NavyButton {
                    text: "Pick date"
                    onClicked: root.openDatePicker()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                implicitHeight: 1
                color: journal.theme.line
            }

            RowLayout {
                Layout.fillWidth: true
                visible: showingTag
                spacing: 10
                NavyButton {
                    text: "‹  Back"
                    onClicked: showingTag = false
                }
                Label {
                    text: "#" + activeTag
                    color: journal.theme.accent
                    font.pixelSize: 20
                    font.bold: true
                    Layout.fillWidth: true
                }
            }

            ListView {
                id: tagView
                Layout.fillWidth: true
                Layout.fillHeight: showingTag && tagResults.length > 0
                visible: showingTag && tagResults.length > 0
                model: tagResults
                spacing: 8
                clip: true
                delegate: Rectangle {
                    width: tagView.width
                    implicitHeight: 64
                    radius: 10
                    color: tagHover.containsMouse ? journal.theme.buttonHover : journal.theme.card
                    border.color: journal.theme.line
                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        spacing: 12
                        Label {
                            text: modelData.date
                            color: journal.theme.accent
                            font.pixelSize: 13
                            font.bold: true
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label {
                                text: modelData.title && modelData.title.length > 0 ? modelData.title : (modelData.text || "Untitled")
                                color: journal.theme.text
                                font.pixelSize: 15
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Label {
                                text: modelData.shamsi + (modelData.text ? "   ·   " + modelData.text : "")
                                color: journal.theme.muted
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                    }
                    MouseArea {
                        id: tagHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var parts = modelData.date ? modelData.date.split("-") : []
                            if (parts.length === 3)
                                journal.changeCurrentDate(Number(parts[0]), Number(parts[1]), Number(parts[2]))
                            showingTag = false
                        }
                    }
                }
            }

            Label {
                visible: showingTag && tagResults.length === 0
                text: "No notes use this hashtag yet."
                color: journal.theme.muted
            }

            ListView {
                id: entriesView
                Layout.fillWidth: true
                Layout.fillHeight: !showingTag
                visible: !showingTag
                model: journal.currentEntries
                spacing: 10
                clip: true

                delegate: EntryDelegate {
                    width: entriesView.width
                    entryIndex: index
                    entryId: model.id
                    entryKind: model.kind || "check"
                    entryTitle: model.title || ""
                    entryText: model.text
                    entryDone: model.done
                    entryTags: model.tags || []
                    entrySnippets: model.snippets || []
                    entryImages: model.images
                    tagCatalog: journal.tagCatalog
                    theme: journal.theme
                    entryModel: journal.currentEntries
                    pendingFocusIndex: root.pendingFocusIndex
                    onFocusConsumed: root.pendingFocusIndex = -1
                    onNewCheckRequested: root.addCheckAndFocus()
                    onSnippetFocused: function(active) { root.snippetFocused = active }
                    onTagActivated: function(tag) { root.openTag(tag) }
                    onEntryFocused: function(index, kind) {
                        root.activeEntry = index
                        root.activeKind = kind
                    }
                    onImagePreviewRequested: function(source) {
                        imagePreview.imageSource = source
                        imagePreview.open()
                    }
                    onCopyToTodayRequested: function(index) { journal.copyEntryToToday(index) }
                }
            }

            RowLayout {
                visible: !showingTag
                spacing: 8
                NavyButton {
                    text: "Add checkbox"
                    onClicked: root.addCheckAndFocus()
                }
                NavyButton {
                    text: "Add note"
                    onClicked: journal.currentEntries.addNote()
                }
                NavyButton {
                    text: "Add code"
                    onClicked: {
                        showingTag = false
                        journal.currentEntries.addCodeNote()
                    }
                }
            }
        }
    }

    RowLayout {
        id: pager
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 16 }
        height: 40

        NavyButton {
            text: "‹  Prev day"
            onClicked: journal.prevPage()
        }

        Item { Layout.fillWidth: true }

        Label {
            text: "Page " + (journal.currentIndex + 1) + " of " + journal.pageCount
            color: journal.theme.muted
            font.pixelSize: 13
        }

        Item { Layout.fillWidth: true }

        NavyButton {
            text: "Next day  ›"
            onClicked: journal.nextPage()
        }
    }

    DatePicker {
        id: datePicker
        theme: journal.theme
        onPicked: function(year, month, day) {
            journal.changeCurrentDate(year, month, day)
        }
    }

    Popup {
        id: imagePreview
        modal: true
        focus: true
        parent: Overlay.overlay
        anchors.centerIn: parent
        padding: 16
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: Math.min(parent ? parent.width - 80 : 760, 920)
        height: Math.min(parent ? parent.height - 80 : 560, 700)
        property string imageSource: ""
        background: Rectangle {
            color: journal.theme.surface
            radius: 16
            border.color: journal.theme.line
        }
        contentItem: ColumnLayout {
            spacing: 10
            Image {
                Layout.fillWidth: true
                Layout.fillHeight: true
                source: imagePreview.imageSource
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
            Rectangle {
                Layout.alignment: Qt.AlignRight
                implicitWidth: imageCloseLabel.implicitWidth + 22
                implicitHeight: 32
                radius: 8
                color: imageCloseHover.containsMouse ? journal.theme.buttonHover : journal.theme.chip
                Text {
                    id: imageCloseLabel
                    anchors.centerIn: parent
                    text: "Close"
                    color: journal.theme.text
                    font.pixelSize: 13
                }
                MouseArea {
                    id: imageCloseHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: imagePreview.close()
                }
            }
        }
    }

    Popup {
        id: themePopup
        modal: true
        focus: true
        parent: Overlay.overlay
        anchors.centerIn: parent
        padding: 16
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle {
            color: journal.theme.surface
            radius: 14
            border.color: journal.theme.line
        }
        contentItem: Column {
            spacing: 8

            Label {
                text: "Theme"
                color: journal.theme.text
                font.pixelSize: 16
                font.bold: true
            }
            Repeater {
                model: [
                    { id: "navy", label: "Navy" },
                    { id: "midnight", label: "Midnight" },
                    { id: "forest", label: "Forest" },
                    { id: "plum", label: "Plum" },
                    { id: "sand", label: "Sand" }
                ]
                delegate: Rectangle {
                    width: 240
                    height: 40
                    radius: 8
                    color: modelData.id === journal.themeName ? journal.theme.chip : "transparent"
                    border.color: journal.theme.line
                    Row {
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        spacing: 10
                        Rectangle {
                            width: 18
                            height: 18
                            radius: 4
                            color: root.swatchFor(modelData.id)
                            border.color: journal.theme.line
                        }
                        Text {
                            text: modelData.label
                            color: journal.theme.text
                            font.pixelSize: 14
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            journal.themeName = modelData.id
                            themePopup.close()
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: keysPopup
        modal: true
        focus: true
        parent: Overlay.overlay
        anchors.centerIn: parent
        padding: 18
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle {
            color: journal.theme.surface
            radius: 14
            border.color: journal.theme.line
        }
        contentItem: Column {
            spacing: 8
            Label {
                text: "Shortcuts"
                color: journal.theme.text
                font.pixelSize: 16
                font.bold: true
            }
            Repeater {
                model: [
                    ["Ctrl+F", "Search"],
                    ["Ctrl+T", "Today"],
                    ["Alt+Left", "Previous day"],
                    ["Alt+Right", "Next day"],
                    ["Ctrl+G", "Pick a date"],
                    ["Ctrl+Shift+T", "Choose a theme"],
                    ["Ctrl+N", "Add a note"],
                    ["Shift+Enter", "Add a checkbox"],
                    ["Ctrl+Shift+K", "Add a code snippet"],
                    ["Ctrl+O", "Choose the save folder"],
                    ["Esc", "Leave a hashtag page"],
                    ["F1", "Show this list"]
                ]
                delegate: Row {
                    width: 360
                    spacing: 12
                    Label {
                        width: 130
                        text: modelData[0]
                        color: journal.theme.accent
                        font.family: "Consolas"
                        font.pixelSize: 13
                    }
                    Label {
                        text: modelData[1]
                        color: journal.theme.text
                        font.pixelSize: 13
                    }
                }
            }
        }
    }

    Shortcut { sequence: "Ctrl+F"; onActivated: { searchField.forceActiveFocus(); searchField.selectAll() } }
    Shortcut { sequence: "Ctrl+T"; onActivated: journal.goToToday() }
    Shortcut { sequence: "Alt+Left"; onActivated: journal.prevPage() }
    Shortcut { sequence: "Alt+Right"; onActivated: journal.nextPage() }
    Shortcut { sequence: "Ctrl+G"; onActivated: root.openDatePicker() }
    Shortcut { sequence: "Ctrl+Shift+T"; onActivated: themePopup.open() }
    Shortcut {
        sequence: "Ctrl+N"
        onActivated: { root.showingTag = false; journal.currentEntries.addNote() }
    }
    Shortcut {
        sequence: "Shift+Return"
        enabled: !snippetFocused
        onActivated: root.addCheckAndFocus()
    }
    Shortcut {
        sequence: "Shift+Enter"
        enabled: !snippetFocused
        onActivated: root.addCheckAndFocus()
    }
    Shortcut { sequence: "Ctrl+Shift+K"; onActivated: root.addCodeSnippet() }
    Shortcut { sequence: "Ctrl+O"; onActivated: folderDialog.open() }
    Shortcut { sequence: "F1"; onActivated: keysPopup.open() }
    Shortcut {
        sequence: "Escape"
        enabled: showingTag && !imagePreview.opened && !themePopup.opened && !keysPopup.opened && !datePicker.opened
        onActivated: showingTag = false
    }

    Connections {
        target: journal
        function onCurrentIndexChanged() {
            root.activeEntry = -1
            root.activeKind = ""
            root.snippetFocused = false
        }
    }

    FolderDialog {
        id: folderDialog
        title: "Choose storage folder"
        onAccepted: {
            var path = folderDialog.selectedFolder.toString()
            if (path.indexOf("file:///") === 0) path = path.substring(8)
            else if (path.indexOf("file://") === 0) path = path.substring(7)
            journal.storageDir = decodeURIComponent(path)
        }
    }
}

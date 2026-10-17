import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: root
    property int entryIndex
    property string entryId
    property string entryKind: "check"
    property string entryTitle
    property string entryText
    property bool entryDone
    property var entryTags: []
    property var entrySnippets: []
    property var entryImages: []
    property var tagCatalog: []
    property var entryModel
    property var theme: ({
        card: "#16233a", line: "#2a4060", text: "#e8eef8", muted: "#8ea0bd",
        faint: "#6d82a3", accent: "#7eb0ff", accentInk: "#0b1220", chip: "#1c3358",
        danger: "#f0b4c0", buttonHover: "#24385a", bg: "#0b1220", surface: "#121c30"
    })

    signal tagActivated(string tag)
    signal imagePreviewRequested(string source)
    signal copyToTodayRequested(int index)
    signal entryFocused(int index, string kind)
    signal snippetFocused(bool active)
    signal newCheckRequested()
    signal focusConsumed()

    property int pendingFocusIndex: -1

    function focusNewCheck() {
        if (pendingFocusIndex !== entryIndex || isNote)
            return
        Qt.callLater(function() {
            if (pendingFocusIndex !== entryIndex || isNote)
                return
            textArea.forceActiveFocus()
            focusConsumed()
        })
    }

    readonly property bool isNote: entryKind === "note"

    function hasTag(name) {
        var want = String(name).toLowerCase()
        for (var i = 0; i < entryTags.length; ++i) {
            if (String(entryTags[i]).toLowerCase() === want)
                return true
        }
        return false
    }

    function commitTag() {
        if (newTag.text.trim().length === 0)
            return
        entryModel.addTag(entryIndex, newTag.text)
        newTag.text = ""
    }

    function noteFocus() {
        entryFocused(entryIndex, entryKind)
    }

    function lineNumbers(src) {
        var lines = String(src === undefined || src === null ? "" : src).split("\n")
        var count = Math.max(1, lines.length)
        var out = ""
        for (var i = 1; i <= count; ++i)
            out += (i > 1 ? "\n" : "") + i
        return out
    }

    function copyText(value) {
        clip.text = value
        clip.selectAll()
        clip.copy()
    }

    height: card.height
    implicitHeight: card.height
    Component.onCompleted: focusNewCheck()
    onPendingFocusIndexChanged: focusNewCheck()

    Rectangle {
        id: card
        width: parent.width
        height: layout.implicitHeight + 20
        radius: 12
        color: theme.card
        border.color: theme.line

        ColumnLayout {
            id: layout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            spacing: 8

            TextField {
                visible: root.isNote
                text: entryTitle
                Layout.fillWidth: true
                placeholderText: "Title"
                placeholderTextColor: theme.faint
                color: theme.text
                font.family: "Segoe UI"
                font.pixelSize: 18
                font.bold: true
                leftPadding: 8
                rightPadding: 8
                background: Rectangle {
                    radius: 8
                    color: "transparent"
                    border.color: parent.activeFocus ? theme.accent : theme.line
                }
                onTextChanged: {
                    if (text !== entryTitle)
                        entryModel.updateTitle(entryIndex, text)
                }
                onActiveFocusChanged: if (activeFocus) root.noteFocus()
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    visible: !root.isNote
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 8
                    Layout.preferredWidth: visible ? 18 : 0
                    Layout.preferredHeight: 18
                    implicitWidth: 18
                    implicitHeight: 18
                    radius: 5
                    color: entryDone ? theme.accent : "transparent"
                    border.color: entryDone ? theme.accent : theme.muted
                    border.width: 1.5

                    Text {
                        anchors.centerIn: parent
                        visible: entryDone
                        text: "✓"
                        color: theme.accentInk
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: entryModel.updateDone(entryIndex, !entryDone)
                    }
                }

                TextArea {
                    id: textArea
                    text: entryText
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    wrapMode: TextArea.Wrap
                    selectByMouse: true
                    placeholderText: root.isNote ? "Write a note…" : "Write a task…"
                    placeholderTextColor: theme.faint
                    color: (!root.isNote && entryDone) ? theme.muted : theme.text
                    font.family: "Segoe UI"
                    font.pixelSize: 17
                    font.weight: (!root.isNote && entryDone) ? Font.Normal : Font.Medium
                    font.strikeout: !root.isNote && entryDone
                    leftPadding: 2
                    rightPadding: 2
                    topPadding: 4
                    bottomPadding: 4
                    background: Rectangle { color: "transparent" }
                    onTextChanged: {
                        if (text !== entryText)
                            entryModel.updateText(entryIndex, text)
                    }
                    onActiveFocusChanged: if (activeFocus) root.noteFocus()
                    Keys.onShortcutOverride: function(event) {
                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (event.modifiers & Qt.ShiftModifier))
                            event.accepted = true
                    }
                    Keys.onPressed: function(event) {
                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (event.modifiers & Qt.ShiftModifier)) {
                            event.accepted = true
                            root.newCheckRequested()
                        }
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 4
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    implicitWidth: 30
                    implicitHeight: 30
                    radius: 8
                    color: imageHover.containsMouse ? theme.buttonHover : "transparent"

                    Item {
                        anchors.centerIn: parent
                        width: 14
                        height: 12
                        Rectangle {
                            anchors.fill: parent
                            radius: 2
                            color: "transparent"
                            border.color: theme.muted
                            border.width: 1.4
                        }
                        Rectangle {
                            width: 3; height: 3; radius: 1.5
                            color: theme.muted
                            x: 2; y: 2
                        }
                        Rectangle {
                            width: 7; height: 4; radius: 1
                            color: theme.muted
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2
                        }
                    }

                    MouseArea {
                        id: imageHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: fileDialog.open()
                    }

                    ToolTip.visible: imageHover.containsMouse
                    ToolTip.text: "Add image"
                    ToolTip.delay: 400
                }

                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 4
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    implicitWidth: 30
                    implicitHeight: 30
                    radius: 8
                    color: todayHover.containsMouse ? theme.buttonHover : "transparent"

                    Item {
                        anchors.centerIn: parent
                        width: 13
                        height: 13
                        Rectangle {
                            x: 0
                            y: 3
                            width: 9
                            height: 9
                            radius: 1
                            color: "transparent"
                            border.width: 1.3
                            border.color: todayHover.copied ? theme.accent : theme.muted
                        }
                        Rectangle {
                            x: 4
                            y: 0
                            width: 9
                            height: 9
                            radius: 1
                            color: theme.card
                            border.width: 1.3
                            border.color: todayHover.copied ? theme.accent : theme.muted
                        }
                    }

                    MouseArea {
                        id: todayHover
                        property bool copied: false
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.copyToTodayRequested(entryIndex)
                            copied = true
                            todayTimer.restart()
                        }
                        Timer {
                            id: todayTimer
                            interval: 900
                            onTriggered: todayHover.copied = false
                        }
                    }

                    ToolTip.visible: todayHover.containsMouse
                    ToolTip.text: todayHover.copied ? "Copied to today" : "Copy to today"
                    ToolTip.delay: 400
                }

                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 4
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    implicitWidth: 30
                    implicitHeight: 30
                    radius: 8
                    color: deleteHover.containsMouse ? theme.chip : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 13
                        color: deleteHover.containsMouse ? theme.danger : theme.muted
                    }

                    MouseArea {
                        id: deleteHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: entryModel.removeAt(entryIndex)
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: root.isNote && entrySnippets && entrySnippets.length > 0

                Repeater {
                    model: entrySnippets
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: codeColumn.implicitHeight + 16
                        radius: 10
                        color: theme.bg
                        border.color: theme.line
                        clip: true

                        ColumnLayout {
                            id: codeColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Rectangle {
                                    width: 3
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: 3
                                    radius: 2
                                    color: theme.accent
                                }
                                Label {
                                    text: "code"
                                    color: theme.accent
                                    font.family: "Consolas"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                                Item { Layout.fillWidth: true }
                                Label {
                                    text: copyHover.copied ? "Copied" : "Copy"
                                    color: copyHover.containsMouse || copyHover.copied ? theme.accent : theme.muted
                                    font.pixelSize: 12
                                    MouseArea {
                                        id: copyHover
                                        property bool copied: false
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.copyText(modelData)
                                            copied = true
                                            copyTimer.restart()
                                        }
                                        Timer {
                                            id: copyTimer
                                            interval: 900
                                            onTriggered: copyHover.copied = false
                                        }
                                    }
                                }
                                Label {
                                    text: "Remove"
                                    color: removeCodeHover.containsMouse ? theme.danger : theme.muted
                                    font.pixelSize: 12
                                    MouseArea {
                                        id: removeCodeHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: entryModel.removeSnippet(entryIndex, index)
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text {
                                    text: root.lineNumbers(codeArea.text)
                                    color: theme.faint
                                    font.family: "Consolas"
                                    font.pixelSize: 13
                                    Layout.alignment: Qt.AlignTop
                                    horizontalAlignment: Text.AlignRight
                                    Layout.minimumWidth: 22
                                }
                                TextArea {
                                    id: codeArea
                                    text: modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 56
                                    wrapMode: TextEdit.NoWrap
                                    textFormat: TextEdit.PlainText
                                    selectByMouse: true
                                    selectByKeyboard: true
                                    persistentSelection: true
                                    color: theme.text
                                    placeholderText: "Paste code here"
                                    placeholderTextColor: theme.faint
                                    font.family: "Consolas"
                                    font.pixelSize: 13
                                    leftPadding: 10
                                    rightPadding: 8
                                    topPadding: 0
                                    bottomPadding: 4
                                    background: Rectangle { color: "transparent" }
                                    onImplicitHeightChanged: {
                                        var next = Math.max(56, implicitHeight)
                                        if (Layout.preferredHeight !== next)
                                            Layout.preferredHeight = next
                                    }
                                    onTextChanged: {
                                        if (text !== modelData)
                                            entryModel.updateSnippet(entryIndex, index, text)
                                    }
                                    onActiveFocusChanged: {
                                        if (activeFocus)
                                            root.noteFocus()
                                        root.snippetFocused(activeFocus)
                                    }
                                    function pastePlain() {
                                        var plain = entryModel.clipboardText()
                                        if (!plain)
                                            return
                                        var start = Math.min(selectionStart, selectionEnd)
                                        var end = Math.max(selectionStart, selectionEnd)
                                        var next = text.slice(0, start) + plain + text.slice(end)
                                        text = next
                                        cursorPosition = start + plain.length
                                    }
                                    Keys.onShortcutOverride: function(event) {
                                        if (event.matches(StandardKey.Paste))
                                            event.accepted = true
                                    }
                                    Keys.onPressed: function(event) {
                                        if (event.matches(StandardKey.Paste)) {
                                            event.accepted = true
                                            pastePlain()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: 6
                visible: root.isNote && entryTags && entryTags.length > 0

                Repeater {
                    model: entryTags
                    delegate: Rectangle {
                        implicitWidth: chipRow.implicitWidth + 14
                        implicitHeight: 28
                        radius: 14
                        color: theme.chip

                        Row {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                text: "#" + modelData
                                color: theme.accent
                                font.pixelSize: 13
                                font.bold: true
                            }
                            Text {
                                text: "×"
                                color: theme.muted
                                font.pixelSize: 12
                            }
                        }

                        MouseArea {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.max(0, parent.width - 24)
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.tagActivated(String(modelData))
                        }
                        MouseArea {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 24
                            cursorShape: Qt.PointingHandCursor
                            onClicked: entryModel.removeTag(entryIndex, modelData)
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.isNote
                spacing: 8

                TextField {
                    id: newTag
                    Layout.fillWidth: true
                    placeholderText: "Add a hashtag"
                    placeholderTextColor: theme.faint
                    color: theme.text
                    font.pixelSize: 13
                    leftPadding: 10
                    background: Rectangle {
                        radius: 8
                        color: "transparent"
                        border.color: newTag.activeFocus ? theme.accent : theme.line
                    }
                    onAccepted: root.commitTag()
                }

                Rectangle {
                    implicitWidth: addTagLabel.implicitWidth + 18
                    implicitHeight: 32
                    radius: 8
                    color: addTagHover.containsMouse ? theme.buttonHover : theme.chip
                    Text {
                        id: addTagLabel
                        anchors.centerIn: parent
                        text: "Add"
                        color: theme.text
                        font.pixelSize: 13
                    }
                    MouseArea {
                        id: addTagHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.commitTag()
                    }
                }

                Rectangle {
                    implicitWidth: addCodeLabel.implicitWidth + 18
                    implicitHeight: 32
                    radius: 8
                    color: addCodeHover.containsMouse ? theme.buttonHover : theme.chip
                    Text {
                        id: addCodeLabel
                        anchors.centerIn: parent
                        text: "Add code"
                        color: theme.text
                        font.pixelSize: 13
                    }
                    MouseArea {
                        id: addCodeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: entryModel.addSnippet(entryIndex)
                    }
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: 6
                visible: root.isNote

                Repeater {
                    model: tagCatalog
                    delegate: Rectangle {
                        visible: !root.hasTag(modelData)
                        implicitWidth: visible ? suggestLabel.implicitWidth + 16 : 0
                        implicitHeight: visible ? 26 : 0
                        radius: 13
                        color: "transparent"
                        border.color: theme.line
                        Text {
                            id: suggestLabel
                            anchors.centerIn: parent
                            text: "#" + modelData
                            color: theme.muted
                            font.pixelSize: 12
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: entryModel.addTag(entryIndex, modelData)
                        }
                    }
                }
            }

            Flow {
                Layout.fillWidth: true
                Layout.leftMargin: root.isNote ? 0 : 28
                spacing: 8
                visible: entryImages && entryImages.length > 0

                Repeater {
                    model: entryImages
                    delegate: Item {
                        width: 120
                        height: 88

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: theme.bg
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: modelData
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.imagePreviewRequested(modelData)
                        }

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 4
                            color: theme.bg
                            opacity: 0.85

                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                color: theme.text
                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: entryModel.removeImage(entryIndex, index)
                            }
                        }
                    }
                }
            }
        }
    }

    TextEdit {
        id: clip
        visible: false
    }

    FileDialog {
        id: fileDialog
        title: "Choose image"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.gif *.webp)"]
        onAccepted: entryModel.addImageFromFile(entryIndex, fileDialog.selectedFile.toString())
    }
}

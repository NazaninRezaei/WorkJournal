import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Journal 1.0

Dialog {
    id: picker
    modal: true
    focus: true
    padding: 18
    implicitWidth: 380
    implicitHeight: 500
    parent: Overlay.overlay
    anchors.centerIn: parent
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    header: null
    footer: null

    property var theme: ({
        surface: "#121c30", buttonLine: "#314868", buttonHover: "#24385a",
        text: "#e7eef8", muted: "#8ea0bd", faint: "#6d82a3", buttonDown: "#2a4570",
        chip: "#1c3358", accent: "#7eb0ff", button: "#1a2c48"
    })
    property date viewDate: new Date()
    signal picked(int year, int month, int day)

    readonly property int leading: {
        var first = new Date(viewDate.getFullYear(), viewDate.getMonth(), 1)
        return (first.getDay() + 1) % 7
    }
    readonly property int daysInMonth: new Date(viewDate.getFullYear(), viewDate.getMonth() + 1, 0).getDate()
    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    readonly property var weekNames: ["Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri"]

    readonly property string shamsiLabel: {
        var mid = new Date(viewDate.getFullYear(), viewDate.getMonth(), 15, 12, 0, 0)
        var parts = Shamsi.fromGregorian(mid)
        if (!parts || parts.length < 2)
            return ""
        return Shamsi.monthName(parts[1]) + "  " + parts[0]
    }

    function shiftMonth(delta) {
        viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() + delta, 1)
    }

    background: Rectangle {
        color: theme.surface
        radius: 16
        border.color: theme.buttonLine
    }

    contentItem: ColumnLayout {
        implicitWidth: 332
        spacing: 12

        RowLayout {
            Layout.fillWidth: true

            Rectangle {
                implicitWidth: 32
                implicitHeight: 32
                radius: 8
                color: prevHover.containsMouse ? theme.buttonHover : "transparent"
                Text { anchors.centerIn: parent; text: "‹"; color: theme.text; font.pixelSize: 18 }
                MouseArea {
                    id: prevHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: picker.shiftMonth(-1)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: picker.monthNames[picker.viewDate.getMonth()] + "  " + picker.viewDate.getFullYear()
                    color: theme.text
                    font.family: "Segoe UI"
                    font.pixelSize: 18
                    font.bold: true
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: picker.shamsiLabel
                    color: theme.muted
                    font.family: "Segoe UI"
                    font.pixelSize: 13
                }
            }

            Rectangle {
                implicitWidth: 32
                implicitHeight: 32
                radius: 8
                color: nextHover.containsMouse ? theme.buttonHover : "transparent"
                Text { anchors.centerIn: parent; text: "›"; color: theme.text; font.pixelSize: 18 }
                MouseArea {
                    id: nextHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: picker.shiftMonth(1)
                }
            }
        }

        Grid {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 318
            Layout.preferredHeight: 286
            columns: 7
            columnSpacing: 4
            rowSpacing: 4

            Repeater {
                model: picker.weekNames
                delegate: Item {
                    width: 42
                    height: 22
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: theme.faint
                        font.family: "Segoe UI"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }

            Repeater {
                model: 42
                delegate: Item {
                    width: 42
                    height: 40
                    property int dayNum: index - picker.leading + 1
                    property bool inMonth: dayNum >= 1 && dayNum <= picker.daysInMonth
                    property bool isToday: {
                        if (!inMonth)
                            return false
                        var now = new Date()
                        return dayNum === now.getDate()
                                && picker.viewDate.getMonth() === now.getMonth()
                                && picker.viewDate.getFullYear() === now.getFullYear()
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: 8
                        visible: inMonth
                        color: dayHover.containsMouse ? theme.buttonDown : (isToday ? theme.chip : "transparent")
                        border.color: isToday ? theme.accent : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: dayNum
                            color: theme.text
                            font.family: "Segoe UI"
                            font.pixelSize: 14
                            font.bold: isToday
                        }
                    }

                    MouseArea {
                        id: dayHover
                        anchors.fill: parent
                        enabled: inMonth
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            picker.picked(picker.viewDate.getFullYear(), picker.viewDate.getMonth() + 1, dayNum)
                            picker.close()
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4

            Rectangle {
                implicitWidth: todayLabel.implicitWidth + 24
                implicitHeight: 32
                radius: 8
                color: todayHover.containsMouse ? theme.buttonHover : theme.button
                border.color: theme.buttonLine
                Text {
                    id: todayLabel
                    anchors.centerIn: parent
                    text: "Today"
                    color: theme.text
                    font.family: "Segoe UI"
                    font.pixelSize: 13
                }
                MouseArea {
                    id: todayHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var now = new Date()
                        picker.picked(now.getFullYear(), now.getMonth() + 1, now.getDate())
                        picker.close()
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitWidth: closeLabel.implicitWidth + 24
                implicitHeight: 32
                radius: 8
                color: closeHover.containsMouse ? theme.buttonHover : "transparent"
                Text {
                    id: closeLabel
                    anchors.centerIn: parent
                    text: "Close"
                    color: theme.muted
                    font.family: "Segoe UI"
                    font.pixelSize: 13
                }
                MouseArea {
                    id: closeHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: picker.close()
                }
            }
        }
    }
}

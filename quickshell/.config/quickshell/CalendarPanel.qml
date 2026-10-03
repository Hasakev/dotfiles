import QtQuick
import QtQuick.Controls as QQC
import Quickshell

// Big glowing clock + month grid. Scroll or arrows slide between months.
Item {
    id: root

    property date today: new Date()
    property int offset: 0          // months from the current one
    property int dir: 1
    readonly property date month: new Date(today.getFullYear(), today.getMonth() + offset, 1)

    implicitWidth: 280
    implicitHeight: col.implicitHeight

    SystemClock { id: clock; precision: SystemClock.Seconds; onDateChanged: root.today = date }

    function shift(n) { dir = n; offset += n; slide.restart() }

    Column {
        id: col
        width: parent.width
        spacing: 10

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clock.date, "HH:mm:ss")
            font.family: "Inter Display"
            font.pixelSize: 40
            font.weight: Font.Light
            color: Theme.text
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(clock.date, "dddd, d MMMM")
            color: Theme.subtext0
        }

        Item {
            width: parent.width
            height: 28
            IconButton { anchors.left: parent.left; text: "󰅁"; size: 13; onClicked: root.shift(-1) }
            Label {
                anchors.centerIn: parent
                text: Qt.formatDate(root.month, "MMMM yyyy")
                color: Theme.subtext1
                font.weight: Font.DemiBold
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.offset = 0 }
            }
            IconButton { anchors.right: parent.right; text: "󰅂"; size: 13; onClicked: root.shift(1) }
        }

        QQC.DayOfWeekRow {
            width: parent.width
            locale: Qt.locale()
            delegate: Label {
                required property string shortName
                text: shortName.slice(0, 2)
                horizontalAlignment: Text.AlignHCenter
                color: Theme.overlay1
                font.pixelSize: 10
                font.weight: Font.Bold
            }
        }

        QQC.MonthGrid {
            id: grid
            width: parent.width
            month: root.month.getMonth()
            year: root.month.getFullYear()
            locale: Qt.locale()

            ParallelAnimation {
                id: slide
                NumberAnimation { target: grid; property: "opacity"; from: 0; to: 1; duration: 260 }
                NumberAnimation { target: grid; property: "x"; from: 30 * root.dir; to: 0; duration: 320; easing.type: Easing.OutCubic }
            }

            // Root must be a Text: MonthGrid sizes cells from it (a Rectangle
            // root collapses every row to 0px).
            delegate: Label {
                id: cell
                required property var model
                height: 28
                horizontalAlignment: Text.AlignHCenter
                text: model.day
                color: model.today ? Theme.accent : model.month === grid.month ? Theme.text : Theme.overlay0
                font.weight: model.today ? Font.Bold : Font.Normal
                Rectangle {
                    anchors.fill: parent
                    z: -1
                    radius: 6
                    visible: cell.model.today
                    color: Theme.a(Theme.accent, 0.14)
                }
            }
        }
    }

    WheelHandler { onWheel: e => root.shift(e.angleDelta.y > 0 ? -1 : 1) }
}

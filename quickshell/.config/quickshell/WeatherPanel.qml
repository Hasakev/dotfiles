import QtQuick

// Current conditions from wttr.in.
Item {
    id: root

    implicitWidth: 260
    implicitHeight: col.implicitHeight

    Column {
        id: col
        width: parent.width
        spacing: 12

        Row {
            spacing: 14
            Label {
                text: Icons.weather(Weather.desc)
                icon: true
                font.pixelSize: 44
                color: Theme.accent
                // gentle bob
                SequentialAnimation on y {
                    loops: Animation.Infinite
                    NumberAnimation { to: -3; duration: 1600; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 3; duration: 1600; easing.type: Easing.InOutSine }
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Label { text: Weather.temp; font.pixelSize: 26; font.weight: Font.Bold; color: Theme.text }
                Label { text: Weather.ok ? Weather.desc : "Unavailable"; color: Theme.subtext0 }
                Label { text: Weather.location; color: Theme.overlay1; font.pixelSize: 10 }
            }
        }

        Grid {
            columns: 2
            columnSpacing: 20
            rowSpacing: 6
            visible: Weather.ok
            Repeater {
                model: [
                    ["󰔏", "Feels", Weather.feels], ["󰖎", "Humidity", Weather.humidity],
                    ["󰖝", "Wind", Weather.wind], ["󰖗", "Rain", Weather.rain],
                    ["󰖙", "UV", Weather.uv]
                ]
                delegate: Row {
                    required property var modelData
                    spacing: 6
                    width: 110
                    Label { text: modelData[0]; icon: true; color: Theme.overlay2; font.pixelSize: 13 }
                    Label { text: modelData[1]; color: Theme.overlay1; font.pixelSize: 11 }
                    Label { text: modelData[2]; color: Theme.subtext1; font.pixelSize: 11 }
                }
            }
        }

        IconButton {
            anchors.right: parent.right
            text: "󰑐"
            size: 13
            accent: Theme.teal
            onClicked: Weather.refresh()
        }
    }
}

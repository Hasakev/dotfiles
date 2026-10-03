import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris

// Now playing, like a record sleeve: the cover is the hero (glowing in its own
// colour, controls on hover), the seek bar is the live spectrum, and synced
// lyrics scroll underneath. Everything tints to the cover's colour.
Item {
    id: root

    readonly property MprisPlayer p: Player.active
    readonly property bool playing: p?.isPlaying ?? false
    readonly property color tint: Player.artColor
    readonly property real frac: p && p.length > 0 ? Math.min(1, p.position / p.length) : 0

    implicitWidth: 460
    implicitHeight: col.implicitHeight

    Component.onCompleted: Lyrics.wanted = true
    Component.onDestruction: Lyrics.wanted = false

    // Finer position updates while open, so lyrics land on the beat.
    Timer {
        running: root.playing
        interval: 250
        repeat: true
        onTriggered: root.p.positionChanged()
    }

    Column {
        id: col
        width: parent.width
        spacing: 16

        Row {
            width: parent.width
            spacing: 18

            Item {
                id: art
                width: 120
                height: 120

                // Soft halo in the cover's colour.
                Rectangle {
                    id: halo
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 6
                    width: parent.width
                    height: parent.height
                    radius: 16
                    color: root.tint
                    visible: false
                }
                MultiEffect {
                    source: halo
                    anchors.fill: halo
                    blurEnabled: true
                    blur: 1
                    blurMax: 48
                    autoPaddingEnabled: true
                    opacity: root.playing ? 0.8 : 0.35
                    Behavior on opacity { NumberAnimation { duration: 500 } }
                }

                ClippingRectangle {
                    anchors.fill: parent
                    radius: 14
                    color: Theme.surface1

                    Image {
                        anchors.fill: parent
                        source: root.p?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize: Qt.size(240, 240)
                    }
                    Label {
                        anchors.centerIn: parent
                        visible: !(root.p?.trackArtUrl)
                        icon: true
                        text: "󰝚"
                        font.pixelSize: 36
                        color: Theme.overlay1
                    }

                    // Controls surface over the cover on hover.
                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(0, 0, 0, 0.5)
                        opacity: artHover.hovered ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                        Row {
                            anchors.centerIn: parent
                            spacing: 2
                            IconButton { anchors.verticalCenter: parent.verticalCenter; text: "󰒮"; size: 15; accent: Theme.text; onClicked: root.p?.previous() }
                            IconButton { anchors.verticalCenter: parent.verticalCenter; text: root.playing ? "󰏤" : "󰐊"; size: 24; accent: Theme.text; onClicked: root.p?.togglePlaying() }
                            IconButton { anchors.verticalCenter: parent.verticalCenter; text: "󰒭"; size: 15; accent: Theme.text; onClicked: root.p?.next() }
                        }
                    }
                }
                HoverHandler { id: artHover }
            }

            Column {
                width: parent.width - art.width - 18
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Label {
                    width: parent.width
                    text: root.p?.trackTitle || "Nothing playing"
                    font.family: "Inter Display"
                    font.pixelSize: 21
                    font.weight: Font.DemiBold
                    lineHeight: 1.05
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Label {
                    width: parent.width
                    text: [root.p?.trackArtist, root.p?.trackAlbum].filter(s => s).join("  ·  ")
                    color: Theme.subtext0
                    font.weight: Font.Normal
                    elide: Text.ElideRight
                }
                Row {
                    spacing: 4
                    topPadding: 2
                    IconButton {
                        visible: root.p?.shuffleSupported ?? false
                        text: "󰒟"; size: 12
                        accent: root.tint
                        on: root.p?.shuffle ?? false
                        onClicked: root.p.shuffle = !root.p.shuffle
                    }
                    IconButton {
                        visible: root.p?.loopSupported ?? false
                        text: root.p?.loopState === MprisLoopState.Track ? "󰑘" : "󰑖"; size: 12
                        accent: root.tint
                        on: (root.p?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
                        onClicked: root.p.loopState = root.p.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                            : root.p.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        leftPadding: 4
                        text: root.p?.identity ?? ""
                        color: Theme.overlay1
                        font.pixelSize: 10
                    }
                }
            }
        }

        // Spectrum seek bar: bars before the playhead lit in the cover colour.
        Column {
            width: parent.width
            spacing: 4

            Item {
                id: spectrum
                width: parent.width
                height: 34
                readonly property int n: Cava.count
                readonly property real gap: 2
                readonly property real barW: (width - (n - 1) * gap) / n

                Repeater {
                    model: spectrum.n
                    delegate: Rectangle {
                        required property int index
                        readonly property real v: Cava.bars[index] ?? 0
                        readonly property bool played: (index + 0.5) / spectrum.n <= root.frac
                        x: index * (spectrum.barW + spectrum.gap)
                        anchors.verticalCenter: parent.verticalCenter
                        width: spectrum.barW
                        height: 3 + (spectrum.height - 3) * v
                        radius: Math.min(2, width / 2)
                        color: played ? root.tint : Theme.a(Theme.text, seekMouse.containsMouse ? 0.2 : 0.12)
                        Behavior on height { NumberAnimation { duration: 70 } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
                MouseArea {
                    id: seekMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: root.p?.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: m => { if (root.p?.canSeek) root.p.position = Math.max(0, Math.min(1, m.x / width)) * root.p.length }
                }
            }
            Item {
                width: parent.width
                height: 12
                Label { text: Player.fmt(root.p?.position ?? 0); color: Theme.overlay1; font.pixelSize: 10 }
                Label { anchors.right: parent.right; text: "-" + Player.fmt((root.p?.length ?? 0) - (root.p?.position ?? 0)); color: Theme.overlay1; font.pixelSize: 10 }
            }
        }

        // Synced lyrics: three lines, the current one bright and centred.
        Item {
            width: parent.width
            height: 78
            visible: Lyrics.lines.length > 0 || Lyrics.loading

            Label {
                anchors.centerIn: parent
                visible: Lyrics.loading && Lyrics.lines.length === 0
                text: "Finding lyrics…"
                color: Theme.overlay0
                font.pixelSize: 11
            }

            ListView {
                id: lyrics
                anchors.fill: parent
                clip: true
                interactive: false
                model: Lyrics.lines
                currentIndex: Math.max(0, Lyrics.index((root.p?.position ?? 0) + 0.25))
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: height / 2 - 13
                preferredHighlightEnd: height / 2 + 13
                highlightMoveDuration: 450
                highlightMoveVelocity: -1

                delegate: Label {
                    required property var modelData
                    required property int index
                    readonly property int dist: Math.abs(index - lyrics.currentIndex)
                    width: lyrics.width
                    height: 26
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: modelData.text
                    font.pixelSize: dist === 0 ? 14 : 12
                    font.weight: dist === 0 ? Font.DemiBold : Font.Normal
                    color: dist === 0 ? Theme.text : Theme.subtext0
                    opacity: dist === 0 ? 1 : dist === 1 ? 0.45 : 0.15
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }
            }
        }

        // Player switcher when several are around.
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            visible: Player.players.length > 1
            Repeater {
                model: Player.players
                delegate: Rectangle {
                    required property MprisPlayer modelData
                    readonly property bool cur: modelData === root.p
                    width: cur ? 16 : 6
                    height: 6
                    radius: 3
                    color: cur ? root.tint : Theme.overlay0
                    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: Player.active = parent.modelData }
                }
            }
        }
    }
}

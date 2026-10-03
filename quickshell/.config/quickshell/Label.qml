import QtQuick
import QtQuick.Effects

// Inter with tabular figures (numbers don't jitter as they change).
// icon: true switches to the symbol font. glow: a faint lamp halo, used rarely.
Text {
    id: label
    property bool glow: false
    property bool icon: false

    color: Theme.text
    font.family: icon ? Theme.iconFont : Theme.font
    font.pixelSize: 12
    font.weight: Font.Medium
    font.features: { "tnum": 1, "cv11": 1 }
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
    Behavior on color { ColorAnimation { duration: 200 } }

    layer.enabled: glow
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: label.color
        shadowBlur: 0.5
        shadowOpacity: 0.45
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
    }
}

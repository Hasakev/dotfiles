import QtQuick

// Filled sparkline. Repaints only when the data changes, not per frame.
Canvas {
    id: root

    property var values: []
    property real max: 1
    property int capacity: 60
    property color accent: Theme.cyan

    onValuesChanged: requestPaint()
    onAccentChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const n = values.length
        if (n < 2) return
        const step = width / (capacity - 1), x0 = width - (n - 1) * step
        const y = v => height - 2 - Math.max(0, Math.min(1, v / max)) * (height - 4)

        ctx.beginPath()
        ctx.moveTo(x0, y(values[0]))
        for (let i = 1; i < n; i++) ctx.lineTo(x0 + i * step, y(values[i]))

        ctx.strokeStyle = accent
        ctx.lineWidth = 1.5
        ctx.lineJoin = "round"
        ctx.stroke()

        ctx.lineTo(width, height)
        ctx.lineTo(x0, height)
        ctx.closePath()
        const g = ctx.createLinearGradient(0, 0, 0, height)
        g.addColorStop(0, Theme.a(accent, 0.35))
        g.addColorStop(1, Theme.a(accent, 0))
        ctx.fillStyle = g
        ctx.fill()
    }
}

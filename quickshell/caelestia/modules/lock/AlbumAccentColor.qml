pragma ComponentBehavior: Bound

import QtQuick

// Invisible component — feed it an imageUrl, read back accentColor.
// Uses a hidden 32×32 Canvas to sample pixels, buckets them by hue,
// and scores each bucket by (avgSaturation × √count) so the most
// vibrant AND representative hue wins. Lightness is clamped to ~0.75
// so the result is always readable as text on a dark background.
Item {
    id: root

    property string imageUrl: ""
    property color accentColor: "white"

    visible: false
    width: 0
    height: 0

    onImageUrlChanged: {
        if (imageUrl !== "") {
            if (prevUrl !== "" && prevUrl !== imageUrl)
                canvas.unloadImage(prevUrl)
            prevUrl = imageUrl
            canvas.loadImage(imageUrl)
        }
    }

    property string prevUrl: ""

    Canvas {
        id: canvas

        width: 32
        height: 32
        visible: false
        renderTarget: Canvas.Image

        onImageLoaded: requestPaint()

        onPaint: {
            if (!root.imageUrl || !isImageLoaded(root.imageUrl))
                return

            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.drawImage(root.imageUrl, 0, 0, width, height)

            var imageData = ctx.getImageData(0, 0, width, height)
            if (!imageData)
                return

            var data = imageData.data
            var result = extractVibrantColor(data)
            root.accentColor = result !== null ? result : "white"
        }

        function extractVibrantColor(data) {
            var HUE_BUCKETS = 36

            // Each bucket tracks totals for averaging
            var buckets = []
            for (var i = 0; i < HUE_BUCKETS; i++)
                buckets.push({ totalSat: 0, totalR: 0, totalG: 0, totalB: 0, count: 0 })

            for (var p = 0; p < data.length; p += 4) {
                var r = data[p]     / 255.0
                var g = data[p + 1] / 255.0
                var b = data[p + 2] / 255.0
                var a = data[p + 3] / 255.0

                if (a < 0.5) continue

                var max = Math.max(r, g, b)
                var min = Math.min(r, g, b)
                var l   = (max + min) / 2.0
                var d   = max - min

                // Skip near-black, near-white, near-gray
                if (l < 0.10 || l > 0.92) continue
                if (d < 0.08)             continue

                // HSL saturation
                var s = d / (1.0 - Math.abs(2.0 * l - 1.0))
                if (s < 0.30) continue

                // Hue (0–1)
                var h
                if (max === r)      h = ((g - b) / d % 6 + 6) % 6
                else if (max === g) h = (b - r) / d + 2
                else                h = (r - g) / d + 4
                h /= 6.0

                var bi = Math.floor(h * HUE_BUCKETS) % HUE_BUCKETS
                buckets[bi].totalSat += s
                buckets[bi].totalR   += r
                buckets[bi].totalG   += g
                buckets[bi].totalB   += b
                buckets[bi].count++
            }

            // Score: avgSaturation × √count — vibrant AND common hues win
            var bestScore  = -1
            var bestBucket = -1
            for (var bi2 = 0; bi2 < HUE_BUCKETS; bi2++) {
                var bkt = buckets[bi2]
                if (bkt.count === 0) continue
                var avgSat = bkt.totalSat / bkt.count
                var score  = avgSat * Math.sqrt(bkt.count)
                if (score > bestScore) {
                    bestScore  = score
                    bestBucket = bi2
                }
            }

            if (bestBucket === -1) return null

            // Average color of winning bucket
            var wb = buckets[bestBucket]
            var ar = wb.totalR / wb.count
            var ag = wb.totalG / wb.count
            var ab = wb.totalB / wb.count
            var color = Qt.rgba(ar, ag, ab, 1.0)

            // Clamp lightness so it reads well on a dark background
            var lum = color.hslLightness
            if (lum < 0.62)
                color = Qt.hsla(color.hslHue, Math.min(1.0, color.hslSaturation * 1.1), 0.75, 1.0)
            else if (lum > 0.92)
                color = Qt.hsla(color.hslHue, color.hslSaturation, 0.85, 1.0)

            return color
        }
    }
}

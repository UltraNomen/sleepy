import AppKit

/// Draws the app icon at every size an .iconset needs. Run through make-icon.sh.
@main
struct MakeIcon {
    static let sizes: [(name: String, pixels: Int)] = [
        ("icon_16x16", 16), ("icon_16x16@2x", 32),
        ("icon_32x32", 32), ("icon_32x32@2x", 64),
        ("icon_128x128", 128), ("icon_128x128@2x", 256),
        ("icon_256x256", 256), ("icon_256x256@2x", 512),
        ("icon_512x512", 512), ("icon_512x512@2x", 1024),
    ]

    static func main() throws {
        let dir = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        for size in sizes {
            let image = render(pixels: size.pixels)
            let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
            try data.write(to: dir.appendingPathComponent("\(size.name).png"))
        }
    }

    /// Drawn on a 1024 canvas, top-left origin, then scaled to `pixels`.
    static func render(pixels: Int) -> CGImage {
        let ctx = CGContext(
            data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        let scale = CGFloat(pixels) / 1024
        ctx.scaleBy(x: scale, y: scale)
        ctx.translateBy(x: 0, y: 1024)
        ctx.scaleBy(x: 1, y: -1)

        let body = CGRect(x: 100, y: 100, width: 824, height: 824)
        let shape = CGPath(roundedRect: body, cornerWidth: 186, cornerHeight: 186, transform: nil)

        // Drop shadow
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -14 * scale), blur: 30 * scale,
                      color: CGColor(gray: 0, alpha: 0.4))
        ctx.addPath(shape)
        ctx.setFillColor(CGColor(gray: 0.05, alpha: 1))
        ctx.fillPath()
        ctx.restoreGState()

        // Body: near-black, slightly lifted at the top like glass catching light
        ctx.saveGState()
        ctx.addPath(shape)
        ctx.clip()
        let gradient = CGGradient(
            colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
            colors: [rgb(0x24, 0x26, 0x33), rgb(0x0D, 0x0E, 0x12)] as CFArray,
            locations: [0, 0.75]
        )!
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 512, y: 100), end: CGPoint(x: 512, y: 924), options: [])

        // Dot grain, only where it can be seen
        if pixels >= 256 {
            ctx.setFillColor(CGColor(gray: 1, alpha: 0.05))
            var y: CGFloat = 104
            while y < 924 {
                var x: CGFloat = 104
                while x < 924 {
                    ctx.fillEllipse(in: CGRect(x: x, y: y, width: 3.5, height: 3.5))
                    x += 12
                }
                y += 12
            }
        }
        ctx.restoreGState()

        // Hairline rim
        ctx.addPath(CGPath(roundedRect: body.insetBy(dx: 2, dy: 2), cornerWidth: 184, cornerHeight: 184, transform: nil))
        ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.18))
        ctx.setLineWidth(4)
        ctx.strokePath()

        // Moon: fewer, bigger dots at small sizes so it still reads
        let grid = pixels <= 64 ? 11 : 19
        let area = CGRect(x: 262, y: 212, width: 560, height: 560)
        let pitch = area.width / CGFloat(grid)
        let dot = pitch * 0.74
        func cellRect(_ col: Int, _ row: Int) -> CGRect {
            CGRect(x: area.minX + CGFloat(col) * pitch + (pitch - dot) / 2,
                   y: area.minY + CGFloat(row) * pitch + (pitch - dot) / 2,
                   width: dot, height: dot)
        }
        ctx.setFillColor(CGColor(gray: 1, alpha: 1))
        for cell in MoonDots.cells(grid: grid) {
            ctx.fillEllipse(in: cellRect(cell.col, cell.row))
        }

        // One blue star in the crescent's opening
        ctx.setFillColor(rgb(0x3A, 0x4B, 0xF0))
        ctx.fillEllipse(in: cellRect(grid * 6 / 10, grid * 4 / 10))

        return ctx.makeImage()!
    }

    static func rgb(_ r: Int, _ g: Int, _ b: Int) -> CGColor {
        CGColor(srgbRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
    }
}

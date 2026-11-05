import AppKit
import SleepyCore

/// The dotted moon for the menu bar. It's a template image, so macOS tints it
/// to match a light or dark menu bar.
enum MoonIcon {
    private static let grid = 9
    private static let pitch: CGFloat = 2
    private static let dot: CGFloat = 1.7

    static let menuBar: NSImage = {
        let side = CGFloat(grid) * pitch
        let image = NSImage(size: NSSize(width: side, height: side), flipped: true) { _ in
            NSColor.black.setFill()
            for cell in MoonDots.cells(grid: grid) {
                let inset = (pitch - dot) / 2
                NSBezierPath(ovalIn: NSRect(
                    x: CGFloat(cell.col) * pitch + inset,
                    y: CGFloat(cell.row) * pitch + inset,
                    width: dot, height: dot
                )).fill()
            }
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Sleepy"
        return image
    }()
}

import Foundation

/// The Sleepy mark: a crescent moon on a square dot grid. The menu bar icon and
/// the app icon both draw from this, at different grid sizes.
public enum MoonDots {
    /// Cells lit for a `grid`×`grid` moon. Row 0 is the top row.
    public static func cells(grid: Int) -> [(col: Int, row: Int)] {
        let n = Double(grid)
        let center = (n - 1) / 2
        let radius = n * 0.5
        // The bite that turns the disc into a crescent, opening to the upper right.
        let biteX = center + n * 0.17
        let biteY = center - n * 0.17
        let biteRadius = n * 0.40

        var lit: [(col: Int, row: Int)] = []
        for row in 0..<grid {
            for col in 0..<grid {
                let x = Double(col), y = Double(row)
                let inDisc = hypot(x - center, y - center) <= radius
                let inBite = hypot(x - biteX, y - biteY) <= biteRadius
                if inDisc && !inBite { lit.append((col, row)) }
            }
        }
        return lit
    }
}

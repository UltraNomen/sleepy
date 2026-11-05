import SleepyCore
import SwiftUI

/// Draws digits and ":" as a 5×7 dot matrix, like the countdown in the design.
struct DotMatrixText: View {
    let text: String
    var dot: CGFloat = 4.2
    var gap: CGFloat = 2.2
    var color: Color = .white

    private var pitch: CGFloat { dot + gap }

    var body: some View {
        let glyphs = text.compactMap { Self.font[$0] }
        let columns = glyphs.reduce(0) { $0 + $1.width } + max(0, glyphs.count - 1)
        Canvas { ctx, _ in
            var path = Path()
            var originCol = 0
            for g in glyphs {
                for (row, bits) in g.rows.enumerated() {
                    for col in 0..<g.width where bits[bits.index(bits.startIndex, offsetBy: col)] == "1" {
                        let x = CGFloat(originCol + col) * pitch
                        path.addEllipse(in: CGRect(x: x, y: CGFloat(row) * pitch, width: dot, height: dot))
                    }
                }
                originCol += g.width + 1
            }
            ctx.fill(path, with: .color(color))
        }
        .frame(width: CGFloat(columns) * pitch - gap, height: 7 * pitch - gap)
        .accessibilityElement()
        .accessibilityLabel(text)
    }

    private struct Glyph {
        let rows: [String]
        var width: Int { rows[0].count }
    }

    private static let font: [Character: Glyph] = [
        "0": Glyph(rows: ["01110", "10001", "10011", "10101", "11001", "10001", "01110"]),
        "1": Glyph(rows: ["00100", "01100", "00100", "00100", "00100", "00100", "01110"]),
        "2": Glyph(rows: ["01110", "10001", "00001", "00010", "00100", "01000", "11111"]),
        "3": Glyph(rows: ["11111", "00010", "00100", "00010", "00001", "10001", "01110"]),
        "4": Glyph(rows: ["00010", "00110", "01010", "10010", "11111", "00010", "00010"]),
        "5": Glyph(rows: ["11111", "10000", "11110", "00001", "00001", "10001", "01110"]),
        "6": Glyph(rows: ["00110", "01000", "10000", "11110", "10001", "10001", "01110"]),
        "7": Glyph(rows: ["11111", "00001", "00010", "00100", "01000", "01000", "01000"]),
        "8": Glyph(rows: ["01110", "10001", "10001", "01110", "10001", "10001", "01110"]),
        "9": Glyph(rows: ["01110", "10001", "10001", "01111", "00001", "00010", "01100"]),
        ":": Glyph(rows: ["0", "1", "0", "1", "0", "1", "0"]),
    ]
}

/// "[▓▓▓░░░░░░░] 2%"
struct AsciiProgress: View {
    let fraction: Double
    var cells = 22

    var body: some View {
        let bar = TimeFormat.asciiBar(fraction: fraction, cells: cells)
        HStack(spacing: 8) {
            Text("[\(bar.filled)\(Text(bar.empty).foregroundStyle(Color.white.opacity(0.22)))]")
                .foregroundStyle(Theme.accent)
                .font(.system(size: 10, design: .monospaced))
                .lineLimit(1)
            Text("\(Int((fraction * 100).rounded()))%")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))
        }
        .accessibilityElement()
        .accessibilityLabel("Progress \(Int(fraction * 100)) percent")
    }
}

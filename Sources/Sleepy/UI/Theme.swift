import SwiftUI

enum Theme {
    static let accent = Color(red: 0x3A / 255, green: 0x4B / 255, blue: 0xF0 / 255)
    static let ink = Color(red: 0x0D / 255, green: 0x0E / 255, blue: 0x12 / 255)
    static let paneTint = Color.black.opacity(0.78)
    static let hairline = Color.white.opacity(0.18)
    static let secondary = Color.white.opacity(0.55)
    static let tertiary = Color.white.opacity(0.38)
    static let lavender = Color(red: 0.70, green: 0.72, blue: 1.0)
}

extension View {
    /// Small wide-tracked monospace caps: "SLEEP IN", "MAC SLEEPS AT 05:05".
    func label(_ color: Color = Theme.secondary, size: CGFloat = 9.5) -> some View {
        self.font(.system(size: size, weight: .medium, design: .monospaced))
            .tracking(1.6)
            .textCase(.uppercase)
            .lineLimit(1)
            .foregroundStyle(color)
    }

    /// Sharp-cornered liquid-glass pane with a hairline rim and dot grain.
    func glassPane(tint: Color = Theme.paneTint) -> some View {
        self
            .background { DotGrain() }
            .glassEffect(.regular.tint(tint), in: Rectangle())
            .overlay { Rectangle().strokeBorder(Theme.hairline, lineWidth: 0.5) }
    }
}

/// Faint dot pattern drawn over glass panes.
struct DotGrain: View {
    var pitch: CGFloat = 3
    var opacity: Double = 0.07

    var body: some View {
        Canvas { ctx, size in
            var path = Path()
            var y: CGFloat = 1
            while y < size.height {
                var x: CGFloat = 1
                while x < size.width {
                    path.addRect(CGRect(x: x, y: y, width: 1, height: 1))
                    x += pitch
                }
                y += pitch
            }
            ctx.fill(path, with: .color(.white.opacity(opacity)))
        }
        .allowsHitTesting(false)
    }
}

/// Hairline divider used between popover sections.
struct Hairline: View {
    var body: some View { Rectangle().fill(Theme.hairline).frame(height: 0.5) }
}

// MARK: - Buttons

/// Capsule button. `.filled` is white on black, `.accent` blue, `.outline` a hairline ring.
struct PillButtonStyle: ButtonStyle {
    enum Kind { case filled, accent, outline }
    var kind: Kind = .outline
    var height: CGFloat = 28

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12.5, weight: .medium))
            .padding(.horizontal, 13)
            .frame(height: height)
            .foregroundStyle(kind == .filled ? Color.black : Color.white)
            .background {
                switch kind {
                case .filled: Capsule().fill(Color.white)
                case .accent: Capsule().fill(Theme.accent)
                case .outline: Capsule().strokeBorder(Color.white.opacity(0.75), lineWidth: 1)
                }
            }
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// Round − / + stepper button.
struct CircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .frame(width: 24, height: 24)
            .foregroundStyle(.white)
            .background(Circle().strokeBorder(Color.white.opacity(0.4), lineWidth: 1))
            .contentShape(Circle())
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

/// Full-width plain menu row with hover highlight.
struct MenuRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        MenuRowBody(configuration: configuration)
    }

    private struct MenuRowBody: View {
        let configuration: Configuration
        @State private var hover = false
        var body: some View {
            configuration.label
                .font(.system(size: 12.5))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: 23, alignment: .leading)
                .background(hover || configuration.isPressed ? Color.white.opacity(0.08) : .clear)
                .contentShape(Rectangle())
                .onHover { hover = $0 }
        }
    }
}

// MARK: - Square toggle

/// The design's square switch: blue track with a dark knob and "ON", or dark track and "OFF".
struct SquareToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button { isOn.toggle() } label: {
            HStack(spacing: 8) {
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Rectangle()
                        .fill(isOn ? Theme.accent : Color.white.opacity(0.1))
                        .overlay(Rectangle().strokeBorder(isOn ? .clear : Theme.hairline, lineWidth: 0.5))
                    Rectangle()
                        .fill(isOn ? Theme.ink : Color.white)
                        .frame(width: 12, height: 12)
                        .padding(3)
                }
                .frame(width: 34, height: 18)
                .animation(.snappy(duration: 0.18), value: isOn)
                Text(isOn ? "On" : "Off")
                    .label(isOn ? Theme.accent : Theme.tertiary, size: 8.5)
                    .frame(width: 24, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation { Toggle("", isOn: $isOn) }
    }
}

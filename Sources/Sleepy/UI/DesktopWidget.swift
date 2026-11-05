import AppKit
import SleepyCore
import SwiftUI

/// Hosts SwiftUI in a borderless panel: takes the first click, and lets the
/// panel be dragged by its background.
final class PanelHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override var mouseDownCanMoveWindow: Bool { true }
}

/// A live Sleepy card on the desktop: above the icons, below every normal window.
@MainActor
final class DesktopWidgetController {
    nonisolated private static let originKey = "desktopWidgetOrigin"
    private var panel: NSPanel?
    private var moveObserver: NSObjectProtocol?

    func show(model: AppModel) {
        if panel == nil { panel = makePanel(model: model) }
        panel?.orderFrontRegardless()
    }

    func hide() { panel?.orderOut(nil) }

    private func makePanel(model: AppModel) -> NSPanel {
        let host = PanelHostingView(rootView: DesktopWidgetView(model: model))
        let size = host.fittingSize
        let p = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered, defer: false
        )
        // In a debug preview it floats on top, so it can be reached while other windows are open.
        p.level = UserDefaults.standard.bool(forKey: "preview")
            ? .floating
            : NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        p.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        p.hidesOnDeactivate = false
        p.isMovableByWindowBackground = true
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = true
        p.contentView = host
        p.setFrameOrigin(Self.savedOrigin(size: size) ?? Self.defaultOrigin(size: size))
        moveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification, object: p, queue: .main
        ) { [weak p] _ in
            guard let origin = p?.frame.origin else { return }
            UserDefaults.standard.set(NSStringFromPoint(origin), forKey: Self.originKey)
        }
        return p
    }

    /// The last dragged spot, if it's still on a connected display.
    private static func savedOrigin(size: NSSize) -> NSPoint? {
        guard let saved = UserDefaults.standard.string(forKey: originKey) else { return nil }
        let origin = NSPointFromString(saved)
        let frame = NSRect(origin: origin, size: size)
        return NSScreen.screens.contains { $0.visibleFrame.contains(frame) } ? origin : nil
    }

    private static func defaultOrigin(size: NSSize) -> NSPoint {
        let frame = NSScreen.main?.visibleFrame ?? .zero
        return NSPoint(x: frame.maxX - size.width - 24, y: frame.maxY - size.height - 24)
    }
}

struct DesktopWidgetView: View {
    let model: AppModel

    private var engine: TimerEngine { model.engine }
    private static let quickStarts = [15, 30, 45, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Sleepy").label()
                Spacer()
                HStack(spacing: 6) {
                    Rectangle().fill(engine.isRunning ? Theme.accent : Theme.tertiary).frame(width: 5, height: 5)
                    Text(engine.isRunning ? "Running" : "Idle")
                        .label(engine.isRunning ? Theme.lavender : Theme.tertiary)
                }
            }
            .padding(.bottom, 12)

            DotMatrixText(
                text: TimeFormat.countdown(seconds: engine.isRunning ? engine.remainingSeconds : engine.selectedPreset * 60),
                dot: 3.2, gap: 1.6,
                color: engine.isRunning ? .white : .white.opacity(0.35)
            )
            .padding(.bottom, 9)

            Group {
                if let sleepDate = engine.sleepDate {
                    Text("Mac sleeps at \(TimeFormat.clock(sleepDate))")
                } else {
                    Text("Sleep in")
                }
            }
            .label()
            .padding(.bottom, 10)

            HStack(spacing: 5) {
                if engine.isRunning {
                    Button { engine.extend(minutes: 15) } label: { Label("15 min", systemImage: "plus") }
                        .buttonStyle(PillButtonStyle(kind: .outline))
                    Button("Stop") { model.stop() }
                        .buttonStyle(PillButtonStyle(kind: .filled))
                } else {
                    ForEach(Self.quickStarts, id: \.self) { minutes in
                        Button("\(minutes)") { engine.start(minutes: minutes) }
                            .buttonStyle(PillButtonStyle(kind: .outline))
                            .accessibilityLabel("Start \(minutes) minutes")
                    }
                }
            }
            .frame(height: 28)
        }
        .padding(14)
        .frame(width: 240, alignment: .leading)
        .glassPane()
        .contentShape(Rectangle())
        .gesture(WindowDragGesture())
        .preferredColorScheme(.dark)
    }
}

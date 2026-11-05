import AppKit
import SleepyCore
import SwiftUI

/// Floating card at the bottom-left of the screen, ten minutes before sleep.
@MainActor
final class HeadsUpController {
    private var panel: NSPanel?

    func show(model: AppModel) {
        if panel == nil {
            let p = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 340, height: 150),
                styleMask: [.nonactivatingPanel, .borderless],
                backing: .buffered, defer: false
            )
            p.level = .floating
            p.isFloatingPanel = true
            p.hidesOnDeactivate = false
            p.backgroundColor = .clear
            p.isOpaque = false
            p.hasShadow = true
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            let host = PanelHostingView(rootView: HeadsUpView(model: model))
            host.sizingOptions = [.preferredContentSize]
            p.contentView = host
            panel = p
        }
        guard let panel, let screen = NSScreen.main else { return }
        panel.setContentSize(panel.contentView?.fittingSize ?? NSSize(width: 340, height: 150))
        let frame = screen.visibleFrame
        panel.setFrameOrigin(NSPoint(x: frame.minX + 20, y: frame.minY + 20))
        panel.orderFrontRegardless()
    }

    func hide() { panel?.orderOut(nil) }
}

struct HeadsUpView: View {
    let model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "bell").font(.system(size: 11))
                Text("Heads-up · Sleepy").label(Theme.secondary, size: 8.5)
                Spacer()
                Button { model.dismissHeadsUp() } label: {
                    Image(systemName: "xmark").font(.system(size: 10, weight: .medium))
                        .frame(width: 18, height: 18).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.secondary)
                .accessibilityLabel("Close")
            }
            let time = Text(TimeFormat.countdown(seconds: model.engine.remainingSeconds))
                .font(.system(size: 15, weight: .light, design: .monospaced))
            let action = model.store.endAction
            let rest = Text(action.headsUpHint).foregroundStyle(Theme.secondary)
            Text("\(action.headsUpLead) \(time). \(rest)")
                .font(.system(size: 15))
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Button { model.extendFromHeadsUp() } label: { Label("Extend 10 min", systemImage: "plus") }
                    .buttonStyle(PillButtonStyle(kind: .accent))
                Button("Cancel") { model.stop() }
                    .buttonStyle(PillButtonStyle(kind: .outline))
            }
        }
        .foregroundStyle(.white)
        .padding(14)
        .frame(width: 300, alignment: .leading)
        .glassPane()
        .preferredColorScheme(.dark)
    }
}

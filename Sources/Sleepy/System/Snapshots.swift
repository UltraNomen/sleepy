import AppKit
import SwiftUI

/// Debug: `Sleepy -preview YES` opens the menu panel and heads-up card in their own
/// windows, side by side, so they can be checked without the menu bar.
@MainActor
enum Snapshots {
    private static var windows: [NSWindow] = []

    static func runIfRequested() {
        guard UserDefaults.standard.bool(forKey: "preview") else { return }
        let model = AppModel.shared
        model.engine.start(minutes: 45)

        func show<V: View>(_ name: String, _ view: V, x: CGFloat, y: CGFloat) {
            let host = NSHostingView(rootView: view)
            let size = host.fittingSize
            let w = NSWindow(contentRect: NSRect(x: x, y: y, width: size.width, height: size.height),
                             styleMask: [.borderless], backing: .buffered, defer: false)
            w.contentView = host
            w.isOpaque = false
            w.backgroundColor = .clear
            w.level = .floating
            w.orderFrontRegardless()
            windows.append(w)
            print("\(name) \(w.windowNumber)")
        }

        let origin = NSScreen.main?.visibleFrame.origin ?? .zero
        show("menu", MenuPanel(model: model).background(Color(white: 0.12)), x: origin.x + 40, y: origin.y + 40)
        show("heads-up", HeadsUpView(model: model).background(Color(white: 0.12)), x: origin.x + 360, y: origin.y + 40)
        fflush(stdout)
    }
}

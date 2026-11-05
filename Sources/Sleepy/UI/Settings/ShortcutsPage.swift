import SwiftUI

struct ShortcutsPage: View {
    private let rows: [(label: String, phrase: String)] = [
        ("Start timer", "Sleepy 45 minutes"),
        ("Start at a specific time", "Set Sleepy to sleep at a time"),
        ("Get timer status", "How much time left on Sleepy?"),
        ("Stop timer", "Stop the sleep timer in Sleepy"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PageHeader(title: "Siri & Shortcuts",
                       subtitle: "Four actions for Spotlight, Siri, Shortcuts and Focus automations.")
            ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                Button {
                    NSWorkspace.shared.open(URL(string: "shortcuts://")!)
                } label: {
                    HStack(spacing: 14) {
                        Text(String(format: "%02d", i + 1))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Theme.tertiary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.label).label(Theme.lavender, size: 8.5)
                            Text("“\(row.phrase)”").font(.system(size: 13, weight: .medium))
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.secondary)
                    }
                    .padding(.vertical, 11)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Open Shortcuts")
                Hairline()
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Also from Terminal, Raycast or Alfred").label(Theme.tertiary, size: 8.5)
                Text("open \"sleepy://start?minutes=45\"")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Theme.secondary)
                    .textSelection(.enabled)
            }
            .padding(.top, 16)
        }
    }
}

import SwiftUI

struct GeneralPage: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PageHeader(title: "General")
            row("Open at login", "Sleepy waits quietly in the menu bar.",
                isOn: Binding(get: { model.loginItem.isEnabled }, set: { model.loginItem.set($0) }))
            if let error = model.loginItem.lastError {
                Text(error).font(.system(size: 11)).foregroundStyle(.orange).padding(.bottom, 8)
            }
            Hairline()
            row("Show remaining time", "Countdown next to the moon in the menu bar.",
                isOn: Bindable(model.store).showRemaining)
            Hairline()
            row("Heads-up 10 min before", "A floating alert with Extend and Cancel.",
                isOn: Bindable(model.store).headsUp)
            Hairline()
            row("Desktop widget", "Countdown and quick starts on your desktop.",
                isOn: Binding(get: { model.store.desktopWidget }, set: {
                    model.store.desktopWidget = $0
                    model.applyDesktopWidget()
                }))
            Hairline()
            Text("Sleepy · open source · the app phones nothing home")
                .label(Theme.tertiary, size: 9)
                .padding(.top, 18)
        }
    }

    private func row(_ title: String, _ detail: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 13, weight: .medium))
                Text(detail).font(.system(size: 11.5)).foregroundStyle(Theme.secondary)
            }
            Spacer()
            SquareToggle(isOn: isOn)
        }
        .padding(.vertical, 13)
    }
}

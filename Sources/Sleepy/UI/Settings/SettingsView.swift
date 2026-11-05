import SleepyCore
import SwiftUI

struct SettingsView: View {
    static let windowID = "settings"
    @Bindable var model: AppModel

    var body: some View {
        HStack(spacing: 0) {
            Sidebar(model: model)
                .frame(width: 218)
            Group {
                switch model.settingsPage {
                case .general: GeneralPage(model: model)
                case .schedules: SchedulesPage(model: model)
                case .shortcuts: ShortcutsPage()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.top, 28)
            .padding(.horizontal, 28)
        }
        .background(Theme.ink.opacity(0.96))
        // Fills the title bar area too. This has to come before the frame, or the
        // content moves up and leaves a title-bar-tall strip along the bottom.
        .ignoresSafeArea()
        .frame(width: 720, height: 470)
        .preferredColorScheme(.dark)
    }
}

private struct Sidebar: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sleepy / Settings").label(Theme.tertiary, size: 8.5)
                .padding(.horizontal, 10)
                .padding(.top, 40)
                .padding(.bottom, 10)
            item("General", icon: "slider.horizontal.3", page: .general, key: "1")
            item("Schedules", icon: "calendar", page: .schedules, key: "2")
            item("Siri & Shortcuts", icon: "command", page: .shortcuts, key: "3")
            Spacer()
            Hairline().padding(.horizontal, 10)
            VStack(alignment: .leading, spacing: 5) {
                Text("Next").label(Theme.tertiary, size: 8.5)
                if let next = model.nextSchedule {
                    Text(next.schedule.name).font(.system(size: 12.5, weight: .medium))
                    Text(TimeFormat.dayAndTime(next.date, from: model.engine.now)).label(Theme.secondary, size: 8.5)
                } else {
                    Text("Nothing scheduled").font(.system(size: 12.5, weight: .medium))
                }
            }
            .padding(10)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background { DotGrain() }
        .glassEffect(.regular.tint(Color.white.opacity(0.03)), in: Rectangle())
        .overlay(alignment: .trailing) { Rectangle().fill(Theme.hairline).frame(width: 0.5) }
    }

    private func item(_ title: String, icon: String, page: SettingsPage, key: KeyEquivalent) -> some View {
        let selected = model.settingsPage == page
        return Button {
            model.settingsPage = page
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 12)).frame(width: 16)
                Text(title).font(.system(size: 12.5))
                Spacer()
            }
            .foregroundStyle(selected ? Color.white : Color.white.opacity(0.75))
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background { if selected { Capsule().fill(Color.white.opacity(0.13)) } }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .keyboardShortcut(key, modifiers: .command)
        .padding(.horizontal, 4)
    }
}

/// Page title and subtitle used by every settings page.
struct PageHeader<Trailing: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.system(size: 22, weight: .regular))
                if let subtitle {
                    Text(subtitle).font(.system(size: 12)).foregroundStyle(Theme.secondary)
                }
            }
            Spacer()
            trailing
        }
        .padding(.bottom, 14)
    }
}

extension PageHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}

import SleepyCore
import SwiftUI

/// The popover under the menu bar moon.
struct MenuPanel: View {
    @Bindable var model: AppModel
    @Environment(\.openWindow) private var openWindow

    private var engine: TimerEngine { model.engine }
    private static let presets = [15, 30, 45, 60, 90, 120]

    var body: some View {
        VStack(spacing: 0) {
            timerSection
            Hairline()
            endActionSection
            Hairline()
            presetsSection
            Hairline()
            sleepAtSection
            Hairline()
            nextScheduleSection
            Hairline()
            menuRows
        }
        .frame(width: 300)
        .glassPane()
        .preferredColorScheme(.dark)
    }

    // MARK: Sections

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Sleepy").label()
                Spacer()
                HStack(spacing: 6) {
                    Rectangle().fill(engine.isRunning ? Theme.accent : Theme.tertiary).frame(width: 5, height: 5)
                    Text(engine.isRunning ? "Running" : "Idle").label(engine.isRunning ? Theme.lavender : Theme.tertiary)
                }
            }
            .padding(.bottom, 14)

            DotMatrixText(
                text: TimeFormat.countdown(seconds: engine.isRunning ? engine.remainingSeconds : engine.selectedPreset * 60),
                color: engine.isRunning ? .white : .white.opacity(0.35)
            )
            .padding(.bottom, 10)

            Group {
                if let sleepDate = engine.sleepDate {
                    Text(model.store.endAction.endsAt(TimeFormat.clock(sleepDate)))
                } else {
                    Text("Pick a time below")
                }
            }
            .label()
            .padding(.bottom, 6)

            AsciiProgress(fraction: engine.progress)
                .padding(.bottom, 12)

            HStack(spacing: 6) {
                if engine.isRunning {
                    Button { engine.extend(minutes: 15) } label: { Label("15 min", systemImage: "plus") }
                        .buttonStyle(PillButtonStyle(kind: .outline))
                    Button("Stop timer") { model.stop() }
                        .buttonStyle(PillButtonStyle(kind: .filled))
                } else {
                    Button { engine.start(minutes: engine.selectedPreset) } label: {
                        Label("Start \(engine.selectedPreset) min", systemImage: "play.fill")
                    }
                    .buttonStyle(PillButtonStyle(kind: .filled))
                }
            }
        }
        .padding(14)
    }

    private var endActionSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("When time's up").label()
            EndActionSwitch(model: model)
            if model.shutdownBlocked {
                Text("Sleepy can't shut down. Allow System Events in System Settings → Privacy & Security → Automation. It will sleep instead.")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
    }

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(model.store.endAction.inLabel).label()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                ForEach(Self.presets, id: \.self) { m in
                    PresetPill(minutes: m, selected: engine.selectedPreset == m) { engine.start(minutes: m) }
                }
            }
            CustomTimeRow(engine: engine)
        }
        .padding(14)
    }

    private var sleepAtSection: some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 3) {
                Text(model.store.endAction.atLabel).label()
                Text(TimeFormat.until(model.sleepAtDate, from: engine.now)).label(Theme.tertiary)
            }
            .fixedSize()
            Spacer(minLength: 2)
            Button { step(-15) } label: { Image(systemName: "minus") }
                .buttonStyle(CircleButtonStyle())
                .accessibilityLabel("Earlier")
            DotMatrixText(
                text: String(format: "%02d:%02d", model.sleepAtMinutes / 60, model.sleepAtMinutes % 60),
                dot: 2.1, gap: 1.1
            )
            Button { step(15) } label: { Image(systemName: "plus") }
                .buttonStyle(CircleButtonStyle())
                .accessibilityLabel("Later")
            Button("Set") { engine.start(until: model.sleepAtDate) }
                .buttonStyle(PillButtonStyle(kind: .accent, height: 26))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var nextScheduleSection: some View {
        Button {
            openSettings(.schedules)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "calendar").font(.system(size: 13))
                VStack(alignment: .leading, spacing: 3) {
                    if let next = model.nextSchedule {
                        Text(next.schedule.name).font(.system(size: 12.5, weight: .medium))
                        Text("Next · \(TimeFormat.dayAndTime(next.date, from: engine.now)) · \(TimeFormat.duration(minutes: next.schedule.durationMinutes))")
                            .label(Theme.tertiary, size: 8.5)
                    } else {
                        Text("No schedule").font(.system(size: 12.5, weight: .medium))
                        Text("Add one in Schedules").label(Theme.tertiary, size: 8.5)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold)).foregroundStyle(Theme.secondary)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var menuRows: some View {
        VStack(spacing: 0) {
            menuRow("Schedules…", shortcut: "⌘S") { openSettings(.schedules) }
                .keyboardShortcut("s")
            menuRow("Settings…", shortcut: "⌘,") { openSettings(.general) }
                .keyboardShortcut(",")
            menuRow("Quit Sleepy", shortcut: "⌘Q") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
        .padding(.vertical, 6)
    }

    private func menuRow(_ title: String, shortcut: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                Text(shortcut).font(.system(size: 11, design: .monospaced)).foregroundStyle(Theme.tertiary)
            }
        }
        .buttonStyle(MenuRowStyle())
    }

    // MARK: Actions

    private func step(_ minutes: Int) {
        model.sleepAtMinutes = (model.sleepAtMinutes + minutes + 24 * 60) % (24 * 60)
    }

    private func openSettings(_ page: SettingsPage) {
        model.settingsPage = page
        openWindow(id: SettingsView.windowID)
        NSApp.activate()
    }
}

private struct PresetPill: View {
    let minutes: Int
    let selected: Bool
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(minutes)").font(.system(size: 15, weight: .light, design: .monospaced))
                Text("min").label(selected ? .black.opacity(0.7) : Theme.secondary, size: 7.5)
            }
            .foregroundStyle(selected ? Color.black : Color.white)
            .frame(maxWidth: .infinity, minHeight: 32)
            .background {
                if selected {
                    Capsule().fill(Color.white)
                } else {
                    Capsule().fill(Color.white.opacity(hover ? 0.1 : 0.04))
                        .glassEffect(.regular, in: Capsule())
                        .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: 0.5))
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .accessibilityLabel("\(minutes) minutes")
    }
}

/// Picks what happens at zero. `compact` shows icons only, for the desktop widget.
struct EndActionSwitch: View {
    let model: AppModel
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 3 : 5) {
            ForEach(EndAction.allCases) { action in
                let selected = model.store.endAction == action
                Button { model.setEndAction(action) } label: {
                    Group {
                        if compact {
                            Image(systemName: action.symbol)
                                .font(.system(size: 9, weight: .semibold))
                                .frame(width: 20, height: 20)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: action.symbol).font(.system(size: 10, weight: .semibold))
                                Text(action.title).font(.system(size: 11, weight: .medium)).lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, minHeight: 28)
                        }
                    }
                    .foregroundStyle(selected ? Color.black : Color.white.opacity(0.8))
                    .background {
                        Capsule().fill(selected ? Color.white : Color.white.opacity(0.05))
                        if !selected { Capsule().strokeBorder(Theme.hairline, lineWidth: 0.5) }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .help(action.title)
                .accessibilityLabel(action.title)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }
}

/// Any length, typed as "75", "1:30" or "1h 30m".
private struct CustomTimeRow: View {
    let engine: TimerEngine
    @AppStorage("customTime") private var text = "75"

    private var minutes: Int? { TimeFormat.parseDuration(text) }

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 8) {
                TextField("Custom time", text: $text, prompt: Text("1h 30m"))
                    .textFieldStyle(.plain)
                    .labelsHidden()
                    .font(.system(size: 13, design: .monospaced))
                    .onSubmit(start)
                Text(minutes.map(TimeFormat.duration(minutes:)) ?? "1 min to 24 h")
                    .label(minutes == nil ? .orange : Theme.secondary, size: 7.5)
                    .fixedSize()
            }
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(Capsule().fill(Color.white.opacity(0.04)))
            .overlay(Capsule().strokeBorder(minutes == nil ? Color.orange.opacity(0.7) : Theme.hairline, lineWidth: 0.5))
            .help("Type minutes, or a length like 1:30 or 1h 30m")
            Button("Start", action: start)
                .buttonStyle(PillButtonStyle(kind: .outline, height: 30))
                .disabled(minutes == nil)
                .opacity(minutes == nil ? 0.4 : 1)
        }
    }

    private func start() {
        if let minutes { engine.start(minutes: minutes) }
    }
}

/// Menu bar label: moon plus the time left while running.
struct MenuBarLabel: View {
    let model: AppModel

    var body: some View {
        let engine = model.engine
        if engine.isRunning && model.store.showRemaining {
            Text("\(Image(nsImage: MoonIcon.menuBar)) \(TimeFormat.countdown(seconds: engine.remainingSeconds))")
                .monospacedDigit()
        } else {
            Image(nsImage: MoonIcon.menuBar)
        }
    }
}

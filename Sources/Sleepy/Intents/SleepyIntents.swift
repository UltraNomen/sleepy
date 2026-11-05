import AppIntents
import SleepyCore

// These actions are what Spotlight, Siri and Shortcuts use. macOS only lists them
// for a build that includes App Intents metadata, which Xcode generates; see README.

/// Preset lengths, so the Spotlight phrase "Sleepy 45 minutes" can carry the length.
enum SleepLength: Int, AppEnum {
    case m15 = 15, m30 = 30, m45 = 45, m60 = 60, m90 = 90, m120 = 120

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Sleep length"
    static let caseDisplayRepresentations: [SleepLength: DisplayRepresentation] = [
        .m15: "15 minutes", .m30: "30 minutes", .m45: "45 minutes",
        .m60: "60 minutes", .m90: "90 minutes", .m120: "120 minutes",
    ]
}

struct StartSleepPresetIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Sleep Timer"
    static let description = IntentDescription("Put the Mac to sleep after a preset length.")

    @Parameter(title: "Length", default: .m45) var length: SleepLength

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        AppModel.shared.engine.start(minutes: length.rawValue)
        return .result(dialog: "\(AppModel.shared.store.endAction.spokenIn(minutes: length.rawValue))")
    }
}

struct StartSleepTimerIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Sleep Timer (Minutes)"
    static let description = IntentDescription("Put the Mac to sleep after any number of minutes.")

    @Parameter(title: "Minutes", default: 45, inclusiveRange: (1, 1440)) var minutes: Int

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        AppModel.shared.engine.start(minutes: minutes)
        return .result(dialog: "\(AppModel.shared.store.endAction.spokenIn(minutes: minutes))")
    }
}

struct SleepAtIntent: AppIntent {
    static let title: LocalizedStringResource = "Sleep at Time"
    static let description = IntentDescription("Put the Mac to sleep at a time of day.")

    @Parameter(title: "Time", kind: .time) var time: Date

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let c = Calendar.current.dateComponents([.hour, .minute], from: time)
        AppModel.shared.run(.at(hour: c.hour ?? 0, minute: c.minute ?? 0))
        let at = TimeFormat.clock(AppModel.shared.sleepAtDate)
        return .result(dialog: "\(AppModel.shared.store.endAction.spokenAt(at))")
    }
}

struct TimerStatusIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Sleep Timer Status"

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
        let engine = AppModel.shared.engine
        guard engine.isRunning else { return .result(value: 0, dialog: "No sleep timer is running.") }
        let minutes = Int((Double(engine.remainingSeconds) / 60).rounded(.up))
        return .result(value: minutes, dialog: "\(minutes) minutes left on the timer.")
    }
}

struct StopTimerIntent: AppIntent {
    static let title: LocalizedStringResource = "Stop Sleep Timer"

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        AppModel.shared.stop()
        return .result(dialog: "Sleep timer stopped.")
    }
}

struct SleepyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartSleepPresetIntent(),
            phrases: [
                "\(.applicationName) \(\.$length)",
                "Start a \(\.$length) timer in \(.applicationName)",
                "Start a sleep timer in \(.applicationName)",
            ],
            shortTitle: "Start Timer",
            systemImageName: "moon"
        )
        AppShortcut(
            intent: SleepAtIntent(),
            phrases: ["Set \(.applicationName) to sleep at a time"],
            shortTitle: "Sleep At",
            systemImageName: "clock"
        )
        AppShortcut(
            intent: TimerStatusIntent(),
            phrases: ["How much time left on \(.applicationName)?"],
            shortTitle: "Time Left",
            systemImageName: "hourglass"
        )
        AppShortcut(
            intent: StopTimerIntent(),
            phrases: ["Stop the sleep timer in \(.applicationName)", "Stop \(.applicationName)"],
            shortTitle: "Stop Timer",
            systemImageName: "stop.circle"
        )
    }
}

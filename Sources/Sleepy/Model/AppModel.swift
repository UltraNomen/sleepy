import AppKit
import Observation
import SleepyCore

enum SettingsPage: Hashable { case general, schedules, shortcuts }

/// Shared state for the whole app, also reached by App Intents and URL commands.
@MainActor
@Observable
final class AppModel {
    static let shared = AppModel()

    let engine = TimerEngine()
    let store = Store()
    let loginItem = LoginItem()
    var settingsPage: SettingsPage = .general
    /// Time picked in the SLEEP AT row, minutes since midnight.
    var sleepAtMinutes = 23 * 60 + 30
    /// Shut Down is selected but macOS refused the permission it needs.
    var shutdownBlocked = false

    private let headsUp = HeadsUpController()
    private let widget = DesktopWidgetController()
    private var lastScheduleCheck = Date()

    private init() {
        engine.onHeadsUp = { [weak self] in
            guard let self, self.store.headsUp else { return }
            self.headsUp.show(model: self)
        }
        engine.onExpire = { [weak self] in
            guard let self else { return }
            self.headsUp.hide()
            SleepController.perform(self.store.endAction)
        }
        engine.onTick = { [weak self] now in self?.checkSchedules(now: now) }
    }

    var nextSchedule: (schedule: Schedule, date: Date)? { store.schedules.next(after: engine.now) }

    var sleepAtDate: Date {
        TimeFormat.nextDate(hour: sleepAtMinutes / 60, minute: sleepAtMinutes % 60, after: engine.now)
    }

    func run(_ command: URLCommand) {
        switch command {
        case .start(let m): engine.start(minutes: m)
        case .extend(let m): engine.extend(minutes: m)
        case .stop: stop()
        case .at(let h, let m):
            sleepAtMinutes = h * 60 + m
            engine.start(until: sleepAtDate)
        }
    }

    func stop() {
        engine.stop()
        headsUp.hide()
    }

    func extendFromHeadsUp() {
        engine.extend(minutes: 10)
        headsUp.hide()
    }

    func dismissHeadsUp() { headsUp.hide() }

    /// Picking Shut Down asks for its permission now, rather than when the timer ends.
    func setEndAction(_ action: EndAction) {
        store.endAction = action
        shutdownBlocked = false
        guard action == .shutdown else { return }
        Task {
            let allowed = await SleepController.canShutDown()
            if store.endAction == .shutdown { shutdownBlocked = !allowed }
        }
    }

    /// Shows or hides the desktop widget to match the setting.
    func applyDesktopWidget() {
        if store.desktopWidget { widget.show(model: self) } else { widget.hide() }
    }

    /// Starts a schedule's timer when its start time passes. Only runs while the app is open.
    private func checkSchedules(now: Date) {
        defer { lastScheduleCheck = now }
        // After a long gap (Mac was asleep) skip missed starts instead of firing them on wake.
        guard now.timeIntervalSince(lastScheduleCheck) < 30, !engine.isRunning else { return }
        for s in store.schedules where s.enabled {
            if let due = s.nextOccurrence(after: lastScheduleCheck), due <= now {
                engine.start(minutes: s.durationMinutes)
                return
            }
        }
    }
}

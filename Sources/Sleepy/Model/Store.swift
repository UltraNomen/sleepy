import Foundation
import Observation
import SleepyCore

/// Schedules and settings, saved to UserDefaults.
@MainActor
@Observable
final class Store {
    private let defaults: UserDefaults

    var schedules: [Schedule] { didSet { save() } }
    var showRemaining: Bool { didSet { defaults.set(showRemaining, forKey: Keys.showRemaining) } }
    var headsUp: Bool { didSet { defaults.set(headsUp, forKey: Keys.headsUp) } }
    var desktopWidget: Bool { didSet { defaults.set(desktopWidget, forKey: Keys.desktopWidget) } }

    private enum Keys {
        static let schedules = "schedules"
        static let showRemaining = "showRemaining"
        static let headsUp = "headsUp"
        static let desktopWidget = "desktopWidget"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [Keys.showRemaining: true, Keys.headsUp: true, Keys.desktopWidget: true])
        showRemaining = defaults.bool(forKey: Keys.showRemaining)
        headsUp = defaults.bool(forKey: Keys.headsUp)
        desktopWidget = defaults.bool(forKey: Keys.desktopWidget)
        if let data = defaults.data(forKey: Keys.schedules),
           let saved = try? JSONDecoder().decode([Schedule].self, from: data) {
            schedules = saved
        } else {
            schedules = Schedule.defaults
        }
    }


    func addSchedule() -> Schedule {
        let s = Schedule(name: "New schedule", hour: 23, minute: 0, durationMinutes: 60,
                         weekdays: Set(Weekday.allCases))
        schedules.append(s)
        return s
    }

    func delete(_ id: Schedule.ID) {
        schedules.removeAll { $0.id == id }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(schedules) {
            defaults.set(data, forKey: Keys.schedules)
        }
    }
}

import Foundation

/// Monday-first weekday, matching the M T W T F S S chips in the UI.
public enum Weekday: Int, Codable, CaseIterable, Hashable, Sendable {
    case mon = 1, tue, wed, thu, fri, sat, sun

    public var letter: String {
        switch self {
        case .mon: "M"
        case .tue: "T"
        case .wed: "W"
        case .thu: "T"
        case .fri: "F"
        case .sat: "S"
        case .sun: "S"
        }
    }

    public var shortName: String {
        switch self {
        case .mon: "MON"
        case .tue: "TUE"
        case .wed: "WED"
        case .thu: "THU"
        case .fri: "FRI"
        case .sat: "SAT"
        case .sun: "SUN"
        }
    }

    /// Converts Foundation's weekday (1 = Sunday) to a Monday-first weekday.
    public init(calendarWeekday: Int) {
        self = Weekday(rawValue: calendarWeekday == 1 ? 7 : calendarWeekday - 1)!
    }
}

public struct Schedule: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var hour: Int
    public var minute: Int
    public var durationMinutes: Int
    public var weekdays: Set<Weekday>
    public var enabled: Bool

    public init(
        id: UUID = UUID(), name: String, hour: Int, minute: Int,
        durationMinutes: Int, weekdays: Set<Weekday>, enabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.hour = hour
        self.minute = minute
        self.durationMinutes = durationMinutes
        self.weekdays = weekdays
        self.enabled = enabled
    }

    public static let defaults: [Schedule] = [
        Schedule(name: "Weeknights", hour: 23, minute: 0, durationMinutes: 60,
                 weekdays: [.mon, .tue, .wed, .thu]),
        Schedule(name: "Friday film", hour: 23, minute: 45, durationMinutes: 120,
                 weekdays: [.fri]),
        Schedule(name: "Weekend", hour: 0, minute: 30, durationMinutes: 90,
                 weekdays: [.sat, .sun], enabled: false),
    ]

    /// "23:00"
    public var timeLabel: String { String(format: "%02d:%02d", hour, minute) }

    /// "23:00 · 1 H 30 MIN"
    public var summary: String { "\(timeLabel) · \(TimeFormat.duration(minutes: durationMinutes))" }

    /// The first start strictly after `date` on one of the schedule's weekdays.
    /// The weekday is the day the start time falls on (so "Weekend 00:30" fires early Saturday).
    public func nextOccurrence(after date: Date, calendar: Calendar = .current) -> Date? {
        guard !weekdays.isEmpty else { return nil }
        let startOfDay = calendar.startOfDay(for: date)
        for offset in 0...7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfDay),
                  let candidate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
            else { continue }
            let weekday = Weekday(calendarWeekday: calendar.component(.weekday, from: candidate))
            if candidate > date && weekdays.contains(weekday) {
                return candidate
            }
        }
        return nil
    }
}

public extension Array where Element == Schedule {
    /// The soonest enabled schedule after `date`.
    func next(after date: Date, calendar: Calendar = .current) -> (schedule: Schedule, date: Date)? {
        self.filter(\.enabled)
            .compactMap { s in s.nextOccurrence(after: date, calendar: calendar).map { (s, $0) } }
            .min { $0.1 < $1.1 }
    }
}

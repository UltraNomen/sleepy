import Foundation

public enum TimeFormat {
    /// "44:02" under an hour, "1:30:00" above.
    public static func countdown(seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, sec)
            : String(format: "%02d:%02d", m, sec)
    }

    /// "1 H", "1 H 30 MIN", "45 MIN"
    public static func duration(minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        switch (h, m) {
        case (0, _): return "\(m) MIN"
        case (_, 0): return "\(h) H"
        default: return "\(h) H \(m) MIN"
        }
    }

    /// Short, one-line distance label: "IN 19H10", "IN 45 MIN", "NOW".
    public static func until(_ target: Date, from now: Date) -> String {
        let total = Int((target.timeIntervalSince(now) / 60).rounded(.up))
        if total <= 0 { return "NOW" }
        let h = total / 60, m = total % 60
        return h > 0 ? String(format: "IN %dH%02d", h, m) : "IN \(m) MIN"
    }

    /// Reads a typed length as minutes: "75", "75 min", "1:30", "1h", "1h 30m".
    /// Nil if it can't be read or is outside 1 minute to 24 hours.
    public static func parseDuration(_ text: String) -> Int? {
        let t = text.lowercased().filter { !$0.isWhitespace }
        func number(_ s: Substring) -> Int? {
            s.allSatisfy(\.isNumber) ? Int(s) : nil
        }
        func stripMinuteUnit(_ s: Substring) -> Substring {
            for unit in ["minutes", "minute", "mins", "min", "m"] where s.hasSuffix(unit) {
                return s.dropLast(unit.count)
            }
            return s
        }
        var hours = 0, minutes = 0
        if let colon = t.firstIndex(of: ":") {
            guard let h = number(t[..<colon]), let m = number(t[t.index(after: colon)...]), m < 60 else { return nil }
            hours = h; minutes = m
        } else if let h = t.firstIndex(of: "h") {
            guard let hh = number(t[..<h]) else { return nil }
            var rest = t[t.index(after: h)...]
            for unit in ["ours", "our", "rs", "r"] where rest.hasPrefix(unit) {
                rest = rest.dropFirst(unit.count)
                break
            }
            rest = stripMinuteUnit(rest)
            hours = hh
            if !rest.isEmpty {
                guard let m = number(rest) else { return nil }
                minutes = m
            }
        } else {
            guard let m = number(stripMinuteUnit(t[...])) else { return nil }
            minutes = m
        }
        let (fromHours, overflow) = hours.multipliedReportingOverflow(by: 60)
        guard !overflow else { return nil }
        let total = fromHours &+ minutes
        return (1...URLCommand.maxMinutes).contains(total) ? total : nil
    }

    /// "05:05"
    public static func clock(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
    }

    /// "TONIGHT 23:00", "TODAY 14:00", "TOMORROW 00:30", "FRI 23:45"
    public static func dayAndTime(_ date: Date, from now: Date, calendar: Calendar = .current) -> String {
        let time = clock(date, calendar: calendar)
        if calendar.isDate(date, inSameDayAs: now) {
            return (calendar.component(.hour, from: date) >= 18 ? "TONIGHT " : "TODAY ") + time
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, inSameDayAs: tomorrow) {
            return "TOMORROW " + time
        }
        let wd = Weekday(calendarWeekday: calendar.component(.weekday, from: date))
        return "\(wd.shortName) \(time)"
    }

    /// The next time the clock reads hour:minute, strictly after `now`.
    public static func nextDate(hour: Int, minute: Int, after now: Date, calendar: Calendar = .current) -> Date {
        let today = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now)!
        return today > now ? today : calendar.date(byAdding: .day, value: 1, to: today)!
    }

    /// "[▓▓▓░░░░░░░░░]" with `cells` cells.
    public static func asciiBar(fraction: Double, cells: Int = 24) -> (filled: String, empty: String) {
        let f = min(1, max(0, fraction))
        let n = Int((f * Double(cells)).rounded())
        return (String(repeating: "▓", count: n), String(repeating: "░", count: cells - n))
    }
}

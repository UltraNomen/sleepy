import Foundation
import Testing
@testable import SleepyCore

private var cal: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC")!
    return c
}()

/// 2026-11-05 is a Thursday.
private func date(_ d: Int, _ h: Int, _ m: Int, month: Int = 11) -> Date {
    cal.date(from: DateComponents(year: 2026, month: month, day: d, hour: h, minute: m))!
}

@Suite struct ScheduleTests {
    @Test func weeknightsTonight() {
        let s = Schedule.defaults[0]
        #expect(s.nextOccurrence(after: date(5, 4, 20), calendar: cal) == date(5, 23, 0))
    }

    @Test func weeknightsSkipsFridayToMonday() {
        let s = Schedule.defaults[0]
        // Thursday 23:30 → next is Monday 9 Nov 23:00
        #expect(s.nextOccurrence(after: date(5, 23, 30), calendar: cal) == date(9, 23, 0))
    }

    @Test func pastMidnightWeekend() {
        let s = Schedule.defaults[2]
        // Friday 23:00 → Saturday 00:30
        #expect(s.nextOccurrence(after: date(6, 23, 0), calendar: cal) == date(7, 0, 30))
    }

    @Test func exactTimeIsNotNext() {
        let s = Schedule.defaults[1]
        #expect(s.nextOccurrence(after: date(6, 23, 45), calendar: cal) == date(13, 23, 45))
    }

    @Test func emptyWeekdays() {
        let s = Schedule(name: "x", hour: 1, minute: 0, durationMinutes: 10, weekdays: [])
        #expect(s.nextOccurrence(after: date(5, 0, 0), calendar: cal) == nil)
    }

    @Test func nextAcrossSchedulesIgnoresDisabled() {
        let next = Schedule.defaults.next(after: date(6, 23, 50), calendar: cal)
        // Weekend is disabled, so after Friday 23:50 the next is Monday weeknights.
        #expect(next?.schedule.name == "Weeknights")
        #expect(next?.date == date(9, 23, 0))
    }
}

@Suite struct FormatTests {
    @Test func untilLabel() {
        #expect(TimeFormat.until(date(5, 23, 30), from: date(5, 4, 20)) == "IN 19H10")
        #expect(TimeFormat.until(date(5, 5, 5), from: date(5, 4, 20)) == "IN 45 MIN")
        #expect(TimeFormat.until(date(5, 4, 20), from: date(5, 4, 20)) == "NOW")
    }

    @Test func countdown() {
        #expect(TimeFormat.countdown(seconds: 44 * 60 + 2) == "44:02")
        #expect(TimeFormat.countdown(seconds: 5400) == "1:30:00")
        #expect(TimeFormat.countdown(seconds: -3) == "00:00")
    }

    @Test func duration() {
        #expect(TimeFormat.duration(minutes: 60) == "1 H")
        #expect(TimeFormat.duration(minutes: 90) == "1 H 30 MIN")
        #expect(TimeFormat.duration(minutes: 45) == "45 MIN")
    }

    @Test func dayAndTime() {
        #expect(TimeFormat.dayAndTime(date(5, 23, 0), from: date(5, 4, 20), calendar: cal) == "TONIGHT 23:00")
        #expect(TimeFormat.dayAndTime(date(6, 0, 30), from: date(5, 23, 0), calendar: cal) == "TOMORROW 00:30")
        #expect(TimeFormat.dayAndTime(date(9, 23, 0), from: date(5, 23, 30), calendar: cal) == "MON 23:00")
    }

    @Test func nextClockDate() {
        #expect(TimeFormat.nextDate(hour: 23, minute: 30, after: date(5, 4, 20), calendar: cal) == date(5, 23, 30))
        #expect(TimeFormat.nextDate(hour: 1, minute: 0, after: date(5, 4, 20), calendar: cal) == date(6, 1, 0))
    }

    @Test func parseDuration() {
        let good: [(String, Int)] = [
            ("75", 75), (" 75 ", 75), ("75m", 75), ("75 min", 75), ("90 minutes", 90),
            ("1:30", 90), ("1h", 60), ("1h30", 90), ("1h 30m", 90), ("2 hours", 120),
            ("2 hours 5 mins", 125), ("24h", 1440), ("0:45", 45),
        ]
        for (text, minutes) in good { #expect(TimeFormat.parseDuration(text) == minutes, "\(text)") }
        for bad in ["", "0", "abc", "-5", "1:75", "25h", "1441", "1h2x", "h", ":", "1.5",
                    "99999999999999999999", "9999999999999999h"] {
            #expect(TimeFormat.parseDuration(bad) == nil, "\(bad)")
        }
    }

    @Test func asciiBar() {
        let bar = TimeFormat.asciiBar(fraction: 0.5, cells: 10)
        #expect(bar.filled.count == 5 && bar.empty.count == 5)
    }
}

@Suite struct MoonDotsTests {
    @Test func crescentOpensUpperRight() {
        for grid in [9, 11, 19] {
            let cells = MoonDots.cells(grid: grid)
            let has = { (col: Int, row: Int) in cells.contains { $0.col == col && $0.row == row } }
            let mid = grid / 2
            #expect(has(0, mid), "left edge lit at \(grid)")
            #expect(has(mid, grid - 1), "bottom edge lit at \(grid)")
            #expect(!has(mid, mid), "bite removes the centre at \(grid)")
            #expect(!has(grid - 1, 0), "corner empty at \(grid)")
            #expect(cells.allSatisfy { (0..<grid).contains($0.col) && (0..<grid).contains($0.row) })
        }
    }
}

@Suite struct URLCommandTests {
    @Test func parses() {
        #expect(URLCommand(url: URL(string: "sleepy://start?minutes=45")!) == .start(minutes: 45))
        #expect(URLCommand(url: URL(string: "sleepy://start")!) == .start(minutes: 45))
        #expect(URLCommand(url: URL(string: "sleepy://extend?m=5")!) == .extend(minutes: 5))
        #expect(URLCommand(url: URL(string: "sleepy://stop")!) == .stop)
        #expect(URLCommand(url: URL(string: "SLEEPY://Cancel")!) == .stop)
        #expect(URLCommand(url: URL(string: "sleepy://at?time=23:30")!) == .at(hour: 23, minute: 30))
    }

    @Test func rejects() {
        #expect(URLCommand(url: URL(string: "sleepy://start?minutes=0")!) == nil)
        #expect(URLCommand(url: URL(string: "sleepy://start?minutes=abc")!) == nil)
        #expect(URLCommand(url: URL(string: "sleepy://start?minutes=99999")!) == nil)
        #expect(URLCommand(url: URL(string: "sleepy://at?time=25:00")!) == nil)
        #expect(URLCommand(url: URL(string: "sleepy://reboot")!) == nil)
        #expect(URLCommand(url: URL(string: "https://start?minutes=5")!) == nil)
    }
}

import Foundation
import Observation
import SleepyCore

/// The single sleep timer every surface reads from: menu bar, popover, heads-up card, intents.
@MainActor
@Observable
final class TimerEngine {
    static let headsUpLead: TimeInterval = 10 * 60

    /// Seconds left; nil when idle.
    private(set) var remaining: TimeInterval?
    /// Length of the current run including extensions, for the progress bar.
    private(set) var total: TimeInterval = 0
    /// Last preset picked, highlighted in the SLEEP IN grid.
    var selectedPreset: Int = 45
    /// Wall clock, refreshed every tick so time labels stay current.
    private(set) var now = Date()

    /// Called once per run when the timer drops under ten minutes.
    var onHeadsUp: (() -> Void)?
    /// Called when the timer reaches zero.
    var onExpire: (() -> Void)?
    /// Called on every tick with the real wall clock (for schedules).
    var onTick: ((Date) -> Void)?

    /// Debug: `-demoSpeed 60` runs the timer 60× faster.
    private let speed: Double
    private var headsUpFired = false
    private var lastTick = Date()
    private var timer: Timer?

    init(speed: Double = max(1, UserDefaults.standard.double(forKey: "demoSpeed"))) {
        self.speed = speed
        let t = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    var isRunning: Bool { remaining != nil }
    var remainingSeconds: Int { Int((remaining ?? 0).rounded(.up)) }
    var progress: Double { total > 0 ? 1 - (remaining ?? 0) / total : 0 }

    /// When the Mac will sleep, on the wall clock.
    var sleepDate: Date? { remaining.map { now.addingTimeInterval($0 / speed) } }

    func start(minutes: Int) {
        selectedPreset = minutes
        start(seconds: TimeInterval(minutes * 60))
    }

    func start(until date: Date) {
        start(seconds: max(1, date.timeIntervalSince(Date())) * speed)
    }

    func extend(minutes: Int) {
        guard let r = remaining else { return start(minutes: minutes) }
        let add = TimeInterval(minutes * 60)
        remaining = r + add
        total += add
        if r + add > Self.headsUpLead { headsUpFired = false }
    }

    func stop() {
        remaining = nil
        total = 0
        headsUpFired = false
    }

    private func start(seconds: TimeInterval) {
        remaining = seconds
        total = seconds
        headsUpFired = seconds <= Self.headsUpLead
        lastTick = Date()
    }

    private func tick() {
        let wall = Date()
        let delta = wall.timeIntervalSince(lastTick)
        lastTick = wall
        now = wall
        onTick?(wall)

        guard let r = remaining else { return }
        let next = r - delta * speed
        if next <= 0 {
            remaining = nil
            total = 0
            // A gap this long means the Mac was already asleep or the app was suspended.
            // Don't put a just-woken Mac straight back to sleep.
            if delta < 30 { onExpire?() }
            return
        }
        remaining = next
        if !headsUpFired && next <= Self.headsUpLead {
            headsUpFired = true
            onHeadsUp?()
        }
    }
}

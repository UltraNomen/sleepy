import Foundation

/// What Sleepy does when the timer reaches zero.
public enum EndAction: String, CaseIterable, Codable, Identifiable, Sendable {
    case sleep, shutdown, stopMedia

    public var id: Self { self }

    public var title: String {
        switch self {
        case .sleep: "Sleep"
        case .shutdown: "Shut down"
        case .stopMedia: "Stop media"
        }
    }

    /// SF Symbol name.
    public var symbol: String {
        switch self {
        case .sleep: "moon"
        case .shutdown: "power"
        case .stopMedia: "pause"
        }
    }

    /// "Mac sleeps at 05:05"
    public func endsAt(_ time: String) -> String {
        switch self {
        case .sleep: "Mac sleeps at \(time)"
        case .shutdown: "Mac shuts down at \(time)"
        case .stopMedia: "Media stops at \(time)"
        }
    }

    /// Heading for the length presets. Short enough for the panel's tight rows.
    public var inLabel: String {
        switch self {
        case .sleep: "Sleep in"
        case .shutdown: "Off in"
        case .stopMedia: "Stop in"
        }
    }

    /// Heading for the time-of-day row.
    public var atLabel: String {
        switch self {
        case .sleep: "Sleep at"
        case .shutdown: "Off at"
        case .stopMedia: "Stop at"
        }
    }

    /// Start of the heads-up sentence, followed by the time left.
    public var headsUpLead: String {
        switch self {
        case .sleep: "Your Mac will sleep in"
        case .shutdown: "Your Mac will shut down in"
        case .stopMedia: "Your media will stop in"
        }
    }

    public var headsUpHint: String {
        self == .stopMedia ? "Your Mac stays on." : "Save what matters."
    }

    /// "Your Mac will sleep in 45 minutes."
    public func spokenIn(minutes: Int) -> String {
        "\(headsUpLead) \(minutes) minutes."
    }

    /// "Your Mac will sleep at 23:30."
    public func spokenAt(_ time: String) -> String {
        "\(headsUpLead.replacingOccurrences(of: " in", with: " at")) \(time)."
    }
}

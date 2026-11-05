import Foundation

/// Commands accepted on the `sleepy://` URL scheme.
///
///     sleepy://start?minutes=45
///     sleepy://extend?minutes=10
///     sleepy://at?time=23:30
///     sleepy://stop
public enum URLCommand: Equatable, Sendable {
    case start(minutes: Int)
    case extend(minutes: Int)
    case at(hour: Int, minute: Int)
    case stop

    public static let maxMinutes = 24 * 60

    public init?(url: URL) {
        guard url.scheme?.lowercased() == "sleepy",
              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return nil }
        let action = (comps.host ?? comps.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))).lowercased()
        let query = Dictionary(
            (comps.queryItems ?? []).compactMap { item in item.value.map { (item.name.lowercased(), $0) } },
            uniquingKeysWith: { a, _ in a }
        )
        func minutes(default d: Int?) -> Int? {
            guard let raw = query["minutes"] ?? query["m"] else { return d }
            guard let m = Int(raw), m > 0, m <= Self.maxMinutes else { return nil }
            return m
        }
        switch action {
        case "start":
            guard let m = minutes(default: 45) else { return nil }
            self = .start(minutes: m)
        case "extend":
            guard let m = minutes(default: 10) else { return nil }
            self = .extend(minutes: m)
        case "stop", "cancel":
            self = .stop
        case "at":
            let parts = (query["time"] ?? "").split(separator: ":").compactMap { Int($0) }
            guard parts.count == 2, (0..<24).contains(parts[0]), (0..<60).contains(parts[1]) else { return nil }
            self = .at(hour: parts[0], minute: parts[1])
        default:
            return nil
        }
    }
}

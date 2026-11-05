import AppKit
import os

/// Pauses whatever is playing, then puts the Mac to sleep.
enum SleepController {
    private static let log = Logger(subsystem: "dev.sleepy.Sleepy", category: "sleep")

    /// Players that answer a plain AppleScript `pause`.
    private static let players: [(bundleID: String, name: String)] = [
        ("com.apple.Music", "Music"),
        ("com.apple.TV", "TV"),
        ("com.spotify.client", "Spotify"),
        ("com.apple.podcasts", "Podcasts"),
    ]

    /// `-dryRun YES` logs instead of sleeping, for testing.
    static var dryRun: Bool { UserDefaults.standard.bool(forKey: "dryRun") }

    @MainActor
    static func sleepNow() {
        pausePlayback()
        if dryRun {
            log.notice("dry run: would sleep now")
            NSSound.beep()
            return
        }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        p.arguments = ["sleepnow"]
        do { try p.run() } catch { log.error("pmset failed: \(error.localizedDescription)") }
    }

    @MainActor
    static func pausePlayback() {
        let running = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
        for player in players where running.contains(player.bundleID) {
            var err: NSDictionary?
            NSAppleScript(source: "tell application id \"\(player.bundleID)\" to pause")?
                .executeAndReturnError(&err)
            if let err { log.error("pause \(player.name) failed: \(err)") }
        }
        let qt = "com.apple.QuickTimePlayerX"
        if running.contains(qt) {
            var err: NSDictionary?
            NSAppleScript(source: "tell application id \"\(qt)\" to pause every document")?
                .executeAndReturnError(&err)
        }
    }
}

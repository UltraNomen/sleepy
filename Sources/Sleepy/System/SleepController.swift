import AppKit
import SleepyCore
import os

/// Runs the end-of-timer action. Everything happens off the main thread with a
/// timeout, so a macOS permission prompt nobody answers can't stop the Mac sleeping.
enum SleepController {
    private static let log = Logger(subsystem: "dev.sleepy.Sleepy", category: "sleep")
    private static let osascript = "/usr/bin/osascript"
    private static let shutdownScript = "tell application \"System Events\" to shut down"

    /// Players and the AppleScript command that stops each one.
    private static let players: [(bundleID: String, command: String)] = [
        ("com.apple.Music", "pause"),
        ("com.apple.TV", "pause"),
        ("com.spotify.client", "pause"),
        ("com.apple.podcasts", "pause"),
        ("com.apple.QuickTimePlayerX", "pause every document"),
        ("org.videolan.vlc", "stop"),
    ]

    /// `-dryRun YES` logs instead of sleeping or shutting down, for testing.
    static var dryRun: Bool { UserDefaults.standard.bool(forKey: "dryRun") }

    static func perform(_ action: EndAction) {
        Task.detached {
            await stopMedia()
            guard !dryRun else {
                log.notice("dry run: would \(action.rawValue, privacy: .public) now")
                await MainActor.run { NSSound.beep() }
                return
            }
            switch action {
            case .sleep:
                await sleep()
            case .shutdown:
                let status = await exec(osascript, ["-e", shutdownScript], timeout: 10)
                if status != 0 {
                    // Permission was refused: sleeping beats leaving the Mac running all night.
                    log.error("shutdown failed (\(status)), sleeping instead")
                    await sleep()
                }
            case .stopMedia:
                break
            }
        }
    }

    /// Triggers the macOS permission prompt for System Events while someone is
    /// there to answer it. Returns false if shutting down isn't allowed.
    static func canShutDown() async -> Bool {
        if dryRun { return true }
        return await exec(osascript, ["-e", "tell application \"System Events\" to get name"], timeout: 120) == 0
    }

    private static func sleep() async {
        await exec("/usr/bin/pmset", ["sleepnow"], timeout: 10)
    }

    private static func stopMedia() async {
        let running = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
        await withTaskGroup(of: Void.self) { group in
            for player in players where running.contains(player.bundleID) {
                group.addTask {
                    let script = "tell application id \"\(player.bundleID)\" to \(player.command)"
                    let status = await exec(osascript, ["-e", script], timeout: 5)
                    if status != 0 { log.error("stopping \(player.bundleID, privacy: .public) failed (\(status))") }
                }
            }
        }
    }

    /// Runs a tool and returns its exit status, or stops it after `timeout` seconds.
    @discardableResult
    private static func exec(_ path: String, _ arguments: [String], timeout: TimeInterval) async -> Int32 {
        await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = arguments
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            process.terminationHandler = { continuation.resume(returning: $0.terminationStatus) }
            do {
                try process.run()
            } catch {
                log.error("\(path, privacy: .public) failed to start: \(error.localizedDescription)")
                continuation.resume(returning: -1)
                return
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                if process.isRunning { process.terminate() }
            }
        }
    }
}

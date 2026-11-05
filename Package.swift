// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Sleepy",
    platforms: [.macOS(.v26)],
    targets: [
        .target(name: "SleepyCore"),
        .executableTarget(
            name: "Sleepy",
            dependencies: ["SleepyCore"],
            exclude: []
        ),
        .testTarget(name: "SleepyCoreTests", dependencies: ["SleepyCore"]),
    ],
    swiftLanguageModes: [.v5]
)

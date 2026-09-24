// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Snicker",
    platforms: [.macOS("26.0")],
    targets: [
        .executableTarget(name: "Snicker"),
        // Run with `swift test`. Needs full Xcode (XCTest and Swift Testing don't ship with the
        // Command Line Tools); CI runs them on every push.
        .testTarget(name: "SnickerTests", dependencies: ["Snicker"]),
    ]
)

// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "XcodeColorTheory",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        // Library: Domain, Services, Views, AppEnvironment.
        // Imported by the app target and by the test target.
        .library(name: "XcodeColorTheory", targets: ["XcodeColorTheory"]),
        // Executable: only the @main entry point.
        .executable(name: "XcodeColorTheoryApp", targets: ["XcodeColorTheoryApp"])
    ],
    targets: [
        // Core library — all model, service, and view code.
        // No @main; safe to import from tests without @testable.
        .target(
            name: "XcodeColorTheory",
            path: "Sources/XcodeColorTheory",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        // App shell — only the @main struct. Depends on the library.
        .executableTarget(
            name: "XcodeColorTheoryApp",
            dependencies: ["XcodeColorTheory"],
            path: "Sources/XcodeColorTheoryApp",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "XcodeColorTheoryTests",
            dependencies: ["XcodeColorTheory"],
            path: "Tests/XcodeColorTheoryTests"
        )
    ]
)

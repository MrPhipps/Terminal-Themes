// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeTheory",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        // Library: Domain, Services, Views, AppEnvironment.
        // Imported by the Xcode project app target and by the test target.
        .library(name: "ThemeTheory", targets: ["ThemeTheory"]),
    ],
    targets: [
        // Core library — all model, service, and view code.
        // No @main; safe to import from tests without @testable.
        // Source directory kept at Sources/XcodeColorTheory to avoid a mass file move.
        .target(
            name: "ThemeTheory",
            path: "Sources/XcodeColorTheory",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        // Sources/XcodeColorTheoryApp/ThemeTheoryApp.swift (@main) is compiled
        // by the native Xcode project target in ThemeTheory.xcodeproj, not here.
        .testTarget(
            name: "XcodeColorTheoryTests",
            dependencies: ["ThemeTheory"],
            path: "Tests/XcodeColorTheoryTests"
        )
    ]
)

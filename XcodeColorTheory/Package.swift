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
        // Imported by the Xcode project app targets and by the test target.
        .library(name: "XcodeColorTheory", targets: ["XcodeColorTheory"]),
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
        // Sources/XcodeColorTheoryApp/XcodeColorTheoryApp.swift (@main) is compiled
        // by the native Xcode project targets in XcodeColorTheory.xcodeproj, not here.
        .testTarget(
            name: "XcodeColorTheoryTests",
            dependencies: ["XcodeColorTheory"],
            path: "Tests/XcodeColorTheoryTests"
        )
    ]
)

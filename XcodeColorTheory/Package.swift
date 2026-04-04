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
        // Core domain library — pure model and color science.
        // No @main; safe to import from tests without @testable.
        .target(
            name: "ThemeTheory",
            path: "Domain",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        // App layer (ThemeTheory/App|Services|Views + ThemeTheoryApp.swift) lives outside
        // the SPM package and is compiled by the native Xcode target, not here.
        .testTarget(
            name: "XcodeColorTheoryTests",
            dependencies: ["ThemeTheory"],
            path: "Tests/XcodeColorTheoryTests"
        )
    ]
)

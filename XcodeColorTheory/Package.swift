// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "XcodeColorTheory",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .executable(name: "XcodeColorTheory", targets: ["XcodeColorTheory"])
    ],
    targets: [
        .executableTarget(
            name: "XcodeColorTheory",
            path: "Sources/XcodeColorTheory",
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

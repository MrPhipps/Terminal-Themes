import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

/// An sRGB color with alpha.
///
/// Components are standard gamma-encoded sRGB values in the range 0–1.
/// This is the output type used for export (`.xccolortheme` plist strings)
/// and for SwiftUI `Color` construction; convert to linear sRGB before
/// performing luminance or contrast calculations (see `relativeLuminance(_:)`).
public struct RGBColor: Sendable, Equatable, Hashable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red.clamped(to: 0...1)
        self.green = green.clamped(to: 0...1)
        self.blue = blue.clamped(to: 0...1)
        self.alpha = alpha.clamped(to: 0...1)
    }

    // MARK: - Xcode .xccolortheme export format

    /// Produces the space-separated "R G B A" string used in Xcode color theme plists.
    /// Components are rounded to 6 decimal places to match Xcode's output.
    public var xcThemeString: String {
        let fmt = { (v: Double) in String(format: "%.6f", v) }
        return "\(fmt(red)) \(fmt(green)) \(fmt(blue)) \(fmt(alpha))"
    }

    /// Parses a space-separated Xcode theme color string back to RGBColor.
    public static func fromXCThemeString(_ string: String) -> RGBColor? {
        let parts = string.split(separator: " ").compactMap { Double($0) }
        guard parts.count == 4 else { return nil }
        return RGBColor(red: parts[0], green: parts[1], blue: parts[2], alpha: parts[3])
    }

    // MARK: - SwiftUI bridge

    #if canImport(SwiftUI)
    public var swiftUIColor: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
    #endif

    // MARK: - Common colors

    public static let black = RGBColor(red: 0, green: 0, blue: 0)
    public static let white = RGBColor(red: 1, green: 1, blue: 1)
    public static let clear = RGBColor(red: 0, green: 0, blue: 0, alpha: 0)
}

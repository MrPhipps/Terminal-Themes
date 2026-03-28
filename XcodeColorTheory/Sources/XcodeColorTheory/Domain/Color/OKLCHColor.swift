/// A color in the OKLCH perceptually-uniform color space.
///
/// OKLCH is the right space for Josef Albers-style color work because:
/// - Equal steps in L produce equal perceived lightness differences
/// - Hue is perceptually circular (no "yellow is brighter than blue" distortions)
/// - Chroma is bounded and predictable across hues
///
/// Lightness 0 = black, 1 = white.
/// Chroma 0 = achromatic; ~0.37 is the gamut edge for sRGB at mid-lightness.
/// Hue is degrees (0–360), red ≈ 29°, yellow ≈ 100°, green ≈ 140°,
/// cyan ≈ 195°, blue ≈ 250°, violet ≈ 300°.
public struct OKLCHColor: Sendable, Equatable, Hashable {
    public let lightness: Double   // 0–1
    public let chroma: Double      // 0–0.4
    public let hue: Double         // 0–360
    public let alpha: Double       // 0–1

    public init(lightness: Double, chroma: Double, hue: Double, alpha: Double = 1.0) {
        self.lightness = lightness.clamped(to: 0...1)
        self.chroma = chroma.clamped(to: 0...0.4)
        self.hue = hue.truncatingRemainder(dividingBy: 360)
        self.alpha = alpha.clamped(to: 0...1)
    }

    /// Achromatic grey at the given lightness.
    public static func grey(_ lightness: Double, alpha: Double = 1.0) -> OKLCHColor {
        OKLCHColor(lightness: lightness, chroma: 0, hue: 0, alpha: alpha)
    }

    /// Returns a copy with lightness adjusted by `delta`.
    public func lightened(by delta: Double) -> OKLCHColor {
        OKLCHColor(lightness: lightness + delta, chroma: chroma, hue: hue, alpha: alpha)
    }

    /// Returns a copy with chroma adjusted by `delta`.
    public func saturated(by delta: Double) -> OKLCHColor {
        OKLCHColor(lightness: lightness, chroma: chroma + delta, hue: hue, alpha: alpha)
    }

    /// Returns a copy rotated by `degrees` around the hue wheel.
    public func hueRotated(by degrees: Double) -> OKLCHColor {
        OKLCHColor(lightness: lightness, chroma: chroma, hue: hue + degrees, alpha: alpha)
    }

    /// Returns a copy with the given alpha.
    public func opacity(_ alpha: Double) -> OKLCHColor {
        OKLCHColor(lightness: lightness, chroma: chroma, hue: hue, alpha: alpha)
    }
}

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}

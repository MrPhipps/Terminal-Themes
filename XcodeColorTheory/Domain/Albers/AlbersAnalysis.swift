import Foundation

// MARK: - Albers Analysis
//
// Pure functions implementing Josef Albers' "Interaction of Color" principles
// as measurable quantities. All functions are referentially transparent.
//
// Key Albers insight: "Color is the most relative medium in art."
// These functions quantify *how relative* — giving the editor actionable numbers.

// MARK: - Contrast

/// WCAG 2.1 contrast ratio between foreground and background.
///
/// - Returns: A ratio in the range 1.0–21.0.
///   WCAG AA normal text: ≥ 4.5. AA large text / UI: ≥ 3.0.
///   For code, we target ≥ 4.5 for all foreground syntax roles.
public func contrastRatio(foreground: RGBColor, background: RGBColor) -> Double {
    let l1 = relativeLuminance(foreground)
    let l2 = relativeLuminance(background)
    let lighter = max(l1, l2)
    let darker = min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)
}

/// Evaluates the contrast rating for a given ratio.
public enum ContrastRating: String, Sendable {
    case fail        // < 3.0 — unreadable for any text
    case uiPass      // 3.0–4.49 — OK for large UI elements only
    case aaPass      // 4.5–6.99 — WCAG AA (normal text)
    case aaaPass     // ≥ 7.0 — WCAG AAA
}

public func contrastRating(ratio: Double) -> ContrastRating {
    switch ratio {
    case ..<3.0:       return .fail
    case 3.0..<4.5:   return .uiPass
    case 4.5..<7.0:   return .aaPass
    default:           return .aaaPass
    }
}

// MARK: - Vibration Risk
//
// Albers: when two adjacent colors have equal (or near-equal) luminance but
// different hues, the boundary appears to shimmer or "vibrate." This is
// visually fatiguing during extended reading sessions.
//
// We quantify this as a risk score 0–1 where:
//   0.0 = no risk (large luminance difference)
//   1.0 = maximum risk (identical luminance, different hue)

/// Computes the vibration risk between two adjacent colors.
///
/// High risk (≥ 0.7) indicates the pair should be avoided as direct syntax
/// neighbors on the same line (e.g. keyword immediately adjacent to a type name).
public func vibrationRisk(colorA: OKLCHColor, colorB: OKLCHColor) -> Double {
    // Luminance difference in OKLCH space (L is perceptually uniform)
    let luminanceDiff = abs(colorA.lightness - colorB.lightness)

    // Hue angular distance (normalized 0–1, where 1 = opposite hue)
    let hueDiff = min(
        abs(colorA.hue - colorB.hue),
        360 - abs(colorA.hue - colorB.hue)
    ) / 180.0

    // Vibration occurs when luminance is similar AND hue differs
    // The risk function is: (1 - luminanceDiff) * hueDiff * chromaFactor
    let chromaFactor = (colorA.chroma + colorB.chroma) / 0.4  // normalize to single-colour max (0.4)
    let risk = (1 - luminanceDiff.clamped(to: 0...1)) * hueDiff * chromaFactor.clamped(to: 0...1)

    return risk.clamped(to: 0...1)
}

public enum VibrationLevel: String, Sendable {
    case safe        // < 0.3
    case moderate    // 0.3–<0.7
    case high        // ≥ 0.7 — avoid as direct syntax neighbors
}

public func vibrationLevel(risk: Double) -> VibrationLevel {
    switch risk {
    case ..<0.3:   return .safe
    case 0.3..<0.7: return .moderate
    default:        return .high
    }
}

// MARK: - Simultaneous Contrast
//
// Albers: a color always appears different depending on its background.
// A mid-grey on a dark background looks lighter than on a white background.
//
// In OKLCH space, this manifests as a perceived lightness shift.
// We model it as a correction to apply to the displayed swatch in the editor.

/// Estimates the perceived lightness shift of `foreground` when placed on `background`.
///
/// Returns a delta in OKLCH L units (negative = appears darker, positive = appears lighter).
/// Use this in the editor to show "actual perceived" swatches.
public func simultaneousContrastShift(foreground: OKLCHColor, background: OKLCHColor) -> Double {
    // Albers' observation: a light background makes foreground appear darker by roughly
    // 10–20% of the background's lightness advantage.
    let bgAdvantage = background.lightness - foreground.lightness
    return -bgAdvantage * 0.15  // empirically calibrated constant for programming themes
}

/// Adjusts an OKLCH color for display in the editor swatch to approximate
/// how it will actually appear to the eye on the theme background.
public func perceivedColor(of color: OKLCHColor, on background: OKLCHColor) -> OKLCHColor {
    let shift = simultaneousContrastShift(foreground: color, background: background)
    return color.lightened(by: shift)
}

// MARK: - Color Temperature

/// Returns whether a hue reads as "warm" (advances visually) or "cool" (recedes).
///
/// Warm hues (red, orange, yellow) draw attention and should be used for
/// semantically important tokens (keywords, operators). Cool hues (blue, cyan)
/// recede and suit comments and secondary syntax.
public enum ColorTemperature: String, Sendable {
    case warm    // 0–60°, 300–360°
    case neutral // 60–120°, 240–300°
    case cool    // 120–259°
}

public func colorTemperature(hue: Double) -> ColorTemperature {
    let h = hue.truncatingRemainder(dividingBy: 360)
    switch h {
    case 0..<60:    return .warm
    case 60..<120:  return .neutral
    case 120..<260: return .cool
    case 260..<300: return .neutral
    default:        return .warm     // 300–360
    }
}

// MARK: - Fatigue Risk
//
// Albers: successive contrast — prolonged exposure to a color creates an
// afterimage in its complementary color. High-saturation colors cause more fatigue.
// For 10-hour sessions, chroma should stay moderate.

/// Returns a fatigue risk score 0–1 based on chroma and usage context.
///
/// Chroma > 0.25 in a foreground role is flagged as high-fatigue for long sessions.
public func fatigueRisk(chroma: Double, isBackground: Bool) -> Double {
    if isBackground {
        // Background chroma should be very low (< 0.05)
        return (chroma / 0.05).clamped(to: 0...1)
    } else {
        // Foreground chroma above 0.25 starts causing afterimage fatigue
        let risk = max(0, (chroma - 0.15) / 0.25)
        return risk.clamped(to: 0...1)
    }
}

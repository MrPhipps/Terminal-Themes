import Foundation

// MARK: - Harmony Schemes
//
// Pure functions that generate a set of hues from a single base hue,
// following classical color harmony relationships.
//
// Albers was skeptical of rigid harmony "rules" — he believed harmony
// emerged from *interaction*, not formula. But he used these relationships
// as starting points, then adjusted by eye. We do the same.

public enum HarmonyScheme: Sendable, Hashable, CaseIterable {
    /// Hues close together on the wheel. Cohesive, low-tension.
    case analogous

    /// The hue and its opposite. Maximum simultaneous contrast.
    case complementary

    /// The hue and two flanking its complement. Softer than pure complementary.
    case splitComplementary

    /// Three hues equally spaced. Balanced, vibrant.
    case triadic

    /// Four hues equally spaced. Rich but complex — requires careful lightness management.
    case tetradic

    /// Albers' own preference: a 4-color "Homage to the Square" palette.
    /// An inner square hue, outer square hue, and two transitional hues.
    /// These were the combinations Albers explored in his famous painting series.
    case albersFavorite

    public var displayName: String {
        switch self {
        case .analogous:           return "Analogous"
        case .complementary:       return "Complementary"
        case .splitComplementary:  return "Split Complementary"
        case .triadic:             return "Triadic"
        case .tetradic:            return "Tetradic"
        case .albersFavorite:      return "Albers Favorite"
        }
    }
}

/// Generates an array of accent hues from a base hue using the given harmony scheme.
///
/// Returns 1–4 hues (in degrees). The base hue is always index 0.
/// Used by the palette generator to assign hues to syntax roles.
public func accentHues(base: Double, scheme: HarmonyScheme) -> [Double] {
    func normalized(_ h: Double) -> Double {
        let r = h.truncatingRemainder(dividingBy: 360)
        return r < 0 ? r + 360 : r
    }

    switch scheme {
    case .analogous:
        return [base, normalized(base + 30), normalized(base - 30), normalized(base + 60)].map(normalized)

    case .complementary:
        return [base, normalized(base + 180)].map(normalized)

    case .splitComplementary:
        return [base, normalized(base + 150), normalized(base + 210)].map(normalized)

    case .triadic:
        return [base, normalized(base + 120), normalized(base + 240)].map(normalized)

    case .tetradic:
        return [base, normalized(base + 90), normalized(base + 180), normalized(base + 270)].map(normalized)

    case .albersFavorite:
        // Albers' "Homage to the Square": adjacent hues separated by ~30°,
        // plus their split complements. Produces a warm-leaning, cohesive quartet.
        return [
            base,
            normalized(base + 35),
            normalized(base + 180 - 20),
            normalized(base + 180 + 20)
        ].map(normalized)
    }
}

/// Distributes a set of hues across the syntax roles, assigning:
/// - Warm hues → semantically important roles (keywords, functions)
/// - Cool hues → secondary roles (comments, attributes)
/// - Darkest-hue positions → background, selection
public func assignHuesToRoles(
    hues: [Double],
    background: OKLCHColor
) -> [PaletteRole: OKLCHColor] {
    // Default lightness and chroma per role (Albers-optimized for dark backgrounds)
    let roleSpecs: [(PaletteRole, Double, Double)] = [
        // role, lightness, chroma
        (.plainText,            0.82, 0.015),
        (.keyword,              0.72, 0.12),
        (.typeIdentifier,       0.74, 0.11),
        (.functionIdentifier,   0.78, 0.08),
        (.constantIdentifier,   0.76, 0.09),
        (.variableIdentifier,   0.80, 0.06),
        (.numberLiteral,        0.73, 0.10),
        (.stringLiteral,        0.70, 0.09),
        (.comment,              0.50, 0.04),
        (.docComment,           0.55, 0.05),
        (.attribute,            0.68, 0.07),
        (.preprocessor,         0.65, 0.08),
        (.insertionPoint,       0.90, 0.02),
    ]

    // Cycle through hues for non-neutral roles
    var result: [PaletteRole: OKLCHColor] = [:]
    result[.background] = background
    result[.selection] = background.lightened(by: 0.15).saturated(by: 0.04)

    var hueIndex = 0
    for (role, lightness, chroma) in roleSpecs {
        let hue: Double
        if chroma < 0.03 {
            // Near-neutral: use base hue slightly warmed toward yellow
            hue = hues[0]
        } else {
            hue = hues[hueIndex % hues.count]
            hueIndex += 1
        }
        result[role] = OKLCHColor(lightness: lightness, chroma: chroma, hue: hue)
    }

    return result
}

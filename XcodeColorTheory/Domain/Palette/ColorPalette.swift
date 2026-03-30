import Foundation

// MARK: - ColorPalette
//
// A complete set of colors for all PaletteRoles. The functional core's central value type.
// Immutable — all edits produce a new ColorPalette.

public struct ColorPalette: Sendable, Equatable {
    public let name: String
    public let colors: [PaletteRole: OKLCHColor]

    public init(name: String, colors: [PaletteRole: OKLCHColor]) {
        self.name = name
        self.colors = colors
    }

    /// Returns the color for `role`, falling back to a neutral grey if unset.
    public subscript(role: PaletteRole) -> OKLCHColor {
        colors[role] ?? .grey(role.isBackground ? 0.15 : 0.70)
    }

    /// Returns a new palette with `role` set to `color`.
    public func setting(_ role: PaletteRole, to color: OKLCHColor) -> ColorPalette {
        var updated = colors
        updated[role] = color
        return ColorPalette(name: name, colors: updated)
    }

    /// Returns a new palette with a different name.
    public func renamed(_ newName: String) -> ColorPalette {
        ColorPalette(name: newName, colors: colors)
    }
}

// MARK: - PaletteValidation (error as types)

public enum PaletteWarning: Sendable {
    case highFatigue(role: PaletteRole, chroma: Double)
    case coolKeyword(role: PaletteRole, hue: Double)
    case moderateVibration(roleA: PaletteRole, roleB: PaletteRole, risk: Double)
}

public enum PaletteError: Error, Sendable {
    case insufficientContrast(role: PaletteRole, actual: Double, required: Double)
    case highVibration(roleA: PaletteRole, roleB: PaletteRole, risk: Double)
    case backgroundTooLight(lightness: Double)
}

public enum PaletteValidation: Sendable {
    case valid(ColorPalette)
    case warnings([PaletteWarning], ColorPalette)
    case errors([PaletteError])
}

// MARK: - Validation

/// Adjacent role pairs that Xcode renders next to each other on the same line
/// (e.g. `func myFunction(` has keyword + whitespace + functionIdentifier + …).
let adjacentRolePairs: [(PaletteRole, PaletteRole)] = [
    (.keyword, .functionIdentifier),
    (.keyword, .typeIdentifier),
    (.typeIdentifier, .plainText),
    (.functionIdentifier, .plainText),
    (.stringLiteral, .plainText),
    (.numberLiteral, .plainText),
    (.attribute, .typeIdentifier),
    (.preprocessor, .keyword),
]

/// Validates a palette against Albers constraints and WCAG contrast requirements.
///
/// Pure function — returns a `PaletteValidation` without any side effects.
public func validate(palette: ColorPalette) -> PaletteValidation {
    let bg = palette[.background]
    let bgRGB = oklchToRGB(bg)

    var errors: [PaletteError] = []
    var warnings: [PaletteWarning] = []

    // Background lightness check
    if bg.lightness > 0.5 {
        errors.append(.backgroundTooLight(lightness: bg.lightness))
    }

    // Contrast checks for all foreground roles
    for role in PaletteRole.allCases where !role.isBackground && role != .insertionPoint {
        let fgRGB = oklchToRGB(palette[role])
        let ratio = contrastRatio(foreground: fgRGB, background: bgRGB)
        let required = role.minimumContrastRatio
        if ratio < required {
            errors.append(.insufficientContrast(role: role, actual: ratio, required: required))
        }
    }

    // Vibration checks for adjacent pairs
    for (a, b) in adjacentRolePairs {
        let risk = vibrationRisk(colorA: palette[a], colorB: palette[b])
        if risk >= 0.7 {
            errors.append(.highVibration(roleA: a, roleB: b, risk: risk))
        } else if risk >= 0.3 {
            warnings.append(.moderateVibration(roleA: a, roleB: b, risk: risk))
        }
    }

    // Fatigue warnings
    for role in PaletteRole.allCases {
        let c = palette[role]
        let fatigue = fatigueRisk(chroma: c.chroma, isBackground: role.isBackground)
        if fatigue > 0.7 {
            warnings.append(.highFatigue(role: role, chroma: c.chroma))
        }
    }

    // Keyword temperature advisory
    let kwHue = palette[.keyword].hue
    if colorTemperature(hue: kwHue) == .cool {
        warnings.append(.coolKeyword(role: .keyword, hue: kwHue))
    }

    if !errors.isEmpty {
        return .errors(errors)
    } else if !warnings.isEmpty {
        return .warnings(warnings, palette)
    } else {
        return .valid(palette)
    }
}

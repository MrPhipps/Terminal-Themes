import Testing
@testable import ThemeTheory

// MARK: - Palette Validation Tests

@Suite("Palette Validation")
struct PaletteValidationTests {

    // MARK: Built-in palette integrity

    @Test("albersMidnight has all 15 palette roles defined")
    func albersMidnightCompleteness() {
        let palette = ColorPalette.albersMidnight
        for role in PaletteRole.allCases {
            #expect(palette.colors[role] != nil, "Missing role: \(role.displayName)")
        }
    }

    @Test("albersOchre has all 15 palette roles defined")
    func albersOchreCompleteness() {
        let palette = ColorPalette.albersOchre
        for role in PaletteRole.allCases {
            #expect(palette.colors[role] != nil, "Missing role: \(role.displayName)")
        }
    }

    @Test("albersMidnight background lightness is < 0.5")
    func albersMidnightBackgroundDark() {
        let palette = ColorPalette.albersMidnight
        #expect(palette[.background].lightness < 0.5)
    }

    @Test("albersMidnight passes validation (valid or warnings only)")
    func albersMidnightValidation() {
        let result = validate(palette: .albersMidnight)
        switch result {
        case .errors(let errors):
            // Report which errors occurred for debugging
            let messages = errors.map { error -> String in
                switch error {
                case .insufficientContrast(let role, let actual, let required):
                    return "\(role.displayName): \(actual) < \(required)"
                case .highVibration(let a, let b, let risk):
                    return "vibration \(a.rawValue)/\(b.rawValue): \(risk)"
                case .backgroundTooLight(let l):
                    return "bg too light: \(l)"
                }
            }
            #expect(Bool(false), "Validation errors: \(messages)")
        case .valid, .warnings:
            break  // pass
        }
    }

    // MARK: Validation logic

    @Test("Too-light background produces backgroundTooLight error")
    func lightBackgroundError() {
        var palette = ColorPalette.albersMidnight
        palette = palette.setting(.background, to: OKLCHColor(lightness: 0.8, chroma: 0.01, hue: 0))
        let result = validate(palette: palette)
        if case .errors(let errors) = result {
            let hasBgError = errors.contains {
                if case .backgroundTooLight = $0 { return true }
                return false
            }
            #expect(hasBgError)
        } else {
            #expect(Bool(false), "Expected errors but got: \(result)")
        }
    }

    @Test("Identical foreground and background colors produces contrast error")
    func identicalColorsContrastError() {
        let bg = ColorPalette.albersMidnight[.background]
        var palette = ColorPalette.albersMidnight
        palette = palette.setting(.keyword, to: bg)
        let result = validate(palette: palette)
        if case .errors(let errors) = result {
            let hasContrastError = errors.contains {
                if case .insufficientContrast(let role, _, _) = $0, role == .keyword { return true }
                return false
            }
            #expect(hasContrastError)
        } else {
            #expect(Bool(false), "Expected contrast error")
        }
    }

    // MARK: Palette mutation

    @Test("setting(_:to:) returns new palette with updated color")
    func settingColor() {
        let palette = ColorPalette.albersMidnight
        let newColor = OKLCHColor(lightness: 0.8, chroma: 0.15, hue: 180)
        let updated = palette.setting(.keyword, to: newColor)
        #expect(updated[.keyword] == newColor)
        #expect(palette[.keyword] != newColor)  // original unchanged
    }

    @Test("renamed(_:) returns new palette with updated name")
    func renamingPalette() {
        let palette = ColorPalette.albersMidnight
        let renamed = palette.renamed("My Custom Theme")
        #expect(renamed.name == "My Custom Theme")
        #expect(palette.name == "Albers Midnight")  // original unchanged
    }

    @Test("Subscript fallback returns grey for undefined roles")
    func subscriptFallback() {
        let empty = ColorPalette(name: "Empty", colors: [:])
        let color = empty[.keyword]
        // Should fall back to a grey (chroma near 0)
        #expect(color.chroma < 0.05)
    }

    // MARK: Harmony generator

    @Test("accentHues returns correct count for each scheme")
    func accentHueCounts() {
        #expect(accentHues(base: 0, scheme: .analogous).count == 4)
        #expect(accentHues(base: 0, scheme: .complementary).count == 2)
        #expect(accentHues(base: 0, scheme: .splitComplementary).count == 3)
        #expect(accentHues(base: 0, scheme: .triadic).count == 3)
        #expect(accentHues(base: 0, scheme: .tetradic).count == 4)
        #expect(accentHues(base: 0, scheme: .albersFavorite).count == 4)
    }

    @Test("accentHues base hue is always index 0")
    func accentHuesBaseIsFirst() {
        let base = 120.0
        for scheme in HarmonyScheme.allCases {
            let hues = accentHues(base: base, scheme: scheme)
            #expect(hues[0] == base, "Scheme \(scheme) failed: first hue was \(hues[0])")
        }
    }

    @Test("All hues are normalized to 0–360")
    func huesNormalized() {
        let hues = accentHues(base: 350, scheme: .complementary)
        for hue in hues {
            #expect(hue >= 0)
            #expect(hue < 360)
        }
    }
}

import XcodeColorTheory

// ═══════════════════════════════════════════════════════════════════════════
// XcodeColorTheory — Public API Explorer
//
// Run each section top-to-bottom in the playground to explore the library.
// All types and functions shown here are public — no @testable needed.
// ═══════════════════════════════════════════════════════════════════════════

// MARK: - 1. OKLCHColor ────────────────────────────────────────────────────
//
// Perceptually-uniform color space. Equal steps in L = equal perceived
// brightness — the foundation for accurate Albers vibration detection.

let navy   = OKLCHColor(lightness: 0.16, chroma: 0.015, hue: 250)
let violet = OKLCHColor(lightness: 0.72, chroma: 0.12,  hue: 300)
let amber  = OKLCHColor(lightness: 0.78, chroma: 0.14,  hue: 55)
let grey   = OKLCHColor.grey(0.6)           // achromatic convenience

// Derived copies — all return new values, original is unchanged
let lighter  = navy.lightened(by: 0.1)
let more_sat = navy.saturated(by: 0.05)
let rotated  = violet.hueRotated(by: 60)
let faded    = amber.opacity(0.5)

print("navy:    L=\(navy.lightness) C=\(navy.chroma) H=\(navy.hue)")
print("lighter: L=\(lighter.lightness)")

// MARK: - 2. ColorConversions ─────────────────────────────────────────────
//
// OKLCH ↔ sRGB via OKLAB. Both directions available.

let navyRGB   = oklchToRGB(navy)
let violetRGB = oklchToRGB(violet)

// Round-trip: OKLCH → sRGB → OKLCH
let navyBack  = rgbToOKLCH(navyRGB)
print("Round-trip L delta: \(abs(navy.lightness - navyBack.lightness))")   // ~0

// Xcode .xccolortheme string format: "R G B A" (0–1, space-separated)
print("Violet xcThemeString: \(violetRGB.xcThemeString)")

// WCAG relative luminance (0 = black, 1 = white)
let lum = relativeLuminance(navyRGB)
print("Navy relative luminance: \(String(format: "%.4f", lum))")

// MARK: - 3. AlbersAnalysis ───────────────────────────────────────────────

// — Contrast ratio (WCAG 2.1) —
let ratio  = contrastRatio(foreground: violetRGB, background: navyRGB)
let rating = contrastRating(ratio: ratio)
print("Violet on navy: \(String(format: "%.1f", ratio)):1 — \(rating.rawValue)")
// aaPass = ≥4.5, aaaPass = ≥7.0

// — Vibration risk —
// Equal-lightness + opposite hue = shimmer at boundaries (Albers, 1963)
let amberRGB = oklchToRGB(amber)
let risk  = vibrationRisk(colorA: violet, colorB: amber)
let level = vibrationLevel(risk: risk)
print("Violet/amber vibration: \(String(format: "%.2f", risk)) — \(level.rawValue)")

// — Simultaneous contrast shift —
let shift = simultaneousContrastShift(foreground: violet, background: navy)
print("Perceived lightness shift on navy bg: \(String(format: "%+.3f", shift))")

let perceived = perceivedColor(of: violet, on: navy)
print("Perceived violet L: \(String(format: "%.3f", perceived.lightness))")

// — Color temperature —
//   warm (0–60°, 300–360°) | neutral (60–120°, 260–300°) | cool (120–260°)
print("Amber temp:  \(colorTemperature(hue: amber.hue).rawValue)")   // warm
print("Violet temp: \(colorTemperature(hue: violet.hue).rawValue)")  // warm (300°)
print("Navy temp:   \(colorTemperature(hue: navy.hue).rawValue)")    // cool (250°)

// — Fatigue risk —
//   foreground chroma >0.25 = afterimage risk in 10-hour sessions
let bgFatigue = fatigueRisk(chroma: navy.chroma,   isBackground: true)
let fgFatigue = fatigueRisk(chroma: violet.chroma, isBackground: false)
print("Background fatigue: \(String(format: "%.2f", bgFatigue))")   // low
print("Foreground fatigue: \(String(format: "%.2f", fgFatigue))")

// MARK: - 4. PaletteRole ──────────────────────────────────────────────────
//
// 15 semantic roles covering all Xcode syntax token categories.

print("\nAll roles:")
PaletteRole.allCases.forEach { print("  \($0.rawValue)") }

// MARK: - 5. ColorPalette ─────────────────────────────────────────────────
//
// Immutable value type. Mutations return new instances.

let midnight = ColorPalette.albersMidnight
let ochre    = ColorPalette.albersOchre

print("\nMidnight keyword: H=\(midnight[.keyword].hue)°")

// Modify a role — returns a new palette, original unchanged
let tweaked = midnight.setting(.keyword, to: amber)
print("Tweaked keyword H: \(tweaked[.keyword].hue)°  original: \(midnight[.keyword].hue)°")

// Rename
let named = midnight.renamed("My Midnight")
print("Renamed: \(named.name)")

// Built-ins
print("Built-in palettes: \(ColorPalette.builtIn.map(\.name))")

// Validation — pure function returning an algebraic result
let validation = validate(palette: midnight)
switch validation {
case .valid:
    print("Palette is valid")
case .warnings(let warnings, _):
    print("Warnings: \(warnings.map(\.description))")
case .errors(let errors):
    print("Errors: \(errors.map(\.description))")
}

// MARK: - 6. HarmonyGenerator ─────────────────────────────────────────────
//
// Pure functions for generating Albers-informed color relationships.

let schemes = HarmonyScheme.allCases
print("\nAll harmony schemes:")
schemes.forEach { print("  \($0.rawValue) — \($0.displayName)") }

// Generate accent hues for a warm amber base
let hues = accentHues(base: 55, scheme: .albersFavorite)
print("albersFavorite hues from 55°: \(hues.map { Int($0) })")

// Assign to roles
let assignments = assignHuesToRoles(hues: hues, background: navy)
print("Assigned keyword hue: \(Int(assignments[.keyword]?.hue ?? 0))°")

// MARK: - 7. ThemeSerializer ──────────────────────────────────────────────
//
// Pure functions — no I/O. Convert palette → Xcode theme XML.

// All five ThemeFonts
print("\nAvailable fonts:")
ThemeFont.allLigatureFonts.forEach { print("  \($0.xcThemeString)") }

// xcodeTheme: palette → XcodeColorTheme (intermediate struct)
let theme = xcodeTheme(from: midnight, font: .default)
print("Theme name: \(theme.name)")
print("Syntax color count: \(theme.syntaxColors.count)")

// serialize: XcodeColorTheme → XML string
let xml = serialize(theme)
print("\nFirst 200 chars of .xccolortheme XML:")
print(xml.prefix(200))

// Convenience: palette → XML in one step
let directXML = themeXMLString(for: ochre, font: .firaCode)
print("\nOchre/FiraCode XML length: \(directXML.count) chars")

// MARK: - 8. SyntaxRole ───────────────────────────────────────────────────
//
// All Xcode xcode.syntax.* keys, each mapped to a PaletteRole.

print("\nSyntax role → palette role mappings:")
SyntaxRole.allCases.forEach {
    print("  \($0.rawValue) → \($0.paletteRole.rawValue)")
}

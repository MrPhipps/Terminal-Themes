// MARK: - XcodeColorTheme
//
// A complete Xcode color theme. This is the output model — derived from a
// ColorPalette and ready to be serialized into a `.xccolortheme` plist file.
//
// Separating XcodeColorTheme from ColorPalette keeps the domain pure:
// ColorPalette is about *what the colors mean*, XcodeColorTheme is about
// *how Xcode represents them*.

public struct XcodeColorTheme: Sendable, Equatable {
    public let name: String
    public let syntaxColors: [SyntaxRole: RGBColor]
    public let background: RGBColor
    public let selectionColor: RGBColor
    public let insertionPointColor: RGBColor
    public let font: ThemeFont

    public init(
        name: String,
        syntaxColors: [SyntaxRole: RGBColor],
        background: RGBColor,
        selectionColor: RGBColor,
        insertionPointColor: RGBColor,
        font: ThemeFont = .default
    ) {
        self.name = name
        self.syntaxColors = syntaxColors
        self.background = background
        self.selectionColor = selectionColor
        self.insertionPointColor = insertionPointColor
        self.font = font
    }
}

// MARK: - ThemeFont

public struct ThemeFont: Sendable, Equatable {
    public let familyName: String
    public let size: Double

    public init(familyName: String, size: Double) {
        self.familyName = familyName
        self.size = size
    }

    // MARK: Top 5 free open-source developer fonts with ligature support
    //
    // All fonts below are licensed under the SIL Open Font License 1.1 or Apache 2.0.
    // Each offers multiple weights and extensive programming ligature coverage.
    // Install via Homebrew: `brew install --cask font-<name>` or from their GitHub releases.

    /// JetBrains Mono — the original Fish Homebrew terminal font, carried forward.
    /// Apache 2.0. Exceptional legibility at small sizes, 139 ligatures.
    /// https://github.com/JetBrains/JetBrainsMono
    public static let `default`: ThemeFont = ThemeFont(familyName: "JetBrainsMonoNL-Regular", size: 13)

    /// Fira Code — the canonical ligature coding font.
    /// SIL OFL 1.1. Pioneered programming ligatures; 6 weights.
    /// https://github.com/tonsky/FiraCode
    public static let firaCode: ThemeFont = ThemeFont(familyName: "FiraCode-Regular", size: 13)

    /// Cascadia Code — Microsoft's open-source coding font.
    /// SIL OFL 1.1. Includes a cursive italic variant (Cascadia Code Italic).
    /// Pairs naturally with VS Code but reads beautifully in Xcode.
    /// https://github.com/microsoft/cascadia-code
    public static let cascadiaCode: ThemeFont = ThemeFont(familyName: "CascadiaCode-Regular", size: 13)

    /// IBM Plex Mono — IBM's corporate open-source typeface.
    /// SIL OFL 1.1. Eight weights, strong geometric structure, excellent for
    /// heavy terminal use. Iconoclasta shares its rational, grid-based DNA.
    /// https://github.com/IBM/plex
    public static let ibmPlexMono: ThemeFont = ThemeFont(familyName: "IBMPlexMono-Regular", size: 13)

    /// Victor Mono — lightweight, semi-connected cursive italics.
    /// SIL OFL 1.1. The italic style distinguishes comments beautifully against
    /// upright keywords — a natural fit for Albers-style visual hierarchy.
    /// https://github.com/rubjo/victor-mono
    public static let victorMono: ThemeFont = ThemeFont(familyName: "VictorMono-Regular", size: 13)

    // MARK: System fallbacks

    public static let sfMono: ThemeFont = ThemeFont(familyName: "SFMono-Regular", size: 13)
    public static let menlo: ThemeFont = ThemeFont(familyName: "Menlo-Regular", size: 13)

    /// All fonts offered in the export UI picker, ordered by visual character.
    public static let allLigatureFonts: [(label: String, font: ThemeFont)] = [
        ("JetBrains Mono", .default),
        ("Fira Code",       .firaCode),
        ("Cascadia Code",   .cascadiaCode),
        ("IBM Plex Mono",   .ibmPlexMono),
        ("Victor Mono",     .victorMono),
    ]

    /// The string format used in DVTSourceTextSyntaxFonts plist values.
    public var xcThemeString: String { return "\(familyName) - \(Int(size))" }
}

// MARK: - ColorPalette → XcodeColorTheme conversion

/// Pure function: converts a ColorPalette into an XcodeColorTheme.
///
/// All OKLCH colors are converted to sRGB for export.
/// All SyntaxRole keys get their color via the PaletteRole mapping.
public func xcodeTheme(from palette: ColorPalette, font: ThemeFont = .default) -> XcodeColorTheme {
    let syntaxColors = Dictionary(
        uniqueKeysWithValues: SyntaxRole.allCases.map { role in
            (role, oklchToRGB(palette[role.paletteRole]))
        }
    )

    return XcodeColorTheme(
        name: palette.name,
        syntaxColors: syntaxColors,
        background: oklchToRGB(palette[.background]),
        selectionColor: oklchToRGB(palette[.selection]),
        insertionPointColor: oklchToRGB(palette[.insertionPoint]),
        font: font
    )
}

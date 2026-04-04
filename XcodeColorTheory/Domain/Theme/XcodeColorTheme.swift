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
    public let fontHierarchy: FontHierarchy

    public init(
        name: String,
        syntaxColors: [SyntaxRole: RGBColor],
        background: RGBColor,
        selectionColor: RGBColor,
        insertionPointColor: RGBColor,
        fontHierarchy: FontHierarchy = .default
    ) {
        self.name = name
        self.syntaxColors = syntaxColors
        self.background = background
        self.selectionColor = selectionColor
        self.insertionPointColor = insertionPointColor
        self.fontHierarchy = fontHierarchy
    }
}

// MARK: - ThemeFont

public struct ThemeFont: Sendable, Equatable, Hashable {
    public let familyName: String
    public let size: Double

    public init(familyName: String, size: Double) {
        self.familyName = familyName
        self.size = size
    }

    // MARK: Base family regulars — used as building blocks for FontHierarchy presets

    public static let `default`: ThemeFont = ThemeFont(familyName: "JetBrainsMonoNL-Regular", size: 13)
    public static let firaCode: ThemeFont   = ThemeFont(familyName: "FiraCode-Regular",       size: 13)
    public static let cascadiaCode: ThemeFont = ThemeFont(familyName: "CascadiaCode-Regular", size: 13)
    public static let ibmPlexMono: ThemeFont = ThemeFont(familyName: "IBMPlexMono-Regular",   size: 13)
    public static let victorMono: ThemeFont  = ThemeFont(familyName: "VictorMono-Regular",    size: 13)
    public static let sfMono: ThemeFont      = ThemeFont(familyName: "SFMono-Regular",        size: 13)
    public static let menlo: ThemeFont       = ThemeFont(familyName: "Menlo-Regular",         size: 13)

    /// The string format used in DVTSourceTextSyntaxFonts plist values.
    public var xcThemeString: String { "\(familyName) - \(Int(size))" }
}

// MARK: - FontCategory
//
// Semantic grouping of syntax roles for font assignment.
// Three tiers cover the full visual hierarchy without over-engineering:
//   comment    → italic or lighter weight (de-emphasised)
//   keyword    → bold or distinct (high salience)
//   identifier → regular (the baseline "code" voice)

public enum FontCategory: String, CaseIterable, Sendable, Hashable {
    case comment
    case keyword
    case identifier

    public var displayName: String {
        switch self {
        case .comment:    return "Comments"
        case .keyword:    return "Keywords & Directives"
        case .identifier: return "Identifiers & Literals"
        }
    }
}

// MARK: - FontHierarchy
//
// Maps each FontCategory to a ThemeFont (family + size).
// The serializer dispatches SyntaxRole → fontCategory → ThemeFont → xcThemeString,
// so Xcode's DVTSourceTextSyntaxFonts gets per-role entries with proper variants.

public struct FontHierarchy: Sendable, Equatable {
    public var fonts: [FontCategory: ThemeFont]

    public init(_ fonts: [FontCategory: ThemeFont]) {
        self.fonts = fonts
    }

    public subscript(category: FontCategory) -> ThemeFont {
        fonts[category] ?? .default
    }

    /// A flat hierarchy — every category uses the same font variant.
    public static func flat(_ font: ThemeFont) -> FontHierarchy {
        FontHierarchy(Dictionary(uniqueKeysWithValues: FontCategory.allCases.map { ($0, font) }))
    }

    // MARK: Built-in presets

    /// JetBrains Mono with weight/style variation per category (the app default).
    public static let `default`: FontHierarchy = FontHierarchy([
        .comment:    ThemeFont(familyName: "JetBrainsMonoNL-Italic",  size: 13),
        .keyword:    ThemeFont(familyName: "JetBrainsMonoNL-Bold",    size: 13),
        .identifier: ThemeFont(familyName: "JetBrainsMonoNL-Regular", size: 13),
    ])

    /// Fira Code — no italic variant; uses Light for comments.
    public static let firaCode: FontHierarchy = FontHierarchy([
        .comment:    ThemeFont(familyName: "FiraCode-Light",   size: 13),
        .keyword:    ThemeFont(familyName: "FiraCode-Bold",    size: 13),
        .identifier: ThemeFont(familyName: "FiraCode-Regular", size: 13),
    ])

    /// Cascadia Code — cursive italic for comments (the signature Cascadia feature).
    public static let cascadiaCode: FontHierarchy = FontHierarchy([
        .comment:    ThemeFont(familyName: "CascadiaCode-Italic",   size: 13),
        .keyword:    ThemeFont(familyName: "CascadiaCode-Bold",     size: 13),
        .identifier: ThemeFont(familyName: "CascadiaCode-Regular",  size: 13),
    ])

    /// IBM Plex Mono — light italic comments, bold keywords.
    public static let ibmPlexMono: FontHierarchy = FontHierarchy([
        .comment:    ThemeFont(familyName: "IBMPlexMono-LightItalic", size: 13),
        .keyword:    ThemeFont(familyName: "IBMPlexMono-Bold",        size: 13),
        .identifier: ThemeFont(familyName: "IBMPlexMono-Regular",     size: 13),
    ])

    /// Victor Mono — semi-connected cursive italic distinguishes comments beautifully.
    public static let victorMono: FontHierarchy = FontHierarchy([
        .comment:    ThemeFont(familyName: "VictorMono-Italic",   size: 13),
        .keyword:    ThemeFont(familyName: "VictorMono-Bold",     size: 13),
        .identifier: ThemeFont(familyName: "VictorMono-Regular",  size: 13),
    ])

    /// All presets offered in the export UI, ordered by visual character.
    public static let allPresets: [(label: String, hierarchy: FontHierarchy)] = [
        ("JetBrains Mono",        .default),
        ("JetBrains Mono (Flat)", .flat(.default)),
        ("Fira Code",             .firaCode),
        ("Cascadia Code",         .cascadiaCode),
        ("IBM Plex Mono",         .ibmPlexMono),
        ("Victor Mono",           .victorMono),
        ("SF Mono",               .flat(.sfMono)),
        ("Menlo",                 .flat(.menlo)),
    ]
}

// MARK: - ColorPalette → XcodeColorTheme conversion

/// Pure function: converts a ColorPalette into an XcodeColorTheme.
///
/// All OKLCH colors are converted to sRGB for export.
/// All SyntaxRole keys get their color via the PaletteRole mapping.
public func xcodeTheme(from palette: ColorPalette, fontHierarchy: FontHierarchy = .default) -> XcodeColorTheme {
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
        fontHierarchy: fontHierarchy
    )
}

import Foundation

// MARK: - ThemeSerializer
//
// Pure function: XcodeColorTheme → XML plist string.
//
// Xcode's .xccolortheme format is a property list. Colors are stored as
// space-separated "R G B A" strings (sRGB, gamma-corrected, 0–1 range).
// Fonts are stored as "FamilyName - Size" strings.
//
// We hand-build the XML rather than using PropertyListSerialization to avoid
// Foundation's key sorting, which scrambles the output compared to Xcode's own format.

/// Serializes an XcodeColorTheme into the `.xccolortheme` XML plist format.
///
/// The output can be written directly to a `.xccolortheme` file.
/// Pure function — no I/O, no side effects.
public func serialize(_ theme: XcodeColorTheme) -> String {
    var lines: [String] = []

    lines += plistHeader()
    lines += ["<dict>"]

    let plainString: String = theme.syntaxColors[.plain]?.xcThemeString ?? ""
    // Console uses the identifier category font (the default "code" voice)
    let consoleFontString: String = theme.fontHierarchy[.identifier].xcThemeString

    // Console debugger colors (match plain text for consistency)
    lines += plistEntry("DVTConsoleDebuggerInputTextColor", value: plainString)
    lines += plistEntry("DVTConsoleDebuggerInputTextFont", value: consoleFontString)
    lines += plistEntry("DVTConsoleDebuggerOutputTextColor", value: plainString)
    lines += plistEntry("DVTConsoleDebuggerOutputTextFont", value: consoleFontString)
    lines += plistEntry("DVTConsoleExecutionOutputTextColor", value: plainString)
    lines += plistEntry("DVTConsoleTextBackgroundColor", value: theme.background.xcThemeString)
    lines += plistEntry("DVTConsoleTextInsertionPointColor", value: theme.insertionPointColor.xcThemeString)
    lines += plistEntry("DVTConsoleTextSelectionColor", value: theme.selectionColor.xcThemeString)

    // Source editor
    lines += plistEntry("DVTSourceTextBackground", value: theme.background.xcThemeString)
    lines += plistReal("DVTSourceTextBlockDimStrength", value: 0.3)
    lines += plistReal("DVTSourceTextBlockDimStrengthEmptyFile", value: 0.15)
    lines += plistEntry("DVTSourceTextInsertionPointColor", value: theme.insertionPointColor.xcThemeString)
    lines += plistEntry("DVTSourceTextInvisiblesColor", value:
        RGBColor(
            red: (theme.background.red + 0.15).clamped(to: 0...1),
            green: (theme.background.green + 0.15).clamped(to: 0...1),
            blue: (theme.background.blue + 0.15).clamped(to: 0...1)
        ).xcThemeString)
    lines += plistEntry("DVTSourceTextSelectionColor", value: theme.selectionColor.xcThemeString)

    // Syntax colors dict
    lines += ["    <key>DVTSourceTextSyntaxColors</key>", "    <dict>"]
    for role in SyntaxRole.allCases {
        if let color = theme.syntaxColors[role] {
            lines += [
                "        <key>\(role.rawValue)</key>",
                "        <string>\(color.xcThemeString)</string>"
            ]
        }
    }
    lines += ["    </dict>"]

    // Syntax fonts dict — per-role, dispatched through FontCategory
    lines += ["    <key>DVTSourceTextSyntaxFonts</key>", "    <dict>"]
    for role in SyntaxRole.allCases {
        let fontString = theme.fontHierarchy[role.fontCategory].xcThemeString
        lines += [
            "        <key>\(role.rawValue)</key>",
            "        <string>\(fontString)</string>"
        ]
    }
    lines += ["    </dict>"]

    // Theme metadata
    lines += plistEntry("name", value: xmlEscaped(theme.name))
    lines += ["    <key>version</key>", "    <integer>1</integer>"]

    lines += ["</dict>"]
    lines += plistFooter()

    return lines.joined(separator: "\n") + "\n"
}

// MARK: - Helpers

private func plistHeader() -> [String] {
    return [
        #"<?xml version="1.0" encoding="UTF-8"?>"#,
        #"<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">"#,
        #"<plist version="1.0">"#
    ]
}

private func plistFooter() -> [String] {
    return ["</plist>"]
}

/// Emits a key/string pair. Keys are Xcode-defined constants (safe).
/// Values that come from user input (palette name) must be XML-escaped before passing here.
private func plistEntry(_ key: String, value: String) -> [String] {
    return ["    <key>\(key)</key>", "    <string>\(value)</string>"]
}

/// Emits a key/real pair for numeric plist values (e.g. dim-strength floats).
/// Using <string> for numeric keys causes Xcode to ignore them.
private func plistReal(_ key: String, value: Double) -> [String] {
    return ["    <key>\(key)</key>", "    <real>\(value)</real>"]
}

/// Escapes the five standard XML entities so user-provided strings
/// (palette names containing `&`, `<`, `>`, `"`, `'`) produce valid XML.
func xmlEscaped(_ string: String) -> String {
    var result: String = string
    result = result.replacingOccurrences(of: "&", with: "&amp;")
    result = result.replacingOccurrences(of: "<", with: "&lt;")
    result = result.replacingOccurrences(of: ">", with: "&gt;")
    result = result.replacingOccurrences(of: "\"", with: "&quot;")
    result = result.replacingOccurrences(of: "'", with: "&apos;")
    return result
}

/// Convenience wrapper: converts a ColorPalette directly to `.xccolortheme` XML.
/// Pure function — no actor required.
public func themeXMLString(for palette: ColorPalette, fontHierarchy: FontHierarchy = .default) -> String {
    return serialize(xcodeTheme(from: palette, fontHierarchy: fontHierarchy))
}

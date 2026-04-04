import Testing
import Foundation
@testable import ThemeTheory

// MARK: - Theme Serializer Tests

@Suite("Theme Serializer")
struct ThemeSerializerTests {

    // MARK: XML structure

    @Test("Serialized output is valid XML (starts with plist declaration)")
    func xmlDeclaration() {
        let xml = serialize(xcodeTheme(from: .albersMidnight))
        #expect(xml.hasPrefix(#"<?xml version="1.0""#))
    }

    @Test("Serialized output contains plist root element")
    func plistRootElement() {
        let xml = serialize(xcodeTheme(from: .albersMidnight))
        #expect(xml.contains("<plist version=\"1.0\">"))
        #expect(xml.contains("</plist>"))
    }

    @Test("Serialized output contains DVTSourceTextBackground key")
    func containsBackground() {
        let xml = serialize(xcodeTheme(from: .albersMidnight))
        #expect(xml.contains("<key>DVTSourceTextBackground</key>"))
    }

    @Test("Serialized output contains DVTSourceTextSyntaxColors dict")
    func containsSyntaxColorsDict() {
        let xml = serialize(xcodeTheme(from: .albersMidnight))
        #expect(xml.contains("<key>DVTSourceTextSyntaxColors</key>"))
        #expect(xml.contains("<dict>"))
    }

    @Test("All SyntaxRole keys appear in serialized output")
    func allSyntaxRolesPresent() {
        let xml = serialize(xcodeTheme(from: .albersMidnight))
        for role in SyntaxRole.allCases {
            #expect(xml.contains(role.rawValue), "Missing syntax key: \(role.rawValue)")
        }
    }

    @Test("Theme name is embedded in output")
    func themeNameEmbedded() {
        let xml = serialize(xcodeTheme(from: .albersMidnight))
        #expect(xml.contains("Albers Midnight"))
    }

    @Test("Version integer is 1")
    func versionOne() {
        let xml = serialize(xcodeTheme(from: .albersMidnight))
        #expect(xml.contains("<key>version</key>"))
        #expect(xml.contains("<integer>1</integer>"))
    }

    // MARK: Color format

    @Test("Color strings have 4 space-separated components")
    func colorStringFormat() {
        let theme = xcodeTheme(from: .albersMidnight)
        let bgLine = theme.background.xcThemeString
        let parts = bgLine.split(separator: " ")
        #expect(parts.count == 4)
    }

    @Test("Color components are in 0–1 range")
    func colorComponentRange() {
        let palette = ColorPalette.albersMidnight
        for role in PaletteRole.allCases {
            let rgb = oklchToRGB(palette[role])
            #expect(rgb.red >= 0 && rgb.red <= 1)
            #expect(rgb.green >= 0 && rgb.green <= 1)
            #expect(rgb.blue >= 0 && rgb.blue <= 1)
            #expect(rgb.alpha >= 0 && rgb.alpha <= 1)
        }
    }

    // MARK: Font format

    @Test("Font string contains family name and size")
    func fontStringFormat() {
        let font = ThemeFont.default
        #expect(font.xcThemeString.contains("JetBrainsMonoNL-Regular"))
        #expect(font.xcThemeString.contains("13"))
    }

    @Test("Custom font appears in serialized output")
    func customFontInOutput() {
        let theme = xcodeTheme(from: .albersMidnight, fontHierarchy: .flat(.sfMono))
        let xml = serialize(theme)
        #expect(xml.contains("SFMono-Regular"))
    }

    // MARK: xcodeTheme conversion

    @Test("xcodeTheme maps all SyntaxRoles")
    func allSyntaxRolesMapped() {
        let theme = xcodeTheme(from: .albersMidnight)
        for role in SyntaxRole.allCases {
            #expect(theme.syntaxColors[role] != nil, "Unmapped role: \(role.rawValue)")
        }
    }

    @Test("xcodeTheme background matches palette background in OKLCH → RGB conversion")
    func backgroundColorMatches() {
        let palette = ColorPalette.albersMidnight
        let theme = xcodeTheme(from: palette)
        let expected = oklchToRGB(palette[.background])
        #expect(abs(theme.background.red - expected.red) < 0.001)
        #expect(abs(theme.background.green - expected.green) < 0.001)
        #expect(abs(theme.background.blue - expected.blue) < 0.001)
    }
}

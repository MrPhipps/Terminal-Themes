import Testing
@testable import ThemeTheory

// MARK: - Color Conversion Tests

@Suite("Color Conversions")
struct ColorConversionsTests {

    // MARK: Round-trip accuracy

    @Test("OKLCH → RGB → OKLCH round-trip preserves lightness within 0.01")
    func roundTripLightness() {
        let original = OKLCHColor(lightness: 0.72, chroma: 0.12, hue: 300)
        let rgb = oklchToRGB(original)
        let back = rgbToOKLCH(rgb)
        #expect(abs(back.lightness - original.lightness) < 0.01)
    }

    @Test("OKLCH → RGB → OKLCH round-trip preserves hue within 2 degrees")
    func roundTripHue() {
        let original = OKLCHColor(lightness: 0.72, chroma: 0.12, hue: 140)
        let rgb = oklchToRGB(original)
        let back = rgbToOKLCH(rgb)
        let hueDiff = min(abs(back.hue - original.hue), 360 - abs(back.hue - original.hue))
        #expect(hueDiff < 2.0)
    }

    @Test("Pure black converts to near-zero RGB")
    func blackConversion() {
        let black = OKLCHColor(lightness: 0, chroma: 0, hue: 0)
        let rgb = oklchToRGB(black)
        #expect(rgb.red < 0.01)
        #expect(rgb.green < 0.01)
        #expect(rgb.blue < 0.01)
    }

    @Test("Pure white converts to near-one RGB")
    func whiteConversion() {
        let white = OKLCHColor(lightness: 1, chroma: 0, hue: 0)
        let rgb = oklchToRGB(white)
        #expect(rgb.red > 0.99)
        #expect(rgb.green > 0.99)
        #expect(rgb.blue > 0.99)
    }

    @Test("Achromatic color has equal RGB components")
    func achromaticIsNeutral() {
        let grey = OKLCHColor.grey(0.5)
        let rgb = oklchToRGB(grey)
        #expect(abs(rgb.red - rgb.green) < 0.01)
        #expect(abs(rgb.green - rgb.blue) < 0.01)
    }

    @Test("Alpha is preserved through conversion")
    func alphaPreservation() {
        let color = OKLCHColor(lightness: 0.6, chroma: 0.08, hue: 200, alpha: 0.7)
        let rgb = oklchToRGB(color)
        #expect(abs(rgb.alpha - 0.7) < 0.001)
    }

    // MARK: xcThemeString format

    @Test("xcThemeString has 4 space-separated components")
    func xcThemeStringFormat() {
        let color = RGBColor(red: 0.5, green: 0.3, blue: 0.8, alpha: 1.0)
        let parts = color.xcThemeString.split(separator: " ")
        #expect(parts.count == 4)
    }

    @Test("xcThemeString round-trips through fromXCThemeString")
    func xcThemeStringRoundTrip() throws {
        let original = RGBColor(red: 0.12, green: 0.45, blue: 0.87, alpha: 1.0)
        let string = original.xcThemeString
        let parsed = try #require(RGBColor.fromXCThemeString(string))
        #expect(abs(parsed.red - original.red) < 0.0001)
        #expect(abs(parsed.green - original.green) < 0.0001)
        #expect(abs(parsed.blue - original.blue) < 0.0001)
    }

    @Test("Invalid xcThemeString returns nil")
    func invalidXCThemeString() {
        #expect(RGBColor.fromXCThemeString("not a color") == nil)
        #expect(RGBColor.fromXCThemeString("0.5 0.5") == nil)
    }

    // MARK: Relative luminance

    @Test("Black has luminance 0")
    func blackLuminance() {
        let luminance = relativeLuminance(RGBColor(red: 0, green: 0, blue: 0))
        #expect(luminance == 0.0)
    }

    @Test("White has luminance 1")
    func whiteLuminance() {
        let luminance = relativeLuminance(RGBColor(red: 1, green: 1, blue: 1))
        #expect(abs(luminance - 1.0) < 0.001)
    }

    @Test("Green contributes most to luminance per WCAG")
    func greenLuminanceDominance() {
        let redLum = relativeLuminance(RGBColor(red: 1, green: 0, blue: 0))
        let greenLum = relativeLuminance(RGBColor(red: 0, green: 1, blue: 0))
        let blueLum = relativeLuminance(RGBColor(red: 0, green: 0, blue: 1))
        #expect(greenLum > redLum)
        #expect(greenLum > blueLum)
    }
}

import Testing
@testable import ThemeTheory

// MARK: - Albers Analysis Tests

@Suite("Albers Analysis")
struct AlbersAnalysisTests {

    // MARK: Contrast ratio

    @Test("Black on white has maximum contrast ratio ~21")
    func maxContrastRatio() {
        let ratio = contrastRatio(
            foreground: RGBColor(red: 0, green: 0, blue: 0),
            background: RGBColor(red: 1, green: 1, blue: 1)
        )
        #expect(ratio > 20.0)
        #expect(ratio <= 21.1)
    }

    @Test("Identical colors have contrast ratio 1")
    func identicalColorsContrast() {
        let grey = RGBColor(red: 0.5, green: 0.5, blue: 0.5)
        let ratio = contrastRatio(foreground: grey, background: grey)
        #expect(abs(ratio - 1.0) < 0.001)
    }

    @Test("Contrast is symmetric (foreground/background swap gives same ratio)")
    func contrastSymmetry() {
        let a = RGBColor(red: 0.9, green: 0.85, blue: 0.7)
        let b = RGBColor(red: 0.1, green: 0.1, blue: 0.15)
        let ratio1 = contrastRatio(foreground: a, background: b)
        let ratio2 = contrastRatio(foreground: b, background: a)
        #expect(abs(ratio1 - ratio2) < 0.001)
    }

    @Test("albersMidnight plainText meets AA contrast against background")
    func albersMidnightTextContrast() {
        let palette = ColorPalette.albersMidnight
        let fg = oklchToRGB(palette[.plainText])
        let bg = oklchToRGB(palette[.background])
        let ratio = contrastRatio(foreground: fg, background: bg)
        #expect(ratio >= 4.5, "Expected ≥ 4.5, got \(ratio)")
    }

    @Test("albersMidnight keyword meets AA contrast")
    func albersMidnightKeywordContrast() {
        let palette = ColorPalette.albersMidnight
        let fg = oklchToRGB(palette[.keyword])
        let bg = oklchToRGB(palette[.background])
        let ratio = contrastRatio(foreground: fg, background: bg)
        #expect(ratio >= 4.5, "Expected ≥ 4.5, got \(ratio)")
    }

    @Test("Contrast rating: ratio < 3 is .fail")
    func contrastRatingFail() {
        #expect(contrastRating(ratio: 2.9) == .fail)
    }

    @Test("Contrast rating: 3.0–4.49 is .uiPass")
    func contrastRatingUIPass() {
        #expect(contrastRating(ratio: 3.0) == .uiPass)
        #expect(contrastRating(ratio: 4.4) == .uiPass)
    }

    @Test("Contrast rating: 4.5–6.99 is .aaPass")
    func contrastRatingAAPass() {
        #expect(contrastRating(ratio: 4.5) == .aaPass)
        #expect(contrastRating(ratio: 6.9) == .aaPass)
    }

    @Test("Contrast rating: ≥ 7 is .aaaPass")
    func contrastRatingAAAPass() {
        #expect(contrastRating(ratio: 7.0) == .aaaPass)
        #expect(contrastRating(ratio: 15.0) == .aaaPass)
    }

    // MARK: Vibration risk

    @Test("Identical colors have zero vibration risk")
    func zeroVibrationForIdenticalColors() {
        let color = OKLCHColor(lightness: 0.5, chroma: 0.1, hue: 200)
        let risk = vibrationRisk(colorA: color, colorB: color)
        #expect(risk < 0.05)
    }

    @Test("Equal lightness, opposite hue produces high vibration risk")
    func highVibrationForOppositeHues() {
        let a = OKLCHColor(lightness: 0.5, chroma: 0.2, hue: 0)
        let b = OKLCHColor(lightness: 0.5, chroma: 0.2, hue: 180)
        let risk = vibrationRisk(colorA: a, colorB: b)
        #expect(risk > 0.5)
    }

    @Test("Large lightness difference reduces vibration risk")
    func largeLightnessDifferenceReducesVibration() {
        let a = OKLCHColor(lightness: 0.1, chroma: 0.1, hue: 0)
        let b = OKLCHColor(lightness: 0.9, chroma: 0.1, hue: 180)
        let risk = vibrationRisk(colorA: a, colorB: b)
        #expect(risk < 0.3)
    }

    @Test("Vibration risk is bounded 0–1")
    func vibrationRiskBounds() {
        let a = OKLCHColor(lightness: 0.5, chroma: 0.4, hue: 0)
        let b = OKLCHColor(lightness: 0.5, chroma: 0.4, hue: 180)
        let risk = vibrationRisk(colorA: a, colorB: b)
        #expect(risk >= 0.0)
        #expect(risk <= 1.0)
    }

    // MARK: Color temperature

    @Test("Hue 0 (red) is warm")
    func redIsWarm() {
        #expect(colorTemperature(hue: 0) == .warm)
    }

    @Test("Hue 30 (orange) is warm")
    func orangeIsWarm() {
        #expect(colorTemperature(hue: 30) == .warm)
    }

    @Test("Hue 200 (cyan) is cool")
    func cyanIsCool() {
        #expect(colorTemperature(hue: 200) == .cool)
    }

    @Test("Hue 250 (blue) is cool")
    func blueIsCool() {
        #expect(colorTemperature(hue: 250) == .cool)
    }

    @Test("albersMidnight keyword is warm (hue ~300, violet-warm)")
    func keywordIsWarm() {
        let kwHue = ColorPalette.albersMidnight[.keyword].hue
        // 300° is in the warm range (300–360)
        #expect(colorTemperature(hue: kwHue) == .warm)
    }

    // MARK: Fatigue risk

    @Test("Very low chroma foreground has near-zero fatigue risk")
    func lowChromaFatigueRisk() {
        let risk = fatigueRisk(chroma: 0.01, isBackground: false)
        #expect(risk < 0.1)
    }

    @Test("High chroma foreground has high fatigue risk")
    func highChromaFatigueRisk() {
        let risk = fatigueRisk(chroma: 0.35, isBackground: false)
        #expect(risk > 0.7)
    }

    @Test("Background chroma > 0.05 has high fatigue risk")
    func backgroundChromaFatigueRisk() {
        let risk = fatigueRisk(chroma: 0.08, isBackground: true)
        #expect(risk > 0.7)
    }
}

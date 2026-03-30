// MARK: - Built-In Palettes
//
// Hand-crafted palettes derived from Albers' principles.
// Each color was chosen in OKLCH to ensure:
//   1. Sufficient luminance contrast against the background (≥ 4.5 for most roles)
//   2. No equal-luminance vibration risk between adjacent syntax pairs
//   3. Warm colors for advancing roles (keywords, functions)
//   4. Cool colors for receding roles (comments)
//   5. Moderate chroma throughout to minimize afterimage fatigue over 10 hours

public extension ColorPalette {

    // MARK: Albers Midnight
    //
    // Inspired by Albers' "Homage to the Square" series — particularly the works
    // from the early 1960s where Albers nested warm violet-grey grounds with
    // amber and teal accents. The background is a deep desaturated navy,
    // not pure black, which Albers considered visually "dead."
    //
    // Hue family: violet (300°) base, with amber (55°), teal (200°), sage (140°)
    // Harmony: Albers Favorite (nested square relationships)
    static let albersMidnight = ColorPalette(
        name: "Albers Midnight",
        colors: [
            .background:         OKLCHColor(lightness: 0.16, chroma: 0.015, hue: 250),
            .selection:          OKLCHColor(lightness: 0.28, chroma: 0.040, hue: 255, alpha: 0.7),
            .insertionPoint:     OKLCHColor(lightness: 0.90, chroma: 0.020, hue: 80),

            .plainText:          OKLCHColor(lightness: 0.82, chroma: 0.015, hue: 80),
            .comment:            OKLCHColor(lightness: 0.50, chroma: 0.040, hue: 250),
            .docComment:         OKLCHColor(lightness: 0.56, chroma: 0.050, hue: 240),

            .keyword:            OKLCHColor(lightness: 0.72, chroma: 0.120, hue: 300),
            .typeIdentifier:     OKLCHColor(lightness: 0.74, chroma: 0.110, hue: 200),
            .functionIdentifier: OKLCHColor(lightness: 0.78, chroma: 0.090, hue: 55),
            .constantIdentifier: OKLCHColor(lightness: 0.76, chroma: 0.095, hue: 35),
            .variableIdentifier: OKLCHColor(lightness: 0.80, chroma: 0.060, hue: 80),

            .numberLiteral:      OKLCHColor(lightness: 0.73, chroma: 0.100, hue: 25),
            .stringLiteral:      OKLCHColor(lightness: 0.70, chroma: 0.090, hue: 140),
            .attribute:          OKLCHColor(lightness: 0.68, chroma: 0.075, hue: 170),
            .preprocessor:       OKLCHColor(lightness: 0.66, chroma: 0.085, hue: 320),
        ]
    )

    // MARK: Albers Ochre
    //
    // A warm-field variant — Albers often used deep ochre grounds in his earlier
    // Bauhaus-era work. This palette uses a warm amber-brown background
    // (very dark, almost black-amber) with cooler accent colors for contrast.
    // Reduces blue-light exposure for late-night sessions.
    static let albersOchre = ColorPalette(
        name: "Albers Ochre",
        colors: [
            .background:         OKLCHColor(lightness: 0.15, chroma: 0.020, hue: 55),
            .selection:          OKLCHColor(lightness: 0.26, chroma: 0.045, hue: 60, alpha: 0.7),
            .insertionPoint:     OKLCHColor(lightness: 0.90, chroma: 0.025, hue: 200),

            .plainText:          OKLCHColor(lightness: 0.84, chroma: 0.020, hue: 80),
            .comment:            OKLCHColor(lightness: 0.48, chroma: 0.035, hue: 75),
            .docComment:         OKLCHColor(lightness: 0.54, chroma: 0.045, hue: 85),

            .keyword:            OKLCHColor(lightness: 0.73, chroma: 0.115, hue: 200),
            .typeIdentifier:     OKLCHColor(lightness: 0.75, chroma: 0.100, hue: 155),
            .functionIdentifier: OKLCHColor(lightness: 0.79, chroma: 0.085, hue: 240),
            .constantIdentifier: OKLCHColor(lightness: 0.77, chroma: 0.090, hue: 290),
            .variableIdentifier: OKLCHColor(lightness: 0.81, chroma: 0.055, hue: 80),

            .numberLiteral:      OKLCHColor(lightness: 0.74, chroma: 0.095, hue: 170),
            .stringLiteral:      OKLCHColor(lightness: 0.71, chroma: 0.085, hue: 300),
            .attribute:          OKLCHColor(lightness: 0.69, chroma: 0.070, hue: 220),
            .preprocessor:       OKLCHColor(lightness: 0.67, chroma: 0.080, hue: 130),
        ]
    )

    // MARK: All built-in palettes
    static let builtIn: [ColorPalette] = [.albersMidnight, .albersOchre]
}

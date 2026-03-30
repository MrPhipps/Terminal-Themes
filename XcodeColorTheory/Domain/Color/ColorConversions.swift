import Foundation

// MARK: - OKLCH ↔ OKLAB ↔ Linear sRGB ↔ sRGB
//
// Reference: https://bottosson.github.io/posts/oklab/
// All functions are pure — no side effects, no I/O.

// MARK: OKLCH → sRGB

/// Converts an OKLCH color to gamma-encoded sRGB.
/// Out-of-gamut colors are clamped into the sRGB gamut before conversion.
public func oklchToRGB(_ color: OKLCHColor) -> RGBColor {
    let lab: Triple = oklchToLab(color)
    let linear: Triple = labToLinearRGB(lab)
    let clamped: Triple = clampToGamut(linear)
    let srgb: Triple = linearToSRGB(clamped)
    return RGBColor(red: srgb.0, green: srgb.1, blue: srgb.2, alpha: color.alpha)
}

/// Converts a gamma-encoded sRGB color back to OKLCH.
public func rgbToOKLCH(_ color: RGBColor) -> OKLCHColor {
    let linear: Triple = srgbToLinear(color.red, color.green, color.blue)
    let lab: Triple = linearRGBToLab(linear)
    return labToOKLCH(lab, alpha: color.alpha)
}

// MARK: - Internal conversion chain

private typealias Triple = (Double, Double, Double)

private func oklchToLab(_ c: OKLCHColor) -> Triple {
    let hRad: Double = c.hue * .pi / 180
    return (c.lightness, c.chroma * cos(hRad), c.chroma * sin(hRad))
}

private func labToLinearRGB(_ lab: Triple) -> Triple {
    let (L, a, b) = lab
    let l_: Double = L + 0.3963377774 * a + 0.2158037573 * b
    let m_: Double = L - 0.1055613458 * a - 0.0638541728 * b
    let s_: Double = L - 0.0894841775 * a - 1.2914855480 * b

    let l: Double = l_ * l_ * l_
    let m: Double = m_ * m_ * m_
    let s: Double = s_ * s_ * s_

    return (
         4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
        -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
        -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
    )
}

private func clampToGamut(_ linear: Triple) -> Triple {
    return (
        linear.0.clamped(to: 0...1),
        linear.1.clamped(to: 0...1),
        linear.2.clamped(to: 0...1)
    )
}

private func linearToSRGB(_ linear: Triple) -> Triple {
    return (srgbTransfer(linear.0), srgbTransfer(linear.1), srgbTransfer(linear.2))
}

/// Applies the sRGB gamma transfer function to a single linear-light component.
private func srgbTransfer(_ v: Double) -> Double {
    if v <= 0.0031308 {
        return 12.92 * v
    } else {
        return 1.055 * pow(v, 1.0 / 2.4) - 0.055
    }
}

private func srgbToLinear(_ r: Double, _ g: Double, _ b: Double) -> Triple {
    return (srgbInverse(r), srgbInverse(g), srgbInverse(b))
}

/// Applies the inverse sRGB gamma transfer function to a single gamma-encoded component.
private func srgbInverse(_ v: Double) -> Double {
    if v <= 0.04045 {
        return v / 12.92
    } else {
        return pow((v + 0.055) / 1.055, 2.4)
    }
}

private func linearRGBToLab(_ linear: Triple) -> Triple {
    let (r, g, b) = linear
    let l_: Double = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
    let m_: Double = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
    let s_: Double = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)

    return (
        0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
        1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
        0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
    )
}

private func labToOKLCH(_ lab: Triple, alpha: Double) -> OKLCHColor {
    let (L, a, b) = lab
    let chroma: Double = sqrt(a * a + b * b)
    var hue: Double = atan2(b, a) * 180 / .pi
    if hue < 0 { hue += 360 }
    return OKLCHColor(lightness: L, chroma: chroma, hue: hue, alpha: alpha)
}

// MARK: - Relative luminance (WCAG 2.1)

/// Computes WCAG 2.1 relative luminance from a linear sRGB triple.
/// Input must be linear (not gamma-corrected).
func relativeLuminanceLinear(_ r: Double, _ g: Double, _ b: Double) -> Double {
    return 0.2126 * r + 0.7152 * g + 0.0722 * b
}

/// Computes WCAG 2.1 relative luminance from an RGBColor (gamma-corrected sRGB).
/// Internally linearizes the components before computing luminance.
public func relativeLuminance(_ color: RGBColor) -> Double {
    let linear: Triple = srgbToLinear(color.red, color.green, color.blue)
    return relativeLuminanceLinear(linear.0, linear.1, linear.2)
}

// MARK: - cbrt

private func cbrt(_ x: Double) -> Double {
    if x < 0 {
        return -pow(-x, 1.0 / 3.0)
    } else {
        return pow(x, 1.0 / 3.0)
    }
}

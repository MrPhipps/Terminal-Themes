import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

// MARK: - ColorRoleRow
//
// A single row in the palette editor. Shows:
//   Left: swatch + role name + code example token
//   Right: contrast badge + color picker
//
// Expanding the row reveals OKLCH sliders (L / C / H) that manipulate
// the perceptual color model directly — no sRGB round-trip, no gamut loss.

struct ColorRoleRow: View {
    let role: PaletteRole
    @Binding var palette: ColorPalette
    @State private var isExpanded: Bool = false

    private var color: OKLCHColor { palette[role] }
    private var rgbColor: RGBColor { oklchToRGB(color) }
    private var swiftUIColor: Color { rgbColor.swiftUIColor }
    private var background: OKLCHColor { palette[.background] }
    private var bgRGB: RGBColor { oklchToRGB(background) }

    private var contrastRatio: Double {
        guard !role.isBackground else { return 1 }
        return AlbersAnalysis.contrastRatio(foreground: rgbColor, background: bgRGB)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            HStack(spacing: 12) {
                swatch

                VStack(alignment: .leading, spacing: 2) {
                    Text(role.displayName)
                        .font(.body)
                    Text(role.codeExample)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if !role.isBackground && role != .insertionPoint {
                    contrastBadge
                }

                // Expand toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .foregroundStyle(.secondary)
                        .imageScale(.medium)
                }
                .buttonStyle(.plain)

                colorPicker
            }
            .padding(.vertical, 2)

            // OKLCH sliders (expanded)
            if isExpanded {
                OKLCHSliders(color: color) { updated in
                    palette = palette.setting(role, to: updated)
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
                .padding(.leading, 44)
            }
        }
    }

    // MARK: - Subviews

    private var swatch: some View {
        ZStack {
            CheckerboardPattern()
                .frame(width: 32, height: 32)

            RoundedRectangle(cornerRadius: 6)
                .fill(bgRGB.swiftUIColor)
                .frame(width: 32, height: 32)

            RoundedRectangle(cornerRadius: 6)
                .fill(swiftUIColor)
                .frame(width: role.isBackground ? 32 : 18, height: role.isBackground ? 32 : 18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
        )
    }

    private var contrastBadge: some View {
        let ratio: Double = contrastRatio
        let rating: ContrastRating = AlbersAnalysis.contrastRating(ratio: ratio)
        return VStack(spacing: 1) {
            Text(String(format: "%.1f:1", ratio))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(badgeColor(rating))
            Text(badgeLabel(rating))
                .font(.system(size: 9))
                .foregroundStyle(badgeColor(rating))
        }
        .frame(width: 44)
    }

    private var colorPicker: some View {
        ColorPicker(
            "",
            selection: Binding(
                get: { swiftUIColor },
                set: { newColor in
                    let rgb: RGBColor = extractRGB(from: newColor)
                    let oklch: OKLCHColor = rgbToOKLCH(rgb)
                    palette = palette.setting(role, to: oklch)
                }
            ),
            supportsOpacity: role == .selection
        )
        .labelsHidden()
        .frame(width: 32)
    }

    // MARK: - Platform-specific Color extraction

    private func extractRGB(from color: Color) -> RGBColor {
        #if canImport(UIKit)
        let uiColor: UIColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return RGBColor(red: Double(r), green: Double(g), blue: Double(b), alpha: Double(a))
        #elseif canImport(AppKit)
        let nsColor: NSColor = NSColor(color).usingColorSpace(.sRGB) ?? .white
        return RGBColor(
            red: Double(nsColor.redComponent),
            green: Double(nsColor.greenComponent),
            blue: Double(nsColor.blueComponent),
            alpha: Double(nsColor.alphaComponent)
        )
        #endif
    }

    // MARK: - Badge helpers

    private func badgeColor(_ rating: ContrastRating) -> Color {
        switch rating {
        case .fail:     return .red
        case .uiPass:   return .orange
        case .aaPass:   return .green
        case .aaaPass:  return Color(hue: 0.35, saturation: 0.8, brightness: 0.6)
        }
    }

    private func badgeLabel(_ rating: ContrastRating) -> String {
        switch rating {
        case .fail:     return "FAIL"
        case .uiPass:   return "UI"
        case .aaPass:   return "AA"
        case .aaaPass:  return "AAA"
        }
    }
}

// MARK: - OKLCHSliders
//
// Three labeled sliders for Lightness, Chroma, and Hue.
// Directly produces OKLCHColor values — no conversion loss.
// The hue track background is a gradient of the hue wheel at the
// current L and C so the user can see what they are picking.

struct OKLCHSliders: View {
    let color: OKLCHColor
    let onChange: (OKLCHColor) -> Void

    var body: some View {
        VStack(spacing: 10) {
            // Lightness
            OKLCHSliderRow(
                label: "L",
                value: color.lightness,
                range: 0...1,
                track: lightnessTrack,
                format: { String(format: "%.2f", $0) }
            ) { newL in
                onChange(OKLCHColor(lightness: newL, chroma: color.chroma, hue: color.hue))
            }

            // Chroma
            OKLCHSliderRow(
                label: "C",
                value: color.chroma,
                range: 0...0.37,
                track: chromaTrack,
                format: { String(format: "%.3f", $0) }
            ) { newC in
                onChange(OKLCHColor(lightness: color.lightness, chroma: newC, hue: color.hue))
            }

            // Hue
            OKLCHSliderRow(
                label: "H",
                value: color.hue,
                range: 0...360,
                track: hueTrack,
                format: { String(format: "%.0f°", $0) }
            ) { newH in
                onChange(OKLCHColor(lightness: color.lightness, chroma: color.chroma, hue: newH))
            }
        }
    }

    // MARK: Track gradients

    private var lightnessTrack: LinearGradient {
        LinearGradient(
            colors: [0.0, 0.25, 0.5, 0.75, 1.0].map { l in
                oklchToRGB(OKLCHColor(lightness: l, chroma: color.chroma, hue: color.hue)).swiftUIColor
            },
            startPoint: .leading, endPoint: .trailing
        )
    }

    private var chromaTrack: LinearGradient {
        LinearGradient(
            colors: [0.0, 0.1, 0.2, 0.3, 0.37].map { c in
                oklchToRGB(OKLCHColor(lightness: color.lightness, chroma: c, hue: color.hue)).swiftUIColor
            },
            startPoint: .leading, endPoint: .trailing
        )
    }

    private var hueTrack: LinearGradient {
        LinearGradient(
            colors: stride(from: 0.0, through: 360.0, by: 30.0).map { h in
                oklchToRGB(OKLCHColor(lightness: color.lightness, chroma: max(color.chroma, 0.08), hue: h)).swiftUIColor
            },
            startPoint: .leading, endPoint: .trailing
        )
    }
}

// MARK: - OKLCHSliderRow

struct OKLCHSliderRow: View {
    let label: String
    let value: Double
    let range: ClosedRange<Double>
    let track: LinearGradient
    let format: (Double) -> String
    let onChange: (Double) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .frame(width: 14, alignment: .leading)

            Slider(
                value: Binding(get: { value }, set: { onChange($0) }),
                in: range
            )
            .tint(track)

            Text(format(value))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 46, alignment: .trailing)
        }
    }
}

// MARK: - AlbersAnalysis namespace (avoids collision with module-level functions)

enum AlbersAnalysis {
    static func contrastRatio(foreground: RGBColor, background: RGBColor) -> Double {
        XcodeColorTheory.contrastRatio(foreground: foreground, background: background)
    }
    static func contrastRating(ratio: Double) -> ContrastRating {
        XcodeColorTheory.contrastRating(ratio: ratio)
    }
}

// MARK: - CheckerboardPattern (transparency indicator)

struct CheckerboardPattern: View {
    var body: some View {
        Canvas { context, size in
            let cellSize: CGFloat = 4
            var row: Int = 0
            var y: CGFloat = 0
            while y < size.height {
                var col: Int = 0
                var x: CGFloat = 0
                while x < size.width {
                    let isLight: Bool = (row + col) % 2 == 0
                    context.fill(
                        Path(CGRect(x: x, y: y, width: cellSize, height: cellSize)),
                        with: .color(isLight ? Color(white: 0.8) : Color(white: 0.6))
                    )
                    x += cellSize
                    col += 1
                }
                y += cellSize
                row += 1
            }
        }
    }
}

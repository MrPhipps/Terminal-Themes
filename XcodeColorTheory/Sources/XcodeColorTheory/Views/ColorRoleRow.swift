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
// The ColorPicker is bound to a SwiftUI Color; we convert to/from OKLCH
// at the boundary (OKLCH ← sRGB conversion via rgbToOKLCH).

struct ColorRoleRow: View {
    let role: PaletteRole
    @Binding var palette: ColorPalette

    private var color: OKLCHColor { palette[role] }
    private var rgbColor: RGBColor { oklchToRGB(color) }
    private var swiftUIColor: Color { rgbColor.swiftUIColor }
    private var background: OKLCHColor { palette[.background] }
    private var bgRGB: RGBColor { oklchToRGB(background) }

    // Contrast ratio (only meaningful for foreground roles)
    private var contrastRatio: Double {
        guard !role.isBackground else { return 1 }
        return AlbersAnalysis.contrastRatio(foreground: rgbColor, background: bgRGB)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Swatch
            swatch

            // Role info
            VStack(alignment: .leading, spacing: 2) {
                Text(role.displayName)
                    .font(.body)
                Text(role.codeExample)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Contrast badge (hidden for background roles)
            if !role.isBackground && role != .insertionPoint {
                contrastBadge
            }

            // Color picker
            colorPicker
        }
        .padding(.vertical, 2)
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

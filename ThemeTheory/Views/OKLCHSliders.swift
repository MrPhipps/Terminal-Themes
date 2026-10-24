import ThemeTheory
import SwiftUI

// MARK: - OKLCHSliders
//
// Three labeled sliders for Lightness, Chroma, and Hue.
// Directly produces OKLCHColor values — no conversion loss.
// The hue track background is a gradient of the hue wheel at the
// current L and C so the user can see what they are picking.
//
// Shared by the app (ColorRoleRow) and the OKLCH color picker bundle,
// so it depends only on the ThemeTheory domain module and SwiftUI.

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
                onChange(OKLCHColor(lightness: newL, chroma: color.chroma, hue: color.hue, alpha: color.alpha))
            }

            // Chroma
            OKLCHSliderRow(
                label: "C",
                value: color.chroma,
                range: 0...0.37,
                track: chromaTrack,
                format: { String(format: "%.3f", $0) }
            ) { newC in
                onChange(OKLCHColor(lightness: color.lightness, chroma: newC, hue: color.hue, alpha: color.alpha))
            }

            // Hue
            OKLCHSliderRow(
                label: "H",
                value: color.hue,
                range: 0...360,
                track: hueTrack,
                format: { String(format: "%.0f°", $0) }
            ) { newH in
                onChange(OKLCHColor(lightness: color.lightness, chroma: color.chroma, hue: newH, alpha: color.alpha))
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

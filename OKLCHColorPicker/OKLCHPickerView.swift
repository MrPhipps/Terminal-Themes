import SwiftUI
import ThemeTheory

// MARK: - OKLCHPickerModel
//
// The picker's only state: the color the sliders show. Owned by OKLCHColorPicker,
// observed by OKLCHPickerView. The panel writes it via setColor(_:); the sliders
// write it via the onChange callback.

@Observable
final class OKLCHPickerModel {
    var color: OKLCHColor = OKLCHColor(lightness: 0.7, chroma: 0.12, hue: 250)
}

// MARK: - OKLCHPickerView
//
// The content of the "OKLCH" tab in NSColorPanel: a swatch, the shared
// OKLCHSliders (same component as the Theme Theory palette editor), and
// copyable CSS / hex readouts.

struct OKLCHPickerView: View {
    let model: OKLCHPickerModel
    let onChange: (OKLCHColor) -> Void

    private var rgb: RGBColor { oklchToRGB(model.color) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(rgb.swiftUIColor)
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.primary.opacity(0.15), lineWidth: 0.5)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(cssString)
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                    Text(hexString)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }

            OKLCHSliders(color: model.color, onChange: onChange)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: Readouts

    /// CSS Color 4 syntax, e.g. `oklch(70.0% 0.120 250.0)`.
    private var cssString: String {
        String(
            format: "oklch(%.1f%% %.3f %.1f)",
            model.color.lightness * 100,
            model.color.chroma,
            model.color.hue
        )
    }

    private var hexString: String {
        let channel: (Double) -> Int = { Int((min(max($0, 0), 1) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", channel(rgb.red), channel(rgb.green), channel(rgb.blue))
    }
}

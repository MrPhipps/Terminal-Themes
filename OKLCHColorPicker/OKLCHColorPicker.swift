import AppKit
import SwiftUI
import ThemeTheory

// MARK: - OKLCHColorPicker
//
// A system color picker bundle (.colorPicker) that adds an "OKLCH" tab to
// NSColorPanel in every app — next to the built-in Wheel, Sliders (RGB/CMYK/HSB),
// Palettes, Image and Pencils tabs.
//
// How the panel talks to us:
//   • Loads the bundle from ~/Library/ColorPickers and instantiates NSPrincipalClass.
//   • Calls setColor(_:) whenever the panel's color changes (from any tab or the host app).
//   • Calls provideNewView(_:) when the user selects our tab.
// How we talk back:
//   • Assign colorPanel.color — the panel then notifies the host app's target/action.
//
// The @objc name must match INFOPLIST_KEY_NSPrincipalClass in the target's build settings.

@objc(OKLCHColorPicker)
final class OKLCHColorPicker: NSColorPicker, NSColorPickingCustom {

    /// Arbitrary mode number unique to this picker. NSColorPanel persists the last-used
    /// mode and hands it back through supportsMode(_:) on the next launch.
    private static let mode: NSColorPanel.Mode = NSColorPanel.Mode(rawValue: 0x4F4B) ?? .none

    private let model: OKLCHPickerModel = OKLCHPickerModel()
    private var hostingView: NSView?

    /// True while we are pushing a color into the panel. The panel echoes it straight
    /// back through setColor(_:); converting that echo (sRGB, gamut-clamped) back to
    /// OKLCH would nudge the sliders under the user's cursor.
    private var isPushingColor: Bool = false

    // MARK: NSColorPickingCustom

    func supportsMode(_ mode: NSColorPanel.Mode) -> Bool {
        mode == Self.mode
    }

    func currentMode() -> NSColorPanel.Mode {
        Self.mode
    }

    func provideNewView(_ initialRequest: Bool) -> NSView {
        if let hostingView {
            return hostingView
        }
        MainActor.assumeIsolated {
            let root: OKLCHPickerView = OKLCHPickerView(model: model) { [weak self] color in
                self?.push(color)
            }
            hostingView = NSHostingView(rootView: root)
        }
        return hostingView ?? NSView()
    }

    func setColor(_ newColor: NSColor) {
        guard !isPushingColor else { return }
        guard let srgb: NSColor = newColor.usingColorSpace(.sRGB) else { return }
        let rgb: RGBColor = RGBColor(
            red: Double(srgb.redComponent),
            green: Double(srgb.greenComponent),
            blue: Double(srgb.blueComponent),
            alpha: Double(srgb.alphaComponent)
        )
        model.color = preservingHue(rgbToOKLCH(rgb), from: model.color)
    }

    // MARK: NSColorPicker overrides

    override var buttonToolTip: String {
        "OKLCH"
    }

    override var minContentSize: NSSize {
        NSSize(width: 220, height: 170)
    }

    override func provideNewButtonImage() -> NSImage {
        NSImage(systemSymbolName: "circle.lefthalf.striped.horizontal", accessibilityDescription: "OKLCH")
            ?? NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: "OKLCH")
            ?? NSImage()
    }

    // MARK: Private

    private func push(_ color: OKLCHColor) {
        model.color = color
        let rgb: RGBColor = oklchToRGB(color)
        isPushingColor = true
        colorPanel.color = NSColor(
            srgbRed: CGFloat(rgb.red),
            green: CGFloat(rgb.green),
            blue: CGFloat(rgb.blue),
            alpha: CGFloat(rgb.alpha)
        )
        isPushingColor = false
    }

    /// Greys have no meaningful hue; rgbToOKLCH returns an arbitrary angle for them.
    /// Keep the previous hue so the H slider doesn't jump when chroma hits zero.
    private func preservingHue(_ incoming: OKLCHColor, from previous: OKLCHColor) -> OKLCHColor {
        guard incoming.chroma < 0.0005 else { return incoming }
        return OKLCHColor(
            lightness: incoming.lightness,
            chroma: incoming.chroma,
            hue: previous.hue,
            alpha: incoming.alpha
        )
    }
}

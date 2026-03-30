import ThemeTheory
import SwiftUI

// MARK: - AlbersAnalysisView
//
// Shows the full Albers analysis for the current palette:
// - Overall validation result (valid / warnings / errors)
// - Contrast table for every foreground role
// - Vibration risk matrix for adjacent syntax pairs
// - Fatigue risk summary

struct AlbersAnalysisView: View {
    let palette: ColorPalette

    private var validation: PaletteValidation { validate(palette: palette) }
    private var bg: RGBColor { oklchToRGB(palette[.background]) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top-level badge
            validationSummary

            // Contrast table
            contrastTable

            // Vibration checks
            vibrationSection

            // Fatigue summary
            fatigueSection
        }
        .padding(.vertical, 4)
    }

    // MARK: - Validation summary

    @ViewBuilder
    private var validationSummary: some View {
        switch validation {
        case .valid:
            Label("All Albers constraints satisfied", systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
                .font(.subheadline.weight(.semibold))

        case .warnings(let warnings, _):
            VStack(alignment: .leading, spacing: 4) {
                Label("\(warnings.count) advisory warning\(warnings.count == 1 ? "" : "s")",
                      systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.subheadline.weight(.semibold))
                ForEach(warnings.indices, id: \.self) { i in
                    Text("• \(warningMessage(warnings[i]))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

        case .errors(let errors):
            VStack(alignment: .leading, spacing: 4) {
                Label("\(errors.count) constraint violation\(errors.count == 1 ? "" : "s")",
                      systemImage: "xmark.octagon.fill")
                    .foregroundStyle(.red)
                    .font(.subheadline.weight(.semibold))
                ForEach(errors.indices, id: \.self) { i in
                    Text("• \(errorMessage(errors[i]))")
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.8))
                }
            }
        }
    }

    // MARK: - Contrast table

    private var contrastTable: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Contrast Ratios")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 2) {
                ForEach(PaletteRole.allCases.filter { !$0.isBackground && $0 != .insertionPoint }, id: \.self) { role in
                    let fg = oklchToRGB(palette[role])
                    let ratio = contrastRatio(foreground: fg, background: bg)
                    let rating = contrastRating(ratio: ratio)
                    let required = role.minimumContrastRatio

                    HStack {
                        // Mini swatch
                        RoundedRectangle(cornerRadius: 3)
                            .fill(fg.swiftUIColor)
                            .frame(width: 12, height: 12)

                        Text(role.displayName)
                            .font(.system(size: 11))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Ratio bar
                        GeometryReader { geo in
                            let width = geo.size.width
                            let barFill = min(CGFloat(ratio) / 21.0, 1.0)
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.08)).frame(height: 4)
                                Capsule()
                                    .fill(ratingColor(rating))
                                    .frame(width: width * barFill, height: 4)
                                // Required threshold marker
                                let reqX = width * CGFloat(required) / 21.0
                                Rectangle()
                                    .fill(Color.white.opacity(0.4))
                                    .frame(width: 1, height: 8)
                                    .offset(x: reqX)
                            }
                        }
                        .frame(width: 80, height: 8)

                        Text(String(format: "%.1f", ratio))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(ratingColor(rating))
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }
        }
    }

    // MARK: - Vibration section

    private var vibrationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Vibration Risk (Adjacent Pairs)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 2) {
                ForEach(adjacentRolePairs.indices, id: \.self) { i in
                    let (a, b) = adjacentRolePairs[i]
                    let risk = vibrationRisk(colorA: palette[a], colorB: palette[b])
                    let level = vibrationLevel(risk: risk)

                    HStack {
                        // Two mini swatches side by side (simulating adjacency)
                        HStack(spacing: 1) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(oklchToRGB(palette[a]).swiftUIColor)
                                .frame(width: 10, height: 12)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(oklchToRGB(palette[b]).swiftUIColor)
                                .frame(width: 10, height: 12)
                        }

                        Text("\(a.displayName) + \(b.displayName)")
                            .font(.system(size: 11))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(level.rawValue.capitalized)
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(levelColor(level).opacity(0.2))
                            .foregroundStyle(levelColor(level))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Fatigue section

    private var fatigueSection: some View {
        let highFatigueRoles = PaletteRole.allCases.filter { role in
            fatigueRisk(chroma: palette[role].chroma, isBackground: role.isBackground) > 0.7
        }

        return VStack(alignment: .leading, spacing: 6) {
            Text("10-Hour Eye Fatigue")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if highFatigueRoles.isEmpty {
                Label("All chroma values within fatigue-safe range", systemImage: "eye.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.green)
            } else {
                ForEach(highFatigueRoles, id: \.self) { role in
                    let chroma = palette[role].chroma
                    HStack {
                        Image(systemName: "eye.trianglebadge.exclamationmark")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                        Text("\(role.displayName): chroma \(String(format: "%.3f", chroma)) — consider reducing")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func ratingColor(_ rating: ContrastRating) -> Color {
        switch rating {
        case .fail:     return .red
        case .uiPass:   return .orange
        case .aaPass:   return .green
        case .aaaPass:  return .cyan
        }
    }

    private func levelColor(_ level: VibrationLevel) -> Color {
        switch level {
        case .safe:     return .green
        case .moderate: return .orange
        case .high:     return .red
        }
    }

    private func warningMessage(_ warning: PaletteWarning) -> String {
        switch warning {
        case .highFatigue(let role, let chroma):
            return "\(role.displayName): chroma \(String(format: "%.3f", chroma)) may cause eye fatigue"
        case .coolKeyword(let role, let hue):
            return "\(role.displayName) at \(Int(hue))° reads as cool — warm hues advance better"
        case .moderateVibration(let a, let b, let risk):
            return "\(a.displayName)/\(b.displayName) vibration risk \(String(format: "%.0f%%", risk * 100))"
        }
    }

    private func errorMessage(_ error: PaletteError) -> String {
        switch error {
        case .insufficientContrast(let role, let actual, let required):
            return "\(role.displayName): \(String(format: "%.1f", actual)):1 < \(String(format: "%.1f", required)):1 required"
        case .highVibration(let a, let b, let risk):
            return "\(a.displayName)/\(b.displayName) vibration risk \(String(format: "%.0f%%", risk * 100)) — redesign adjacent pair"
        case .backgroundTooLight(let lightness):
            return "Background lightness \(String(format: "%.2f", lightness)) — use a darker ground (< 0.5)"
        }
    }
}

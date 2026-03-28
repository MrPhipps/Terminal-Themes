import SwiftUI

// MARK: - PaletteEditorView
//
// Lets the user tweak every color role in the selected palette.
// Changes are live — the ThemePreviewView updates immediately because
// it reads from the same @Binding<ColorPalette>.
//
// The editor shows:
//   - The color role name + example token
//   - A color swatch (showing perceived color on dark background)
//   - WCAG contrast ratio badge
//   - Albers vibration / fatigue badges where applicable
//   - A ColorPicker (SwiftUI native) bound to the OKLCH representation

public struct PaletteEditorView: View {
    @Binding public var palette: ColorPalette
    @Environment(AppEnvironment.self) private var env

    public init(palette: Binding<ColorPalette>) {
        self._palette = palette
    }

    private var background: OKLCHColor { palette[.background] }

    public var body: some View {
        List {
            Section("Canvas") {
                ForEach([PaletteRole.background, .selection, .insertionPoint], id: \.self) { role in
                    ColorRoleRow(role: role, palette: $palette)
                }
            }

            Section("Text") {
                ForEach([PaletteRole.plainText, .comment, .docComment], id: \.self) { role in
                    ColorRoleRow(role: role, palette: $palette)
                }
            }

            Section("Keywords & Declarations") {
                ForEach([PaletteRole.keyword, .typeIdentifier, .functionIdentifier,
                         .constantIdentifier, .variableIdentifier], id: \.self) { role in
                    ColorRoleRow(role: role, palette: $palette)
                }
            }

            Section("Literals & Attributes") {
                ForEach([PaletteRole.numberLiteral, .stringLiteral,
                         .attribute, .preprocessor], id: \.self) { role in
                    ColorRoleRow(role: role, palette: $palette)
                }
            }

            Section("Albers Analysis") {
                AlbersAnalysisView(palette: palette)
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .navigationTitle(palette.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Save") {
                    Task { await env.saveCustomPalette(palette) }
                }
                .disabled(ColorPalette.builtIn.contains(where: { $0.name == palette.name }))
            }
        }
    }
}

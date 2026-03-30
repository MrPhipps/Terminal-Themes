import SwiftUI

// MARK: - PaletteEditorView
//
// Lets the user tweak every color role in the selected palette.
// Changes are live — the ThemePreviewView updates immediately because
// it reads from the same @Binding<ColorPalette>.
//
// Propagation mode: when isPropagating is true, a Harmony section
// appears at the top. Changing baseHue or the scheme immediately calls
// env.propagate(), re-deriving all syntax colors from the Albers generator
// while preserving the background. Individual color overrides still work.

public struct PaletteEditorView: View {
    @Binding public var palette: ColorPalette
    @Environment(AppEnvironment.self) private var env

    public init(palette: Binding<ColorPalette>) {
        self._palette = palette
    }

    private var background: OKLCHColor { palette[.background] }

    public var body: some View {
        @Bindable var env = env
        List {
            if env.isPropagating {
                Section("Harmony") {
                    Picker("Scheme", selection: $env.editingScheme) {
                        ForEach(HarmonyScheme.allCases, id: \.self) { scheme in
                            Text(scheme.displayName).tag(scheme)
                        }
                    }
                    HStack {
                        Text("Base hue")
                        Slider(value: $env.editingBaseHue, in: 0...360)
                            .onChange(of: env.editingBaseHue) { env.propagate() }
                        Text("\(Int(env.editingBaseHue))°")
                            .monospacedDigit()
                            .frame(width: 40, alignment: .trailing)
                    }
                    Button("Propagate Now") { env.propagate() }
                        .font(.subheadline)
                }
                .onChange(of: env.editingScheme) { env.propagate() }
            }

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
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    if env.isPropagating {
                        env.isPropagating = false
                    } else {
                        env.beginPropagation()
                    }
                } label: {
                    Label(
                        env.isPropagating ? "Stop Propagating" : "Propagate Harmony",
                        systemImage: env.isPropagating ? "waveform.slash" : "waveform"
                    )
                }
            }
        }
    }
}

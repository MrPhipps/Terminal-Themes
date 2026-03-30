import ThemeTheory
import SwiftUI

public struct ContentView: View {
    @Environment(AppEnvironment.self) private var env

    public init() {}

    public var body: some View {
        @Bindable var env = env
        NavigationSplitView {
            PaletteLibrarySidebar()
        } content: {
            PaletteEditorView(palette: $env.selectedPalette)
        } detail: {
            ThemePreviewView(palette: env.selectedPalette)
        }
        #if os(macOS)
        .navigationSplitViewStyle(.balanced)
        #endif
    }
}

// MARK: - Palette Library Sidebar

struct PaletteLibrarySidebar: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showNewPaletteSheet: Bool = false

    var body: some View {
        @Bindable var env = env
        List(env.palettes, id: \.name, selection: $env.selectedPaletteNameBinding) { palette in
            PaletteLibraryRow(
                palette: palette,
                isBuiltIn: ColorPalette.builtIn.contains(where: { $0.name == palette.name })
            )
        }
        .listStyle(.sidebar)
        .navigationTitle("Palettes")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewPaletteSheet = true
                } label: {
                    Label("New Palette", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewPaletteSheet) {
            NewPaletteSheet()
        }
    }
}

struct PaletteLibraryRow: View {
    let palette: ColorPalette
    let isBuiltIn: Bool
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        HStack(spacing: 8) {
            // Mini color strip — 5 key roles as swatches
            HStack(spacing: 2) {
                ForEach([PaletteRole.background, .keyword, .stringLiteral, .functionIdentifier, .typeIdentifier], id: \.self) { role in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(oklchToRGB(palette[role]).swiftUIColor)
                        .frame(width: 10, height: 20)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 2) {
                Text(palette.name)
                    .font(.body)
                if isBuiltIn {
                    Text("Built-in")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            if !isBuiltIn {
                Button(role: .destructive) {
                    Task { await env.deletePalette(named: palette.name) }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - New Palette Sheet

struct NewPaletteSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = "My Palette"
    // Use a separate String state for the Picker so we can bind to it directly,
    // then derive the `basedOn` palette at creation time — avoids the non-writable
    // `let name` property binding issue.
    @State private var basedOnName: String = ColorPalette.albersMidnight.name
    @State private var scheme: HarmonyScheme = HarmonyScheme.albersFavorite
    @State private var baseHue: Double = 300.0

    private var basedOn: ColorPalette {
        ColorPalette.builtIn.first(where: { $0.name == basedOnName }) ?? .albersMidnight
    }

    private var previewPalette: ColorPalette {
        let hues = accentHues(base: baseHue, scheme: scheme)
        let generated = assignHuesToRoles(hues: hues, background: basedOn[.background])
        let merged = basedOn.colors.merging(generated) { _, new in new }
        return ColorPalette(name: name.isEmpty ? "Preview" : name, colors: merged)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Palette name", text: $name)
                }
                Section("Starting Point") {
                    Picker("Based on", selection: $basedOnName) {
                        ForEach(ColorPalette.builtIn, id: \.name) { palette in
                            Text(palette.name).tag(palette.name)
                        }
                    }
                }
                Section("Preview") {
                    ThemePreviewView(palette: previewPalette)
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .listRowInsets(.init())
                }

                Section("Harmony") {
                    Picker("Scheme", selection: $scheme) {
                        ForEach(HarmonyScheme.allCases, id: \.self) { scheme in
                            Text(scheme.displayName).tag(scheme)
                        }
                    }
                    HStack {
                        Text("Base hue")
                        Slider(value: $baseHue, in: 0...360)
                        Text("\(Int(baseHue))°")
                            .monospacedDigit()
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
            .navigationTitle("New Palette")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let hues: [Double] = accentHues(base: baseHue, scheme: scheme)
                        let generated: [PaletteRole: OKLCHColor] = assignHuesToRoles(
                            hues: hues,
                            background: basedOn[.background]
                        )
                        let merged: [PaletteRole: OKLCHColor] = basedOn.colors.merging(generated) { _, new in new }
                        let newPalette: ColorPalette = ColorPalette(name: name, colors: merged)
                        Task {
                            await env.saveCustomPalette(newPalette)
                            env.selectedPalette = newPalette
                        }
                        dismiss()
                    }
                    .disabled({
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        let nameExists = env.palettes.contains(where: { $0.name == trimmed })
                        return trimmed.isEmpty || nameExists
                    }())
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 300)
        #endif
    }
}

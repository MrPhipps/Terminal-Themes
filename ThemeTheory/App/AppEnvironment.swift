import ThemeTheory
import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif


public typealias RGBColor = ThemeTheory.RGBColor

// MARK: - ExportState
//
// Algebraic type representing the lifecycle of a theme export operation.
// Replaces the three loose booleans (isExporting, exportedURL, exportError)
// that previously encoded the same state space with overlap and ambiguity.

public enum ExportState: Sendable {
    case idle
    case exporting
    case success(URL)
    case failure(String)

    public var isExporting: Bool {
        if case .exporting = self { return true }
        return false
    }

    public var exportedURL: URL? {
        if case .success(let url) = self { return url }
        return nil
    }

    public var errorMessage: String? {
        if case .failure(let message) = self { return message }
        return nil
    }
}

// MARK: - LoadState
//
// Algebraic type for library load lifecycle — separates "not found yet"
// (first launch) from a genuine decode failure (corrupted file).

public enum LoadState: Sendable {
    case notLoaded
    case loaded
    case failed(String)
}

// MARK: - AppEnvironment
//
// Observable object that bridges the actor-based services to SwiftUI's main-thread world.
// Keeps the actors as private implementation details; views only see plain Swift values.

@MainActor
@Observable
public final class AppEnvironment {
    // MARK: - State (all explicitly typed)
    public var palettes: [ColorPalette] = [ColorPalette]()
    private var selectedPaletteName: String = ColorPalette.albersMidnight.name
    public var exportState: ExportState = ExportState.idle
    public var loadState: LoadState = LoadState.notLoaded

    // MARK: - Harmony propagation editing state
    //
    // When isPropagating is true the editor shows a hue slider + scheme picker.
    // Changing either value calls propagate(), which re-derives all non-background
    // colors via the Albers harmony generator and writes them into selectedPalette.
    // Individual color overrides made after propagation persist until the next
    // propagate() call — the user is always in control.

    public var isPropagating: Bool = false
    public var editingBaseHue: Double = 240.0
    public var editingScheme: HarmonyScheme = .albersFavorite

    /// Re-derives all syntax colors from the current baseHue + scheme + background
    /// and merges them into selectedPalette. Background and selection are preserved.
    public func propagate() {
        let hues = accentHues(base: editingBaseHue, scheme: editingScheme)
        let generated = assignHuesToRoles(hues: hues, background: selectedPalette[.background])
        var updatedColors = selectedPalette.colors
        for (role, color) in generated {
            // Preserve existing background and selection colors as documented.
            if role == .background || role == .selection {
                continue
            }
            updatedColors[role] = color
        }
        selectedPalette = ColorPalette(name: selectedPalette.name, colors: updatedColors)
    }

    /// Enters propagation mode, seeding editingBaseHue from the palette's current keyword hue.
    public func beginPropagation() {
        editingBaseHue = selectedPalette[.keyword].hue
        isPropagating = true
        propagate()
    }

    // MARK: - Computed selection (live lookup into palettes — never stale)

    /// The currently selected palette. Setting this updates the stored name.
    /// The getter always performs a live lookup into `palettes` so it
    /// reflects additions, deletions, and renames without capturing a stale copy.
    public var selectedPalette: ColorPalette {
        get { palettes.first(where: { $0.name == selectedPaletteName }) ?? .albersMidnight }
        set {
            selectedPaletteName = newValue.name
            if let index = palettes.firstIndex(where: { $0.name == newValue.name }) {
                palettes[index] = newValue
            }
        }
    }

    /// Bindable name used for List selection.
    /// Optional because SwiftUI's List(selection:) requires Binding<SelectionValue?>.
    public var selectedPaletteNameBinding: String? {
        get { selectedPaletteName }
        set { if let newValue { selectedPaletteName = newValue } }
    }

    // MARK: - Services (actors — accessed only from async tasks, types explicit)

    private let library: ThemeLibrary = ThemeLibrary()
    private let exporter: ThemeExporter = ThemeExporter()

    public init() {
        palettes = ColorPalette.builtIn
    }

    // MARK: - Load

    public func loadLibrary() async {
        do {
            try await library.load()
            palettes = await library.allPalettes()
            loadState = .loaded
        } catch CocoaError.fileNoSuchFile, CocoaError.fileReadNoSuchFile {
            // First launch — no saved palettes yet.
            palettes = ColorPalette.builtIn
            loadState = .loaded
        } catch {
            // Genuine failure (corrupted JSON, permissions, etc.) — surface it.
            loadState = .failed("Could not load saved palettes: \(error.localizedDescription)")
            palettes = ColorPalette.builtIn
        }
    }

    // MARK: - Save custom palette

    public func saveCustomPalette(_ palette: ColorPalette) async {
        do {
            try await library.save(palette: palette)
            palettes = await library.allPalettes()
        } catch {
            exportState = .failure("Could not save palette: \(error.localizedDescription)")
        }
    }

    public func deletePalette(named name: String) async {
        guard !ColorPalette.builtIn.contains(where: { $0.name == name }) else { return }
        do {
            try await library.delete(named: name)
            palettes = await library.allPalettes()
            if selectedPaletteName == name {
                selectedPaletteName = ColorPalette.albersMidnight.name
            }
        } catch {
            exportState = .failure("Could not delete palette: \(error.localizedDescription)")
        }
    }

    // MARK: - Export

    #if os(macOS)
    public func exportToXcodeThemes(fontHierarchy: FontHierarchy = .default) async {
        exportState = .exporting
        do {
            let url: URL = try await exporter.exportToXcodeThemes(palette: selectedPalette, fontHierarchy: fontHierarchy)
            exportState = .success(url)
        } catch {
            exportState = .failure(error.localizedDescription)
        }
    }
    #endif

    public func exportToDownloads(fontHierarchy: FontHierarchy = .default) async {
        exportState = .exporting
        do {
            let url: URL = try await exporter.exportToDownloads(palette: selectedPalette, fontHierarchy: fontHierarchy)
            exportState = .success(url)
        } catch {
            exportState = .failure(error.localizedDescription)
        }
    }

    public func xmlString(fontHierarchy: FontHierarchy = .default) -> String {
        return themeXMLString(for: selectedPalette, fontHierarchy: fontHierarchy)
    }
}

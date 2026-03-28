import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

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

    // MARK: - Computed selection (live lookup into palettes — never stale)

    /// The currently selected palette. Setting this updates the stored name.
    /// The getter always performs a live lookup into `palettes` so it
    /// reflects additions, deletions, and renames without capturing a stale copy.
    public var selectedPalette: ColorPalette {
        get { palettes.first(where: { $0.name == selectedPaletteName }) ?? .albersMidnight }
        set { selectedPaletteName = newValue.name }
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

    public func exportToXcodeThemes(font: ThemeFont = .default) async {
        exportState = .exporting
        do {
            let url: URL = try await exporter.exportToXcodeThemes(palette: selectedPalette, font: font)
            exportState = .success(url)
        } catch {
            exportState = .failure(error.localizedDescription)
        }
    }

    public func exportToDownloads(font: ThemeFont = .default) async {
        exportState = .exporting
        do {
            let url: URL = try await exporter.exportToDownloads(palette: selectedPalette, font: font)
            exportState = .success(url)
        } catch {
            exportState = .failure(error.localizedDescription)
        }
    }

    public func xmlString(font: ThemeFont = .default) -> String {
        return themeXMLString(for: selectedPalette, font: font)
    }
}

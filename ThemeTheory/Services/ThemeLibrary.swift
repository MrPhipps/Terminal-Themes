import ThemeTheory
import Foundation

// MARK: - ThemeLibrary (actor — imperative shell)
//
// Persists user-created palettes to the app's Application Support directory.
// All JSON encoding/decoding happens here — the domain types are plain Swift structs.

/// Manages saving and loading custom palettes.
///
/// Built-in palettes are always available and not persisted here.
/// Custom palettes are stored as JSON in Application Support.
public actor ThemeLibrary {
    private let storageURL: URL
    private var customPalettes: [ColorPalette] = []

    public init() {
        let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("XcodeColorTheory", isDirectory: true)
        self.storageURL = appSupport.appendingPathComponent("custom-palettes.json")
    }

    // MARK: - All palettes

    /// Returns all palettes: built-ins first, then custom.
    public func allPalettes() async -> [ColorPalette] {
        ColorPalette.builtIn + customPalettes
    }

    // MARK: - Load

    public func load() async throws {
        let fm = FileManager.default
        guard fm.fileExists(atPath: storageURL.path) else { return }
        let data = try Data(contentsOf: storageURL)
        let stored = try JSONDecoder().decode([StoredPalette].self, from: data)
        customPalettes = stored.map(\.palette)
    }

    // MARK: - Save

    public func save(palette: ColorPalette) async throws {
        // Replace if name matches, otherwise append
        if let index = customPalettes.firstIndex(where: { $0.name == palette.name }) {
            customPalettes[index] = palette
        } else {
            customPalettes.append(palette)
        }
        try await persistToDisk()
    }

    public func delete(named name: String) async throws {
        customPalettes.removeAll { $0.name == name }
        try await persistToDisk()
    }

    // MARK: - Private

    private func persistToDisk() async throws {
        let fm = FileManager.default
        try fm.createDirectory(at: storageURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let stored = customPalettes.map(StoredPalette.init)
        let data = try JSONEncoder().encode(stored)
        try data.write(to: storageURL, options: .atomic)
    }
}

// MARK: - Codable bridge types

private struct StoredPalette: Codable {
    let name: String
    let colors: [String: StoredColor]

    init(palette: ColorPalette) {
        self.name = palette.name
        self.colors = Dictionary(
            uniqueKeysWithValues: palette.colors.map { role, color in
                (role.rawValue, StoredColor(color: color))
            }
        )
    }

    var palette: ColorPalette {
        let roleColors = Dictionary(
            uniqueKeysWithValues: colors.compactMap { rawRole, stored -> (PaletteRole, OKLCHColor)? in
                guard let role = PaletteRole(rawValue: rawRole) else { return nil }
                return (role, stored.color)
            }
        )
        return ColorPalette(name: name, colors: roleColors)
    }
}

private struct StoredColor: Codable {
    let lightness: Double
    let chroma: Double
    let hue: Double
    let alpha: Double

    init(color: OKLCHColor) {
        lightness = color.lightness
        chroma = color.chroma
        hue = color.hue
        alpha = color.alpha
    }

    var color: OKLCHColor {
        OKLCHColor(lightness: lightness, chroma: chroma, hue: hue, alpha: alpha)
    }
}
